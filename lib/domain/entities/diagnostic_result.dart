class DiagnosticResult {
  final int? id;
  final String cropName;
  final String disease;
  final double confidence;
  final String remedy;
  final String? imagePath;
  final DateTime timestamp;
  final String status;

  DiagnosticResult({
    this.id,
    required this.cropName,
    required this.disease,
    required this.confidence,
    required this.remedy,
    this.imagePath,
    required this.timestamp,
    this.status = 'new',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crop_name': cropName,
      'disease': disease,
      'confidence': confidence,
      'remedy': remedy,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory DiagnosticResult.fromMap(Map<String, dynamic> map) {
    return DiagnosticResult(
      id: map['id'] as int?,
      cropName: map['crop_name'] as String,
      disease: map['disease'] as String,
      confidence: map['confidence'] as double,
      remedy: map['remedy'] as String,
      imagePath: map['image_path'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: map['status'] as String? ?? 'new',
    );
  }

  DiagnosticResult copyWith({
    int? id,
    String? cropName,
    String? disease,
    double? confidence,
    String? remedy,
    String? imagePath,
    DateTime? timestamp,
    String? status,
  }) {
    return DiagnosticResult(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      disease: disease ?? this.disease,
      confidence: confidence ?? this.confidence,
      remedy: remedy ?? this.remedy,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
