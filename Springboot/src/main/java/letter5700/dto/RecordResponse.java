package letter5700.dto;

import letter5700.entity.DailyRecord;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
public class RecordResponse {
    private Long id;
    private String content; // 일기 내용
    private String emotion;
    private LocalDateTime date;
    private String adviceContent; // AI 조언 내용 (핵심!)

    public RecordResponse(DailyRecord record) {
        this.id = record.getId();
        this.content = record.getContent();
        this.emotion = record.getEmotion();
        this.date = record.getRecordDate();

        // 조언이 생성되어 있다면 내용 담기, 없으면 null
        if (record.getAdvice() != null) {
            this.adviceContent = record.getAdvice().getContent();
        }
    }
}