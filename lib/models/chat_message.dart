import 'package:tourn/models/search_result.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? imagePath; // path on disk (mobile/desktop)
  final String?
  imageData; // base64 bytes (used on Web or when embedding image data)
  final List<SearchResult>?
  sources; // optional list of sources referenced by this message

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
    this.imageData,
    this.sources,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'time': time.toIso8601String(),
    'imagePath': imagePath,
    'imageData': imageData,
    'sources': sources?.map((s) => s.toJson()).toList(),
  };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] as String? ?? '',
    isUser: json['isUser'] as bool? ?? true,
    time: DateTime.parse(json['time'] as String),
    imagePath: json['imagePath'] as String?,
    imageData: json['imageData'] as String?,
    sources: (json['sources'] as List<dynamic>?)
        ?.map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
