class Appointment {
  final String id;
  final String userId;
  final String assetId;
  final String assetName;
  final DateTime date;
  final String status; // 'scheduled', 'completed', 'cancelled'

  Appointment({
    required this.id,
    required this.userId,
    required this.assetId,
    required this.assetName,
    required this.date,
    this.status = 'scheduled',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'assetId': assetId,
      'assetName': assetName,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  factory Appointment.fromMap(String docId, Map<String, dynamic> map) {
    return Appointment(
      id: docId,
      userId: map['userId'] ?? '',
      assetId: map['assetId'] ?? '',
      assetName: map['assetName'] ?? '',
      date: DateTime.parse(map['date']),
      status: map['status'] ?? 'scheduled',
    );
  }
}
