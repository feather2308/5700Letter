package letter5700.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Getter @Setter
@NoArgsConstructor
public class Advice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 어떤 기록에 대한 조언인지 연결
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "daily_record_id")
    private DailyRecord dailyRecord;

    // AI가 생성한 조언 내용 (5700자 등 매우 긴 텍스트) [cite: 109]
    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    // 생성 시각
    private LocalDateTime createdAt;

    public Advice(DailyRecord dailyRecord, String content) {
        this.dailyRecord = dailyRecord;
        this.content = content;
        this.createdAt = LocalDateTime.now();
    }
}