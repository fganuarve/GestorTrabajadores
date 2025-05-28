class ShiftModel {
  final String id;
  final String userId;
  final DateTime date;
  final String shiftType;
  final String? notes;
  final bool isCompleted;

  ShiftModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.shiftType,
    this.notes,
    this.isCompleted = false,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      shiftType: json['shiftType'] as String,
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'shiftType': shiftType,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }
}
