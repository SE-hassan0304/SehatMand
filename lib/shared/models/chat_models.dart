class ChatResponse {
  final String reply;
  final String type; // 'general' | 'specialist' | 'emergency' | 'clinical'
  final String? specialist;
  final List<Doctor> doctors;
  final String mode; // 'user' | 'doctor'

  ChatResponse({
    required this.reply,
    required this.type,
    this.specialist,
    required this.doctors,
    required this.mode,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? '',
      type: json['type'] ?? 'general',
      specialist: json['specialist'],
      mode: json['mode'] ?? 'user',
      doctors: (json['doctors'] as List<dynamic>? ?? [])
          .map((d) => Doctor.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmergency => type == 'emergency';
  bool get hasDoctors => doctors.isNotEmpty;
}

class Doctor {
  final String name;
  final String hospitalName;
  final String specialization;
  final String? phone;
  final String? pmdc;
  final String city;

  Doctor({
    required this.name,
    required this.hospitalName,
    required this.specialization,
    this.phone,
    this.pmdc,
    required this.city,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      name: json['name'] ?? 'N/A',
      hospitalName: json['hospital_name'] ?? 'N/A',
      specialization: json['specialization'] ?? 'N/A',
      phone: json['phone']?.toString(),
      pmdc: json['pmdc']?.toString(),
      city: json['city'] ?? 'karachi',
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatResponse? response;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.response,
  });
}
