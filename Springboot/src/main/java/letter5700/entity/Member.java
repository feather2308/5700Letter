package letter5700.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter @Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 로그인 아이디 (중복 불가)
    @Column(nullable = false, unique = true)
    private String username;

    // 암호화된 비밀번호
    @Column(nullable = false)
    private String password;

    // 사용자 이름
    @Column(nullable = false)
    private String name;

    // 역할 (USER, ADMIN 등 - 추후 확장을 위해 추가해두면 좋음)
    private String role;

    @Builder
    public Member(String username, String password, String name, String role) {
        this.username = username;
        this.password = password;
        this.name = name;
        this.role = role;
    }
}