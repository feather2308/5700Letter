package letter5700.dto;

import lombok.Data;

public class AuthDto {

    @Data
    public static class SignupRequest {
        private String username;
        private String password;
        private String name;
    }

    @Data
    public static class LoginRequest {
        private String username;
        private String password;
    }

    @Data
    public static class TokenResponse {
        private String token;
        // 필요시 사용자 정보 추가 (name, id 등)

        public TokenResponse(String token) {
            this.token = token;
        }
    }
}