// lib/models/record.dart

class Record {
  final int id;
  final String content;
  final String emotion;
  final String? adviceContent;
  final String date; // [추가] 날짜 필드 (String으로 받음)

  Record({
    required this.id,
    required this.content,
    required this.emotion,
    this.adviceContent,
    required this.date, // [추가]
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      emotion: json['emotion'] ?? '',
      adviceContent: json['adviceContent'],
      date: json['date'] ?? '', // [추가] 백엔드가 "2024-11-26" 형식으로 줌
    );
  }
}