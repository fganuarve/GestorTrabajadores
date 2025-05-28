class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String workplace;
  final String role; // 'MÉDICO', 'ENFERMERO', 'TCAE'
  final String location;
  final String? phoneNumber;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.workplace,
    required this.role,
    required this.location,
    this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      workplace: json['workplace'] ?? '',
      role: json['role'] ?? '',
      location: json['location'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'workplace': workplace,
      'role': role,
      'location': location,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}
