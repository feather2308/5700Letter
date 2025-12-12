package letter5700.controller.web;

import letter5700.dto.AuthDto;
import letter5700.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequiredArgsConstructor
@RequestMapping("/")
public class AuthController {

    private final AuthService authService;

    @GetMapping("/login")
    public String login(Authentication authentication) {

        // 🔥 JWT 인증되었으면 자동 로그인 처리
        if (authentication != null && authentication.isAuthenticated()
                && !authentication.getPrincipal().equals("anonymousUser")) {

            return "redirect:/"; // 원하는 메인 페이지로 redirect
        }

        return "user/login"; // 로그인 페이지 렌더링
    }

    // 🔹 회원가입 페이지 이동
    @GetMapping("/register")
    public String registerPage() {
        return "user/register";  // templates/user/register.html
    }

    // 🔹 회원가입 처리
    @PostMapping("/register")
    public String registerSubmit(@ModelAttribute AuthDto.SignupRequest request,
                                 Model model) {

        try {
            authService.signup(request);
        } catch (Exception e) {
            model.addAttribute("errorMessage", "회원가입 실패: " + e.getMessage());
            return "user/register";
        }

        return "redirect:/login";
    }
}
