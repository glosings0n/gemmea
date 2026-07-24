class CalendarEvent {
  final int? id;
  final String title;
  final String eventDate; // YYYY-MM-DD
  final String description;
  final bool isRainy;

  CalendarEvent({
    this.id,
    required this.title,
    required this.eventDate,
    required this.description,
    required this.isRainy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'event_date': eventDate,
      'description': description,
      'is_rainy': isRainy ? 1 : 0,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      eventDate: map['event_date'] as String,
      description: map['description'] as String,
      isRainy: (map['is_rainy'] as int) == 1,
    );
  }

  CalendarEvent copyWith({
    int? id,
    String? title,
    String? eventDate,
    String? description,
    bool? isRainy,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      description: description ?? this.description,
      isRainy: isRainy ?? this.isRainy,
    );
  }
}
