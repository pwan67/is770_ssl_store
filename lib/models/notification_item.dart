class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // pawn, cart, store, appointment, price
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  factory NotificationItem.fromMap(String id, Map<String, dynamic> data) {
    return NotificationItem(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      timestamp: data['timestamp'] != null ? DateTime.parse(data['timestamp']) : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
