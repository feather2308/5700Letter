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

        // Setter를 사용하여 이름 변경
        member.setName(newName);

        // @Transactional 덕분에 변경 감지(Dirty Checking)가 작동하여
        // 별도의 repository.save(member) 없이도 DB에 자동 업데이트됩니다.
    }
}