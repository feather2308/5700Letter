package letter5700.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import jakarta.annotation.PostConstruct;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.IOException;

@Service
public class FcmService {

    // 서버 켜질 때 Firebase 연동
    @PostConstruct
    public void init() {
        try {
            // 아까 resource에 넣은 키 파일 읽기
            var resource = new ClassPathResource("firebase-account.json");

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(resource.getInputStream()))
                        .build();
                FirebaseApp.initializeApp(options);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 알림 전송 메서드
    public void sendNotification(String token, String title, String body) {
        if (token == null || token.isEmpty()) return;

        try {
            Message message = Message.builder()
                    .setToken(token) // 수신자 (앱에서 받은 토큰)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .build();

            FirebaseMessaging.getInstance().send(message);
            System.out.println(">>> FCM 알림 전송 성공: " + token);

        } catch (Exception e) {
            System.err.println(">>> FCM 전송 실패: " + e.getMessage());
        }
    }
}