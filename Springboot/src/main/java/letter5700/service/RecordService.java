package letter5700.service;

import io.qdrant.client.grpc.Points;
import letter5700.dto.RecordRequest;
import letter5700.dto.RecordResponse;
import letter5700.entity.Advice;
import letter5700.entity.DailyRecord;
import letter5700.entity.Member;
import letter5700.repository.AdviceRepository;
import letter5700.repository.DailyRecordRepository;
import letter5700.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class RecordService {

    private final DailyRecordRepository recordRepository;
    private final MemberRepository memberRepository;
    private final AdviceRepository adviceRepository;
    private final GeminiService geminiService;
    private final RagService ragService;
    private final FcmService fcmService;

    @Autowired
    @Lazy
    private RecordService self;

    public Long saveRecord(RecordRequest request, String username) {
        // 0. 사용자 조회
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 회원입니다."));

        // 2. 일기(Record) 저장
        DailyRecord record = new DailyRecord(
                member,
                request.getContent(),
                "", // request.getEmotion() 대신 aiEmotion 사용
                LocalDateTime.now()
        );
        DailyRecord savedRecord = recordRepository.save(record);

        self.generateAdviceAsync(savedRecord.getId(), request.getContent(), request.getFcmToken());

        return savedRecord.getId(); // 앱에는 바로 "성공" 응답이 감
    }

    // 3. [비동기] 뒤에서 몰래 5700자 조언 쓰기 (@Async)
    @Async
    public void generateAdviceAsync(Long recordId, String content, String fcmToken) {
        try {
            System.out.println(">>> [비동기] 작업 시작 (ID: " + recordId + ")");

            // (1) 감정 분석
            String aiEmotion = geminiService.analyzeEmotion(content);

            // (2) RAG 검색
            List<Float> queryVector = geminiService.createEmbedding(content);
            List<Points.ScoredPoint> searchResults = ragService.search(queryVector, 3);
            String knowledgeContext = searchResults.stream()
                    .map(point -> point.getPayloadMap().get("content").getStringValue())
                    .collect(Collectors.joining("\n- "));

            // (3) 프롬프트 구성
            String finalPrompt = String.format("""
                당신은 심리 상담 전문가입니다.
                아래 '참고 지식'을 바탕으로, 사용자의 일기에 대해 5700자 내외의 깊이 있는 편지를 써주세요.
                
                [참고 지식]
                %s
                
                [사용자 일기]
                %s
                """, knowledgeContext, content);

            // (4) 조언 생성
            String aiAdvice = geminiService.getAdvice(finalPrompt);

            // (5) DB 업데이트 (트랜잭션 분리됨)
            // 주의: Async 내부에서는 트랜잭션이 끊기므로 다시 조회해서 처리
            recordRepository.findById(recordId).ifPresent(record -> {
                // 1. 감정 업데이트 후 저장 (일기 테이블)
                record.setEmotion(aiEmotion);
                recordRepository.save(record);

                // 2. 조언 생성 후 저장 (조언 테이블)
                Advice advice = new Advice(record, aiAdvice);
                adviceRepository.save(advice);

                System.out.println(">>> [비동기] DB 저장 완료! 감정: " + aiEmotion);
            });

            // (6) 알림 전송
            fcmService.sendNotification(
                    fcmToken,
                    "5700 Letter 도착",
                    "당신에게 필요한 말, 준비됐어요."
            );

        } catch (Exception e) {
            e.printStackTrace();
            System.err.println(">>> [비동기] 실패: " + e.getMessage());
        }
    }

    // [추가] 1. 단건 조회 (특정 일기와 조언 보기)
    @Transactional(readOnly = true)
    public RecordResponse getRecord(Long recordId) {
        DailyRecord record = recordRepository.findById(recordId)
                .orElseThrow(() -> new IllegalArgumentException("기록을 찾을 수 없습니다."));
        return new RecordResponse(record);
    }

    // [추가] 2. 목록 조회 (특정 사용자의 모든 기록)
    @Transactional(readOnly = true)
    public List<RecordResponse> getMemberRecords(String username) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 회원입니다."));
        // 원래는 MemberRepository에서 records를 가져오거나 별도 쿼리를 짜야 함
        // 편의상 DailyRecordRepository에 메서드가 필요함 (아래 3번 참고)
        return recordRepository.findAllByMemberIdOrderByRecordDateDesc(member.getId())
                .stream()
                .map(RecordResponse::new)
                .collect(Collectors.toList());
    }

    // [추가] 특정 멤버의 모든 기록 삭제 (설정 > 데이터 초기화용)
    public void deleteAllRecords(String username) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 회원입니다."));

        List<DailyRecord> records = recordRepository.findAllByMemberIdOrderByRecordDateDesc(member.getId());
        recordRepository.deleteAll(records);
    }
}