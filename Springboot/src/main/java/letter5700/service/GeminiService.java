package letter5700.service;

import com.google.genai.Client;
import com.google.genai.types.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

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
            String modelName = "gemini-2.5-flash";
            String prompt = """
            당신은 '5700 레터'라는 서비스의 AI 조언자입니다.
            사용자의 일기를 읽고, 그 마음을 깊이 헤아려 약 5,700자 분량(공백 포함)의 매우 긴 편지를 써주세요.
            
            [지침]
            1. 단순한 위로를 넘어, 심리적/철학적 통찰을 제공하세요.
            2. 문체는 따뜻하고 서정적이며, 때로는 냉철한 분석도 포함하세요.
            3. 서론-본론(다각도 분석)-결론의 구조를 갖추고 풍부한 문장을 사용하세요.
            4. 절대 요약하지 말고, 이야기를 풀어서 서술하세요.
            5. 답변을 작성할 때 문장 앞에 숫자를 붙이는 형태의 번호 매기기를 사용하지 않는다
            6. 문장을 강조할 때 별표(*)를 이용한 굵게 표시를 사용하지 않는다
            7. 과도한 장식, 과도한 Markdown 형식, 불필요한 시각적 강조를 피한다
            
            [사용자 일기]
            %s
            """.formatted(userRecord);

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
            return "아직 마음을 정리하는 중입니다. 잠시 후 다시 시도해주세요. (Error: " + e.getMessage() + ")";
        }
    }

    // [추가] 텍스트의 감정을 단어 하나로 분석하는 메서드
    public String analyzeEmotion(String text) {
        try {
            String prompt = """
                다음 일기를 읽고, 작성자의 감정을 가장 잘 나타내는 단어를 아래 목록 중에서 딱 하나만 골라 답변해줘.
                설명이나 다른 말은 절대 하지 말고, 오직 단어 하나만 출력해.
                
                [감정 목록]
                기쁨, 슬픔, 불안, 분노, 평온, 우울, 기대, 후회, 벅참, 피로
                
                [일기 내용]
                %s
                """.formatted(text);

            // 분석은 짧고 빠르면 되니 flash 모델 사용
            return getAdvice(prompt).trim(); // 기존 getAdvice 메서드 재활용 (또는 별도 호출)
        } catch (Exception e) {
            return "평온"; // 에러 시 기본값
        }
    }

    // [추가] 텍스트 -> 벡터 변환 메서드
    public List<Float> createEmbedding(String text) {
        try {
            EmbedContentResponse response = client.models.embedContent(
                    "text-embedding-004",
                    text,
                    null
            );

            List<ContentEmbedding> embeddingList =
                    response.embeddings().orElseThrow(() ->
                            new RuntimeException("임베딩 응답에 embeddings 필드가 없습니다.")
                    );

            if (embeddingList.isEmpty()) {
                throw new RuntimeException("임베딩 리스트가 비어 있습니다.");
            }

            ContentEmbedding embedding = embeddingList.get(0);

            // 여기! embedding.values() 가 Optional<List<Float>> 라서 풀어줘야 함

            return embedding.values().orElseThrow(() ->
                    new RuntimeException("임베딩 값이 없습니다.")
            );

        } catch (Exception e) {
            throw new RuntimeException("임베딩 생성 중 오류 발생: " + e.getMessage(), e);
        }
    }

}