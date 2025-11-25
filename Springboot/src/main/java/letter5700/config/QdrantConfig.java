package letter5700.config;

import io.qdrant.client.QdrantClient;
import io.qdrant.client.QdrantGrpcClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QdrantConfig {

    @Bean
    public QdrantClient qdrantClient() {
        // Docker의 Qdrant gRPC 포트(6334)로 연결
        return new QdrantClient(
                QdrantGrpcClient.newBuilder("localhost", 6334, false).build()
        );
    }

}