package letter5700.controller;

import letter5700.dto.AuthDto;
import letter5700.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    // 회원가입 API
    @PostMapping("/signup")
    public ResponseEntity<String> signup(@RequestBody AuthDto.SignupRequest request) {
        authService.signup(request);
        return ResponseEntity.ok("회원가입 성공");
    }

    // 로그인 API
    @PostMapping("/login")
    public ResponseEntity<AuthDto.TokenResponse> login(@RequestBody AuthDto.LoginRequest request) {
        String token = authService.login(request);
        return ResponseEntity.ok(new AuthDto.TokenResponse(token));
    }
}