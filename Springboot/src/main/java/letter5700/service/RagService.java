package letter5700.service;

import io.qdrant.client.QdrantClient;
import io.qdrant.client.QdrantGrpcClient;
import io.qdrant.client.grpc.Collections.Distance;
import io.qdrant.client.grpc.Collections.VectorParams;
import io.qdrant.client.grpc.JsonWithInt;
import io.qdrant.client.grpc.Points;
import io.qdrant.client.grpc.Points.PointStruct;
import io.qdrant.client.grpc.Points.ScoredPoint;
import io.qdrant.client.grpc.Points.SearchPoints;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;


import jakarta.annotation.PostConstruct;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static io.qdrant.client.PointIdFactory.id;
import static io.qdrant.client.VectorFactory.vector;
import static io.qdrant.client.VectorsFactory.namedVectors;

@Service
@RequiredArgsConstructor
public class RagService {

    // Qdrant 클라이언트 인스턴스
    private QdrantClient qdrantClient;
    private final GeminiService geminiService;

    // 컬렉션 이름, 벡터 이름, 벡터 차원 정의
    private final String COLLECTION = "advice_knowledge";
    private final String VECTOR_NAME = "text";
    private final int VECTOR_SIZE = 768;

    @PostConstruct
    public void init() {
        // Qdrant 클라이언트 초기화 (localhost:6334 기본값)
        qdrantClient = new QdrantClient(
                QdrantGrpcClient.newBuilder("localhost", 6334, false).build()
        );
        // 서버 시작 시 컬렉션이 없으면 자동 생성
        initCollection();
    }

    // 자원 해제
    @PreDestroy
    public void close() {
        if (qdrantClient != null) {
            qdrantClient.close();
        }
    }

    /**
     * Qdrant 1.16 Named Vector 기반 컬렉션 생성
     * - vector params 설정: size, distance
     * - NamedVectors 생성(map<string, VectorParams>)
     * - VectorsConfig에 NamedVectors 추가
     * - 컬렉션 생성(CreateCollection)
     */
    public void initCollection() {
        try {
            // [수정] 컬렉션 존재 여부 먼저 확인 (에러 방지)
            if (qdrantClient.collectionExistsAsync(COLLECTION).get()) {
                System.out.println(">>> Collection already exists: " + COLLECTION);
                return;
            }

            // VectorParams 생성 (size, distance 설정)
            VectorParams vectorParams = VectorParams.newBuilder()
                    .setSize(VECTOR_SIZE)
                    .setDistance(Distance.Cosine)
                    .build();

            // Named Vectors로 컬렉션 생성
            Map<String, VectorParams> namedVectorsMap = Map.of(VECTOR_NAME, vectorParams);

            qdrantClient.createCollectionAsync(COLLECTION, namedVectorsMap).get();

            System.out.println("Collection created: " + COLLECTION);

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to create collection", e);
        }
    }

    // [추가] 지식 데이터 초기화 메서드
    public void initKnowledgeBase() {
        System.out.println(">>> RAG 데이터 주입 시작...");

        String[] knowledgeTexts = {
                "불안은 통제할 수 없는 미래를 통제하려는 마음에서 온다. 현재에 집중하라.",
                "진정한 휴식은 멈춤이 아니라, 나를 돌보는 적극적인 행위이다.",
                "슬픔을 억누르면 엉뚱한 곳에서 터진다. 충분히 울어야 비로소 웃을 수 있다."
        };

        for (String text : knowledgeTexts) {
            try {
                // 1. 텍스트 -> 임베딩 변환 (Gemini 이용)
                List<Float> vector = geminiService.createEmbedding(text);

                // 2. Qdrant 저장 (자기 자신의 메서드 호출)
                upsert(UUID.randomUUID(), vector, Map.of("content", text));

            } catch (Exception e) {
                System.err.println("데이터 주입 중 오류 발생 (" + text + "): " + e.getMessage());
            }
        }
        System.out.println(">>> RAG 데이터 주입 완료! (" + knowledgeTexts.length + "건)");
    }

