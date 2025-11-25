package letter5700.service;

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

    // 기록 저장 로직
    public Long saveRecord(RecordRequest request) {
        // 1. 사용자 조회 (없으면 에러)
        Member member = memberRepository.findById(request.getMemberId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 회원입니다."));

        // 2. 기록 엔티티 생성
        DailyRecord record = new DailyRecord(
                member,
                request.getContent(),
                request.getEmotion(),
                LocalDate.now() // 오늘 날짜
        );

        // 3. DB 저장
        DailyRecord savedRecord = recordRepository.save(record);

        return savedRecord.getId();
    }
}