// 홈 화면 JavaScript

document.addEventListener('DOMContentLoaded', function() {
    const menuButton = document.getElementById('menuButton');
    const recordButton = document.getElementById('recordButton');
    const contentInput = document.getElementById('contentInput');

    const sidebar = document.getElementById('sidebar');
    const recordsList = document.getElementById('recordsList');

    // 메뉴 버튼 클릭 이벤트
    if (menuButton) {
        menuButton.addEventListener('click', function() {
            sidebar.classList.toggle('expanded');

            // 사이드바가 확장되면 기록 목록을 불러옵니다
            if (sidebar.classList.contains('expanded')) {
                loadRecords();
            }
        });
    }

    // 기록 목록 불러오기
    function loadRecords() {
        // TODO: 실제 API 엔드포인트로 변경 필요
        fetch('/api/records', {
            method: 'GET',
            headers: {
                'Authorization': 'Bearer ' + getToken()
            }
        })
        .then(response => response.json())
        .then(data => {
            displayRecords(data);
        })
        .catch(error => {
            console.error('Error loading records:', error);
        });
    }

    // 기록 목록 표시
    function displayRecords(records) {
        if (!recordsList) return;

        recordsList.innerHTML = '';

        if (records && records.length > 0) {
            records.forEach(record => {
                const recordItem = document.createElement('div');
                recordItem.className = 'record-item';

                // 텍스트 30자로 제한
                const displayText = record.content.length > 30
                    ? record.content.substring(0, 30) + '...'
                    : record.content;

                recordItem.textContent = displayText;
                recordItem.onclick = () => viewRecord(record.id);

                recordsList.appendChild(recordItem);
            });
        } else {
            recordsList.innerHTML = '<p style="color: #999; font-size: 16px;">기록이 없습니다</p>';
        }
    }

    // 기록 상세보기
    function viewRecord(recordId) {
        window.location.href = '/result/' + recordId;
    }

    // 녹음 버튼 클릭 이벤트
    if (recordButton) {
        recordButton.addEventListener('click', function() {
            const content = contentInput.value.trim();

            if (!content) {
                alert('내용을 입력해주세요.');
                return;
            }

            // TODO: 글 제출 기능 구현
            console.log('제출할 내용:', content);

            // API 호출 예시
            submitContent(content);
        });
    }

    // 내용 제출 함수
    function submitContent(content) {
        // TODO: 실제 API 엔드포인트로 변경 필요
        fetch('/api/records', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + getToken()
            },
            body: JSON.stringify({
                content: content
            })
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            console.log('Success:', data);
            // TODO: 성공 시 로딩 페이지로 이동
            window.location.href = '/loading';
        })
        .catch(error => {
            console.error('Error:', error);
            alert('제출 중 오류가 발생했습니다.');
        });
    }

    // 토큰 가져오기 함수
    function getToken() {
        // TODO: 실제 토큰 저장/가져오기 로직 구현
        return localStorage.getItem('token') || '';
    }

    // 텍스트 영역 자동 높이 조절
    if (contentInput) {
        contentInput.addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = this.scrollHeight + 'px';
        });
    }
});
