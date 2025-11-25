package letter5700.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GeminiRequest {
    private List<Content> contents;

    @Data
    @AllArgsConstructor
    public static class Content {
        private List<Part> parts;
    }

    @Data
    @AllArgsConstructor
    public static class Part {
        private String text;
    }

    // 편의 메서드
    public static GeminiRequest create(String text) {
        return new GeminiRequest(List.of(new Content(List.of(new Part(text)))));
    }
}