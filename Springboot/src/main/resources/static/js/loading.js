// 로딩 페이지 JavaScript

document.addEventListener('DOMContentLoaded', function() {
    const contentPreview = document.getElementById('contentPreview');
    const timestamp = document.getElementById('timestamp');

    // URL 파라미터에서 recordId 가져오기
    const urlParams = new URLSearchParams(window.location.search);
    const recordId = urlParams.get('recordId');

    if (recordId) {
        // 기록 상세 정보 가져오기
        loadRecordContent(recordId);

        // AI 응답 대기
        pollForAdvice(recordId);
    } else {
        // 로컬 스토리지에서 임시 저장된 내용 가져오기
        const savedContent = localStorage.getItem('pendingContent');
        if (savedContent) {
            displayContent(savedContent);
        }
    }

    // 현재 시간 표시
    displayCurrentTime();

    // 기록 내용 불러오기
    function loadRecordContent(recordId) {
        fetch('/api/records/' + recordId, {
            method: 'GET',
            headers: {
                'Authorization': 'Bearer ' + getToken()
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data && data.content) {
                displayContent(data.content);
            }
        })
        .catch(error => {
            console.error('Error loading record:', error);
        });
    }

    // 내용 표시
    function displayContent(content) {
        if (contentPreview) {
            // 내용을 적절히 잘라서 표시 (최대 300자)
            const displayText = content.length > 300
                ? content.substring(0, 300) + '...'
                : content;
            contentPreview.textContent = displayText;
        }
    }

    // AI 응답 폴링
    function pollForAdvice(recordId) {
        const pollInterval = setInterval(function() {
            fetch('/api/records/' + recordId + '/advice', {
                method: 'GET',
                headers: {
                    'Authorization': 'Bearer ' + getToken()
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data && data.content) {
                    // AI 응답이 준비되면 결과 페이지로 이동
                    clearInterval(pollInterval);
                    localStorage.removeItem('pendingContent');
                    window.location.href = '/result/' + recordId;
                }
            })
            .catch(error => {
                console.error('Error polling advice:', error);
            });
        }, 2000); // 2초마다 확인

        // 최대 5분 후 타임아웃
        setTimeout(function() {
            clearInterval(pollInterval);
            alert('응답 생성에 시간이 너무 오래 걸립니다. 나중에 다시 확인해주세요.');
            window.location.href = '/home';
        }, 300000);
    }

    // 현재 시간 표시
    function displayCurrentTime() {
        const now = new Date();
        const year = String(now.getFullYear()).slice(2);
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');

        const timeString = `${year}.${month}.${day} ${hours}:${minutes}`;
        timestamp.textContent = timeString;
    }

    // 토큰 가져오기
    function getToken() {
        return localStorage.getItem('token') || '';
    }
});
