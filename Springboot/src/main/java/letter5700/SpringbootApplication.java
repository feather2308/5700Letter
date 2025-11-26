package letter5700;

import letter5700.entity.Member;
import letter5700.repository.MemberRepository;
import letter5700.service.RagService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class SpringbootApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringbootApplication.class, args);
	}

	// 서버 시작 시 테스트 유저 1명 자동 생성
	@Bean
	public CommandLineRunner initData(MemberRepository memberRepository) {
		return args -> {
			if (memberRepository.count() == 0) {
				memberRepository.save(new Member("test@test.com", "1234", "테스트유저"));
				System.out.println(">>> 테스트용 회원 생성 완료 (ID: 1)");
			}
		};
	}

	@Bean
	public CommandLineRunner initRAG(RagService ragService) {
		return args -> {
			ragService.initKnowledgeBase(); // 서버 시작 시 지식 DB 구축
		};
	}
}
