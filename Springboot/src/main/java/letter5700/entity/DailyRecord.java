package letter5700.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Getter @Setter
@NoArgsConstructor
public class DailyRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 어떤 사용자의 기록인지 연결 [cite: 112]
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id")
    private Member member;

    // 기록 내용 (긴 텍스트 허용)
    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    // 오늘의 감정 (예: 행복, 불안, 피곤 등)
    private String emotion;

    // 기록 날짜
    private LocalDateTime recordDate;

    // 이 기록에 대해 생성된 AI 조언 (1:1 관계)
    @OneToOne(mappedBy = "dailyRecord", cascade = CascadeType.ALL)
    private Advice advice;

    // 생성자
    public DailyRecord(Member member, String content, String emotion, LocalDateTime recordDate) {
        this.member = member;
        this.content = content;
        this.emotion = emotion;
        this.recordDate = recordDate;
    }
}