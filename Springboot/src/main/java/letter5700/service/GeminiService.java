package letter5700.service;

import letter5700.dto.GeminiRequest;
import letter5700.dto.GeminiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
@RequiredArgsConstructor
public class GeminiService {

    @Value("${gemini.api.key}")
    private String apiKey;

    @Value("${gemini.api.url}")
    private String apiUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    public String getAdvice(String userRecord) {
        // 1. 요청 URL 완성 (키 포함)
        String requestUrl = apiUrl + "?key=" + apiKey;

        // 2. 프롬프트 구성 (나중에 RAG와 프롬프트 빌더로 고도화 예정)
        String prompt = "다음 일기를 쓴 사람에게 5700자 내외의 따뜻하고 깊이 있는 조언을 해줘:\n\n" + userRecord;

        // 3. 요청 객체 생성
        GeminiRequest request = GeminiRequest.create(prompt);

        // 4. API 호출
        GeminiResponse response = restTemplate.postForObject(requestUrl, request, GeminiResponse.class);

        // 5. 응답 파싱 (텍스트만 추출)
        if (response != null && !response.getCandidates().isEmpty()) {
            return response.getCandidates().get(0).getContent().getParts().get(0).getText();
        }

        return "조언 생성에 실패했습니다.";
    }
}