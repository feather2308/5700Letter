package letter5700.controller;

import letter5700.dto.RecordRequest;
import letter5700.dto.RecordResponse;
import letter5700.service.RecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/records") // 공통 경로
@RequiredArgsConstructor
public class RecordController {

    private final RecordService recordService;

    // 1. 기록 저장 API
    // (request에 memberId가 없어도, 토큰(UserDetails)에서 꺼내서 저장)
    @PostMapping
    public ResponseEntity<Map<String, Object>> saveRecord(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody RecordRequest request) {

        // 서비스에 'username' 전달
        Long recordId = recordService.saveRecord(request, userDetails.getUsername());

        Map<String, Object> response = new HashMap<>();
        response.put("message", "기록 저장 성공!");
        response.put("recordId", recordId);

        return ResponseEntity.ok(response);
    }

    // 2. 상세 조회 API (특정 기록 ID로 조회)
    @GetMapping("/{id}")
    public ResponseEntity<RecordResponse> getRecord(@PathVariable Long id) {
        return ResponseEntity.ok(recordService.getRecord(id));
    }

    // 3. 내 기록 목록 조회 API
    // 경로: /api/records/member/me
    @GetMapping("/member/me")
    public ResponseEntity<List<RecordResponse>> getMemberRecords(
            @AuthenticationPrincipal UserDetails userDetails) {

        return ResponseEntity.ok(recordService.getMemberRecords(userDetails.getUsername()));
    }

    // 4. 기록 전체 삭제 API
    // 경로: /api/records/member/me
    @DeleteMapping("/member/me")
    public ResponseEntity<String> deleteAllRecords(
            @AuthenticationPrincipal UserDetails userDetails) {

        recordService.deleteAllRecords(userDetails.getUsername());
        return ResponseEntity.ok("모든 기록이 삭제되었습니다.");
    }

    @GetMapping("/ping")
    public String ping() {
        return "pong";
    }
}