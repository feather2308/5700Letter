package letter5700.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter @Setter
@NoArgsConstructor
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 이메일 (로그인 ID 역할)
    @Column(nullable = false, unique = true)
    private String email;

    // 비밀번호 (암호화 저장 예정)
    private String password;

    // 닉네임 (개인화된 호칭용)
    private String nickname;

    // 가입일
    private LocalDateTime createdAt;

    // 사용자가 작성한 기록들과의 관계 설정
    @OneToMany(mappedBy = "member")
    private List<DailyRecord> records = new ArrayList<>();

    // 생성자 편의 메서드
    public Member(String email, String password, String nickname) {
        this.email = email;
        this.password = password;
        this.nickname = nickname;
        this.createdAt = LocalDateTime.now();
    }
}