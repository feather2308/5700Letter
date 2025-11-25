package letter5700.repository;

import letter5700.entity.DailyRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface DailyRecordRepository extends JpaRepository<DailyRecord, Long> {
    // [추가] 특정 멤버의 기록을 날짜 내림차순(최신순)으로 조회
    List<DailyRecord> findAllByMemberIdOrderByRecordDateDesc(Long memberId);
}
