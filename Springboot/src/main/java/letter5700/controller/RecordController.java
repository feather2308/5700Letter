package letter5700.controller;

import letter5700.dto.RecordRequest;
import letter5700.service.GeminiService;
import letter5700.service.RecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/records") // 공통 주소
@RequiredArgsConstructor
public class RecordController {

    private final RecordService recordService;
    private final GeminiService geminiService;

    // 기록 저장 API
    @PostMapping
    public ResponseEntity<String> saveRecord(@RequestBody RecordRequest request) {
        Long recordId = recordService.saveRecord(request);
        return ResponseEntity.ok("기록 저장 성공! ID: " + recordId);
    }

    // 테스트용: 서버 체크
    @GetMapping("/ping")
    public String ping() {
        return "pong";
    }

    // [테스트] Gemini 연결 확인용
    @PostMapping("/test-gemini")
    public String testGemini(@RequestBody String text) {
        return geminiService.getAdvice(text);
    }
}