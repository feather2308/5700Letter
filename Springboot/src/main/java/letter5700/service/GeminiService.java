package letter5700.service;

import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class GeminiService {

    private final Client client;

    // 생성자에서 API 키를 주입받아 Client 초기화
    public GeminiService(@Value("${gemini.api.key}") String apiKey) {
        this.client = Client.builder()
                .apiKey(apiKey)
                .build();
    }

    public String getAdvice(String userRecord) {
        try {
            // 1. 모델명과 프롬프트 설정 (Gemini 1.5 Flash 사용)
            String modelName = "gemini-1.5-flash";
            String prompt = "다음 일기를 쓴 사람에게 5700자 내외의 따뜻하고 깊이 있는 조언을 해줘:\n\n" + userRecord;

            // 2. 라이브러리를 통해 요청 전송
            GenerateContentResponse response = client.models.generateContent(
                    modelName,
                    prompt,
                    null
            );

            // 3. 응답 텍스트 추출
            return response.text();

        } catch (Exception e) {
            e.printStackTrace();
            return "조언 생성 중 오류가 발생했습니다: " + e.getMessage();
        }
    }
}