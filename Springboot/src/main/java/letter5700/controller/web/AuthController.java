package letter5700.controller.web;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequiredArgsConstructor
@RequestMapping("/")
public class AuthController {

    @GetMapping("/login")
    public String login(Authentication authentication) {

        // 🔥 JWT 인증되었으면 자동 로그인 처리
        if (authentication != null && authentication.isAuthenticated()
                && !authentication.getPrincipal().equals("anonymousUser")) {

            return "redirect:/"; // 원하는 메인 페이지로 redirect
        }

        return "user/login"; // 로그인 페이지 렌더링
    }
}
