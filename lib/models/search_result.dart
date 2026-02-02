class SearchResult {
  final String id;
  final String title;
  final String url;
  final String excerpt;
  final double score;

  SearchResult({
    required this.id,
    required this.title,
    required this.url,
    required this.excerpt,
    this.score = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'excerpt': excerpt,
    'score': score,
  };

  static SearchResult fromJson(Map<String, dynamic> json) => SearchResult(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
    excerpt: json['excerpt'] as String? ?? '',
    score: (json['score'] is num) ? (json['score'] as num).toDouble() : 0.0,
  );
}
