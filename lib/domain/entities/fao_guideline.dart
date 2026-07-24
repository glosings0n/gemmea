class FAOGuideline {
  final int? id;
  final String topic;
  final String cropName;
  final String keywords;
  final String content;
  final String organicRemedy;
  final double estimatedLossPct;
  final String sourceCitation;

  FAOGuideline({
    this.id,
    required this.topic,
    required this.cropName,
    required this.keywords,
    required this.content,
    required this.organicRemedy,
    required this.estimatedLossPct,
    required this.sourceCitation,
  });

  factory FAOGuideline.fromMap(Map<String, dynamic> map) {
    return FAOGuideline(
      id: map['id'] as int?,
      topic: map['topic'] as String? ?? '',
      cropName: map['crop_name'] as String? ?? '',
      keywords: map['keywords'] as String? ?? '',
      content: map['content'] as String? ?? '',
      organicRemedy: map['organic_remedy'] as String? ?? '',
      estimatedLossPct: (map['estimated_loss_pct'] as num? ?? 0.0).toDouble(),
      sourceCitation: map['source_citation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'crop_name': cropName,
      'keywords': keywords,
      'content': content,
      'organic_remedy': organicRemedy,
      'estimated_loss_pct': estimatedLossPct,
      'source_citation': sourceCitation,
    };
  }
}
