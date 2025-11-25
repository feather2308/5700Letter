package letter5700.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // 1. CSRF 보안 끄기 (API 테스트 할 때 방해됨)
                .csrf(AbstractHttpConfigurer::disable)
                // 2. 기본 로그인 페이지 끄기
                .formLogin(AbstractHttpConfigurer::disable)
                // 3. HTTP Basic 인증 끄기
                .httpBasic(AbstractHttpConfigurer::disable)
                // 4. 모든 요청 허용 (누구나 접속 가능하게)
                .authorizeHttpRequests(auth -> auth
                        .anyRequest().permitAll()
                );

        return http.build();
    }
}