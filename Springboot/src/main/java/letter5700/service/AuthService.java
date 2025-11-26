package letter5700.service;

import letter5700.entity.Member;
import letter5700.dto.AuthDto;
import letter5700.repository.MemberRepository;
import letter5700.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class AuthService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    // 회원가입
    public Long signup(AuthDto.SignupRequest request) {
        if (memberRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("이미 존재하는 아이디입니다.");
        }

        Member member = Member.builder()
                .username(request.getUsername())
                .password(passwordEncoder.encode(request.getPassword())) // 암호화 저장
                .name(request.getName())
                .role("USER")
                .build();

        return memberRepository.save(member).getId();
    }

    // 로그인 -> 토큰 반환
    public String login(AuthDto.LoginRequest request) {
        Member member = memberRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new RuntimeException("존재하지 않는 아이디입니다."));

        // 비밀번호 검증 (입력받은 PW vs DB 암호화 PW)
        if (!passwordEncoder.matches(request.getPassword(), member.getPassword())) {
            throw new RuntimeException("비밀번호가 일치하지 않습니다.");
        }

        // 인증 성공 시 토큰 생성
        return jwtTokenProvider.createToken(member.getUsername());
    }
}