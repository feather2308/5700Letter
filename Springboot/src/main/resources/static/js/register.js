document.getElementById("registerForm").addEventListener("submit", async function (e) {
    e.preventDefault();

    const data = {
        username: document.getElementById("username").value,
        password: document.getElementById("password").value,
        nickname: document.getElementById("nickname").value
    };

    try {
        const res = await fetch("/api/auth/register", {
            method: "POST",
            headers: {"Content-Type": "application/json"},
            body: JSON.stringify(data)
        });

        if (!res.ok) {
            alert("회원가입 실패\n입력값을 다시 확인해주세요.");
            return;
        }

        alert("회원가입이 완료되었습니다!");
        location.href = "/login";
    } catch (err) {
        console.error(err);
        alert("서버 오류가 발생했습니다.");
    }
});
