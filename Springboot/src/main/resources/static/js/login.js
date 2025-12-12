document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("loginForm");

    form.addEventListener("submit", async (e) => {
        e.preventDefault();

        const username = document.getElementById("username").value.trim();
        const password = document.getElementById("password").value.trim();

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
            window.location.href = "/";
        } catch (err) {
            alert("로그인 중 오류가 발생했습니다.");
        }
    });
});
