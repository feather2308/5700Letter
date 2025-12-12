// 결과 페이지 JavaScript

document.addEventListener('DOMContentLoaded', function() {
    const detailButton = document.getElementById('detailButton');
    const emotionResult = document.getElementById('emotionResult');
    const advicePreview = document.getElementById('advicePreview');
    const timestamp = document.getElementById('timestamp');

    // URL에서 recordId 가져오기
    const pathParts = window.location.pathname.split('/');
    const recordId = pathParts[pathParts.length - 1];

    if (recordId) {
        // 기록 및 조언 데이터 로드
        loadResultData(recordId);
    }

    // 자세히 보기 버튼 클릭
    if (detailButton) {
        detailButton.addEventListener('click', function() {
            window.location.href = '/result/' + recordId + '/detail';
        });
    }

    // 결과 데이터 로드
    function loadResultData(recordId) {
        fetch('/api/records/' + recordId + '/advice', {
            method: 'GET',
            headers: {
                'Authorization': 'Bearer ' + getToken()
            }
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            if (data) {
                displayResult(data);
            }
        })
        .catch(error => {
            console.error('Error loading result:', error);
            alert('결과를 불러오는 중 오류가 발생했습니다.');
        });
    }

    // 결과 표시
    function displayResult(data) {
        // 감정 표시
        if (data.emotion && emotionResult) {
            emotionResult.textContent = `"${data.emotion}"`;
        }

        // 조언 미리보기 (최대 150자)
        if (data.content && advicePreview) {
            const previewText = data.content.length > 150
                ? data.content.substring(0, 150) + ' ...'
                : data.content;
            advicePreview.textContent = previewText;
        }

        // 타임스탬프
        if (data.createdAt && timestamp) {
            const date = new Date(data.createdAt);
            const year = String(date.getFullYear()).slice(2);
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            const hours = String(date.getHours()).padStart(2, '0');
            const minutes = String(date.getMinutes()).padStart(2, '0');

            timestamp.textContent = `${year}.${month}.${day} ${hours}:${minutes}`;
        }
    }

    // 토큰 가져오기
    function getToken() {
        return localStorage.getItem('token') || '';
    }
});
