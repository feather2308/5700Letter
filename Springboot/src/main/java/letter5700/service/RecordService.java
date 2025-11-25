package letter5700.service;

import letter5700.entity.Advice; // import 추가
import letter5700.repository.AdviceRepository; // import 추가 (아래 3번에서 만들 예정)
import letter5700.entity.DailyRecord;
import letter5700.entity.Member;
import letter5700.dto.RecordRequest;
import letter5700.repository.DailyRecordRepository;
import letter5700.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
@RequiredArgsConstructor
@Transactional
public class RecordService {

    private final DailyRecordRepository recordRepository;
    private final MemberRepository memberRepository;
    private final AdviceRepository adviceRepository; // [추가] 조언 저장소
    private final GeminiService geminiService;       // [추가] AI 서비스
    private final RagService ragService;

    public Long saveRecord(RecordRequest request) {
        // 1. 사용자 조회
        Member member = memberRepository.findById(request.getMemberId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 회원입니다."));

        // 2. 일기(Record) 저장
        DailyRecord record = new DailyRecord(
                member,
                request.getContent(),
                request.getEmotion(),
                LocalDate.now()
        );
        DailyRecord savedRecord = recordRepository.save(record);

        // 3. [RAG 적용] 문맥 검색
        String similarWisdom = ragService.searchSimilarAdvice(request.getContent());

        // 4. [프롬프트 강화] 검색된 지식을 포함하여 AI 요청
        // (기존 geminiService.getAdvice 메서드 파라미터를 수정해야 함. 아래 참고)
        String finalPrompt = String.format("""
            [참고할 지혜]
            %s
            
            [사용자 일기]
            %s
            """, similarWisdom, request.getContent());

        // 3. [추가] AI 조언 생성 요청 (비동기로 처리하면 좋지만, 일단 동기로 구현)
        String aiContent = geminiService.getAdvice(finalPrompt);

        // 4. [추가] 조언(Advice) DB 저장
        Advice advice = new Advice(savedRecord, aiContent);
        adviceRepository.save(advice);

        return savedRecord.getId();
    }
}