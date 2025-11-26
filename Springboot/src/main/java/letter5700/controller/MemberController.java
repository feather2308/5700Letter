package letter5700.controller;

import letter5700.entity.Member;
import letter5700.service.MemberService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/member")
@RequiredArgsConstructor
public class MemberController {

    private final MemberService memberService;

    // 내 정보 조회 API
    // @AuthenticationPrincipal: SecurityContext에 저장된 유저 정보를 바로 가져옴
    @GetMapping("/me")
    public ResponseEntity<Member> getMyInfo(@AuthenticationPrincipal UserDetails userDetails) {
        Member member = memberService.getMyInfo(userDetails.getUsername());
        return ResponseEntity.ok(member);
    }

    @Data
    static class UpdateRequest {
        private String name;
    }

    // [추가] 내 정보 수정 API
    @PutMapping("/me")
    public ResponseEntity<String> updateMyInfo(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateRequest request) {

        memberService.updateMyInfo(userDetails.getUsername(), request.getName());
        return ResponseEntity.ok("정보가 수정되었습니다.");
    }
}