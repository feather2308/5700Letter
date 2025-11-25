package letter5700.controller;

import letter5700.dto.RecordRequest;
import letter5700.dto.RecordResponse;
import letter5700.service.GeminiService;
import letter5700.service.RecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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

    // [테스트] Gemini 연결 확인용
    @GetMapping("/test-gemini")
    public String testGeminiGet(@RequestParam("text") String text) {
        return geminiService.getAdvice(text);
    }

    // [추가] 1. 상세 조회 API (GET /api/records/{id})
    @GetMapping("/{id}")
    public ResponseEntity<RecordResponse> getRecord(@PathVariable Long id) {
        return ResponseEntity.ok(recordService.getRecord(id));
    }

    // [추가] 2. 내 기록 목록 조회 API (GET /api/records/member/{memberId})
    // (원래는 토큰에서 멤버 ID를 꺼내야 하지만, 지금은 파라미터로 받음)
    @GetMapping("/member/{memberId}")
    public ResponseEntity<List<RecordResponse>> getMemberRecords(@PathVariable Long memberId) {
        return ResponseEntity.ok(recordService.getMemberRecords(memberId));
    }

    // [추가] 기록 전체 삭제 API (DELETE /api/records/member/{memberId})
    @DeleteMapping("/member/{memberId}")
    public ResponseEntity<String> deleteAllRecords(@PathVariable Long memberId) {
        recordService.deleteAllRecords(memberId);
        return ResponseEntity.ok("모든 기록이 삭제되었습니다.");
    }
}