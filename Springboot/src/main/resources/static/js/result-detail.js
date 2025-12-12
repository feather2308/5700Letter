// 상세 결과 페이지 JavaScript

document.addEventListener('DOMContentLoaded', function() {
    const closeButton = document.getElementById('closeButton');
    const emotionResult = document.getElementById('emotionResult');
    const userContent = document.getElementById('userContent');
    const adviceContent = document.getElementById('adviceContent');
    const timestamp = document.getElementById('timestamp');
    const contentSection = document.querySelector('.content-section');
    const scrollbarThumb = document.querySelector('.scrollbar-thumb');

    // URL에서 recordId 가져오기
    const pathParts = window.location.pathname.split('/');
    const recordId = pathParts[pathParts.indexOf('result') + 1];

    if (recordId) {
        // 상세 데이터 로드
        loadDetailData(recordId);
    }

    // 닫기 버튼 클릭
    if (closeButton) {
        closeButton.addEventListener('click', function() {
            window.location.href = '/result/' + recordId;
        });
    }

    // 스크롤바 동기화
    if (contentSection && scrollbarThumb) {
        contentSection.addEventListener('scroll', function() {
            const scrollPercentage = contentSection.scrollTop / (contentSection.scrollHeight - contentSection.clientHeight);
            const maxThumbTop = 211 - 100; // scrollbar height - thumb height
            scrollbarThumb.style.transform = `translateY(${scrollPercentage * maxThumbTop}px)`;
        });
    }

    // 상세 데이터 로드
    function loadDetailData(recordId) {
        // 기록 내용 가져오기
        fetch('/api/records/' + recordId, {
            method: 'GET',
            headers: {
                'Authorization': 'Bearer ' + getToken()
            }
        })
        .then(response => response.json())
        .then(recordData => {
            if (recordData && userContent) {
                userContent.textContent = recordData.content;

                // 타임스탬프 표시
                if (recordData.createdAt && timestamp) {
                    displayTimestamp(recordData.createdAt);
                }
            }

            // 조언 가져오기
            return fetch('/api/records/' + recordId + '/advice', {
                method: 'GET',
                headers: {
                    'Authorization': 'Bearer ' + getToken()
                }
            });
        })
        .then(response => response.json())
        .then(adviceData => {
            if (adviceData) {
                // 감정 표시
                if (adviceData.emotion && emotionResult) {
                    emotionResult.textContent = `"${adviceData.emotion}"`;
                }

                // 조언 표시
                if (adviceData.content && adviceContent) {
                    adviceContent.textContent = adviceData.content;
                }
            }
        })
        .catch(error => {
            console.error('Error loading detail data:', error);
            alert('상세 정보를 불러오는 중 오류가 발생했습니다.');
        });
    }

    // 타임스탬프 표시
    function displayTimestamp(dateString) {
        const date = new Date(dateString);
        const year = String(date.getFullYear()).slice(2);
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');

        timestamp.textContent = `${year}.${month}.${day} ${hours}:${minutes}`;
    }

    // 토큰 가져오기
    function getToken() {
        return localStorage.getItem('token') || '';
    }
});
