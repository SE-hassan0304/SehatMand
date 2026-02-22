// lib/shared/models/chat_models.dart
//
// Models that exactly match the backend /api/chat JSON response:
// {
//   "reply"     : "AI response text",
//   "type"      : "general" | "specialist" | "emergency" | "emotional" | "general_chat",
//   "specialist": "cardiologist" | null,
//   "doctors"   : [ { name, hospital_name, specialization, phone, pmdc, city } ],
//   "mode"      : "user" | "doctor"
// }

class DoctorModel {
  final String name;
  final String hospitalName;
  final String specialization;
  final String? phone;
  final String? pmdc;
  final String city;

  const DoctorModel({
    required this.name,
    required this.hospitalName,
    required this.specialization,
    this.phone,
    this.pmdc,
    required this.city,
  });

  // Backend uses snake_case: hospital_name, not hospitalName
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      name: json['name'] as String? ?? 'N/A',
      hospitalName: json['hospital_name'] as String? ?? 'N/A',
      specialization: json['specialization'] as String? ?? 'N/A',
      phone: json['phone'] as String?,
      pmdc: json['pmdc'] as String?,
      city: json['city'] as String? ?? 'karachi',
    );
  }

  // Display-friendly doctor card line
  String get displayLine {
    final buffer = StringBuffer('${_title(name)} — ${_title(hospitalName)}');
    if (phone != null && phone!.isNotEmpty) buffer.write(' | 📞 $phone');
    return buffer.toString();
  }

  String _title(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// Response type enum matching backend "type" field
enum ChatResponseType {
  general,
  specialist,
  emergency,
  emotional,
  generalChat,
  clinical, // doctor mode
  unknown,
}

ChatResponseType _parseType(String? type) {
  switch (type) {
    case 'general':
      return ChatResponseType.general;
    case 'specialist':
      return ChatResponseType.specialist;
    case 'emergency':
      return ChatResponseType.emergency;
    case 'emotional':
      return ChatResponseType.emotional;
    case 'general_chat':
      return ChatResponseType.generalChat;
    case 'clinical':
      return ChatResponseType.clinical;
    default:
      return ChatResponseType.unknown;
  }
}

class ChatResponse {
  final String reply;
  final ChatResponseType type;
  final String? specialist;
  final List<DoctorModel> doctors;
  final String mode; // "user" or "doctor"

  const ChatResponse({
    required this.reply,
    required this.type,
    this.specialist,
    this.doctors = const [],
    required this.mode,
  });

  bool get hasDoctors => doctors.isNotEmpty;
  bool get isEmergency => type == ChatResponseType.emergency;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawDoctors = json['doctors'];
    final doctors = <DoctorModel>[];
    if (rawDoctors is List) {
      for (final d in rawDoctors) {
        if (d is Map<String, dynamic>) {
          doctors.add(DoctorModel.fromJson(d));
        }
      }
    }

    return ChatResponse(
      reply: json['reply'] as String? ?? 'Jawab nahi mila.',
      type: _parseType(json['type'] as String?),
      specialist: json['specialist'] as String?,
      doctors: doctors,
      mode: json['mode'] as String? ?? 'user',
    );
  }
}
