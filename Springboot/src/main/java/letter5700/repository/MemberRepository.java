package letter5700.repository;

import letter5700.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MemberRepository extends JpaRepository<Member, Long> {
    // 로그인 아이디로 회원 조회
    Optional<Member> findByUsername(String username);

    // 중복 가입 방지용
    boolean existsByUsername(String username);
}