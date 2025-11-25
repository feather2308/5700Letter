package letter5700.service;

import letter5700.dto.RecordResponse;
import letter5700.entity.Advice;
import letter5700.entity.DailyRecord;
import letter5700.entity.Member;
import letter5700.dto.RecordRequest;
import letter5700.repository.AdviceRepository;
import letter5700.repository.DailyRecordRepository;
import letter5700.repository.MemberRepository;
import io.qdrant.client.grpc.Points; // ScoredPoint import
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Async; // import 추가

import java.time.LocalDate;
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

    public Long saveRecord(RecordRequest request) {
        // 0. 사용자 조회
        Member member = memberRepository.findById(request.getMemberId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 회원입니다."));

        // [변경] 1. 저장 전에 먼저 감정 분석 수행
        String aiEmotion = geminiService.analyzeEmotion(request.getContent());
        System.out.println(">>> AI가 분석한 감정: " + aiEmotion);

        // 2. 일기(Record) 저장
        DailyRecord record = new DailyRecord(
                member,
                request.getContent(),
                aiEmotion, // request.getEmotion() 대신 aiEmotion 사용
                LocalDate.now()
        );
        DailyRecord savedRecord = recordRepository.save(record);

        generateAdviceAsync(savedRecord.getId(), request.getContent(), request.getFcmToken());

        return savedRecord.getId(); // 앱에는 바로 "성공" 응답이 감
    }

    // 3. [비동기] 뒤에서 몰래 5700자 조언 쓰기 (@Async)
    @Async
    public void generateAdviceAsync(Long recordId, String content, String fcmToken) {
        try {
            System.out.println(">>> [비동기] 조언 생성 시작 (ID: " + recordId + ")");

            // ---------------------------------------------------------
            // [RAG 핵심 로직 통합]

            // 1. 사용자 일기 내용을 벡터로 변환
            List<Float> queryVector = geminiService.createEmbedding(content);

            // 2. Qdrant에서 유사한 지식 검색 (Top 3)
            List<Points.ScoredPoint> searchResults = ragService.search(queryVector, 3);

            // 3. 검색된 지식들을 하나의 문자열로 합치기
            String knowledgeContext = searchResults.stream()
                    .map(point -> point.getPayloadMap().get("content").getStringValue())
                    .collect(Collectors.joining("\n- "));

            // 4. 프롬프트 구성 (검색된 지식 + 사용자 일기)
            String finalPrompt = String.format("""
                당신은 심리 상담 전문가이자 따뜻한 조언자입니다.
                아래 '참고 지식'을 바탕으로, 사용자의 일기에 대해 5700자 내외의 깊이 있는 편지를 써주세요.
                
                [참고 지식 (DB 검색 결과)]
                - %s
                
                [사용자 일기]
                %s
                """, knowledgeContext, content);

            // 5. Gemini에게 최종 요청 (조언 생성 - 시간 오래 걸림)
            String aiAdvice = geminiService.getAdvice(finalPrompt);

            // ---------------------------------------------------------

            // 6. DB 업데이트 (비동기라 다시 조회해서 저장)
            recordRepository.findById(recordId).ifPresent(record -> {
                Advice advice = new Advice(record, aiAdvice);
                adviceRepository.save(advice);
                System.out.println(">>> [비동기] 조언 저장 완료! (ID: " + recordId + ")");
            });

            // [마지막에 추가] 진짜 작업이 다 끝나면 알림 발사!
            fcmService.sendNotification(
                    fcmToken,
                    "5700 Letter 도착",
                    "당신에게 필요한 말, 준비됐어요."
            );

        } catch (Exception e) {
            e.printStackTrace();
            System.err.println(">>> [비동기] 조언 생성 실패: " + e.getMessage());
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
    public List<RecordResponse> getMemberRecords(Long memberId) {
        // 원래는 MemberRepository에서 records를 가져오거나 별도 쿼리를 짜야 함
        // 편의상 DailyRecordRepository에 메서드가 필요함 (아래 3번 참고)
        return recordRepository.findAllByMemberIdOrderByRecordDateDesc(memberId)
                .stream()
                .map(RecordResponse::new)
                .collect(Collectors.toList());
    }

    // [추가] 특정 멤버의 모든 기록 삭제 (설정 > 데이터 초기화용)
    public void deleteAllRecords(Long memberId) {
        // DailyRecord를 지우면 연결된 Advice도 Cascade 설정 덕분에 같이 지워짐
        List<DailyRecord> records = recordRepository.findAllByMemberIdOrderByRecordDateDesc(memberId);
        recordRepository.deleteAll(records);
    }
}