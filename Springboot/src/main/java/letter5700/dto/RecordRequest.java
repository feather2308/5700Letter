package letter5700.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter
@NoArgsConstructor
public class RecordRequest {
    private Long memberId; // 테스트용: 누가 썼는지 ID로 받음
    private String content;
    private String emotion;
}