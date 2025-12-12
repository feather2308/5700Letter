document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("loginForm");

    form.addEventListener("submit", async (e) => {
        e.preventDefault();

        const username = document.getElementById("username").value.trim();
        const password = document.getElementById("password").value.trim();

        console.log('로그인 시도:', username);

        // 임시: 프론트 테스트용 - 바로 홈으로 이동
        if (username && password) {
            console.log('테스트 모드: 홈으로 이동');
            localStorage.setItem("accessToken", "test-token");
            window.location.href = "/home";
            return;
        }

        // 실제 API 호출 (DB 연결 시 사용)
        try {
            const res = await fetch("/api/auth/login", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ username, password })
            });

            if (!res.ok) {
                alert("아이디 또는 비밀번호가 올바르지 않습니다.");
                return;
            }

            const data = await res.json();

            // JWT 저장
            localStorage.setItem("accessToken", data.accessToken);

            // 메인 페이지로 이동
            window.location.href = "/home";
        } catch (err) {
            console.error('로그인 오류:', err);
            alert("로그인 중 오류가 발생했습니다.");
        }
    });
});
