package letter5700.repository;

import letter5700.entity.DailyRecord;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DailyRecordRepository extends JpaRepository<DailyRecord, Long> {
}
