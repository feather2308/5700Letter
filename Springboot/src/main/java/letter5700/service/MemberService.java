package letter5700.service;

import letter5700.entity.Member;
import letter5700.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class MemberService {

    private final MemberRepository memberRepository;

    // 내 정보 조회
    @Transactional(readOnly = true)
    public Member getMyInfo(String username) {
        return memberRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("로그인 유저 정보가 없습니다."));
    }

    // 내 정보 수정 (이름 변경 예시)
    public void updateMyInfo(String username, String newName) {
        Member member = memberRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("로그인 유저 정보가 없습니다."));

        // Entity에 setter가 없다면 update 메서드를 만들어서 사용 권장 (여기선 편의상 가정)
        // member.updateName(newName);
        // JPA Dirty Checking으로 자동 저장됨
    }
}