    /**
     * Point upsert
     * - payload를 JsonWithInt 형태로 변환
     * - float[] → Points.Vector 변환
     * - NamedVectors(map<string, Vector>) 생성
     * - Points.Vectors로 래핑
     * - PointStruct 생성(id, vectors, payload)
     * - UpsertPoints 요청 실행
     */
    public void upsert(UUID id, List<Float> vector, Map<String, Object> payload) {
        try {
            // Named vectors 생성 (VectorFactory.vector + VectorsFactory.namedVectors)
            Points.Vector pointVector = vector(vector);
            Points.Vectors pointVectors = namedVectors(Map.of(VECTOR_NAME, pointVector));

            // Payload 변환 (Map<String, Object> → Map<String, JsonWithInt.Value>)
            Map<String, JsonWithInt.Value> payloadMap = new HashMap<>();
            for (Map.Entry<String, Object> entry : payload.entrySet()) {
                payloadMap.put(entry.getKey(), convertToValue(entry.getValue()));
            }

            // PointStruct 생성
            PointStruct point = PointStruct.newBuilder()
                    .setId(id(id))
                    .setVectors(pointVectors)
                    .putAllPayload(payloadMap)
                    .build();

            // UpsertPoints 실행
            qdrantClient.upsertAsync(COLLECTION, List.of(point)).get();

            System.out.println("Point upserted: " + id);

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to upsert point", e);
        }
    }

    /**
     * Search
     * - query vector → Points.Vector 변환
     * - NamedVectors 생성 후 Points.Vectors로 래핑
     * - SearchPoints 요청 생성(setCollectionName, addVectors, setLimit, setWithPayload)
     * - Qdrant searchAsync 호출 후 결과 반환
     */
    public List<ScoredPoint> search(List<Float> queryVector, int limit) {
        try {
            // SearchPoints 요청 생성
            SearchPoints searchRequest = SearchPoints.newBuilder()
                    .setCollectionName(COLLECTION)
                    .addAllVector(queryVector)
                    .setLimit(limit)
                    .setWithPayload(Points.WithPayloadSelector.newBuilder()
                            .setEnable(true)
                            .build())
                    .setVectorName(VECTOR_NAME)  // Named vector 지정
                    .build();

            // 검색 실행
            List<ScoredPoint> results = qdrantClient.searchAsync(searchRequest).get();

            return results;

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to search", e);
        }
    }

    /**
     * float[] → List<Float> 변환
     * - 벡터를 protobuf에서 사용 가능한 형태로 변환
     */
    private List<Float> floatArrayToList(float[] arr) {
        return IntStream.range(0, arr.length)
                .mapToObj(i -> arr[i])
                .collect(Collectors.toList());
    }

    /**
     * Object → JsonWithInt.Value 변환
     * - Payload 값을 Qdrant가 받을 수 있는 형태로 변환
     */
    private JsonWithInt.Value convertToValue(Object obj) {
        if (obj == null) {
            return JsonWithInt.Value.newBuilder()
                    .setNullValue(io.qdrant.client.grpc.JsonWithInt.NullValue.NULL_VALUE)
                    .build();
        } else if (obj instanceof String) {
            return JsonWithInt.Value.newBuilder()
                    .setStringValue((String) obj)
                    .build();
        } else if (obj instanceof Integer) {
            return JsonWithInt.Value.newBuilder()
                    .setIntegerValue((Integer) obj)
                    .build();
        } else if (obj instanceof Long) {
            return JsonWithInt.Value.newBuilder()
                    .setIntegerValue((Long) obj)
                    .build();
        } else if (obj instanceof Double) {
            return JsonWithInt.Value.newBuilder()
                    .setDoubleValue((Double) obj)
                    .build();
        } else if (obj instanceof Boolean) {
            return JsonWithInt.Value.newBuilder()
                    .setBoolValue((Boolean) obj)
                    .build();
        } else {
            throw new IllegalArgumentException("Unsupported payload type: " + obj.getClass());
        }
    }
}