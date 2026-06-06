class HandledClassModel {
  final String id;
  final String sectionId;
  final String sectionName;
  final String levelName;
  final String subjectId;
  final String subjectName;
  final String subjectCode;

  HandledClassModel({
    required this.id,
    required this.sectionId,
    required this.sectionName,
    required this.levelName,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
  });

  factory HandledClassModel.fromJson(Map<String, dynamic> json) {
    final section = json['section'] ?? {};
    final subject = json['subject'] ?? {};
    final level = section['level'] ?? {};

    return HandledClassModel(
      id: json['_id'] ?? '',
      sectionId: section['_id'] ?? '',
      sectionName: section['name'] ?? 'Unknown Section',
      levelName: level['name'] ?? 'Unknown Level',
      subjectId: subject['_id'] ?? '',
      subjectName: subject['name'] ?? 'Unknown Subject',
      subjectCode: subject['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'section': {
        '_id': sectionId,
        'name': sectionName,
        'level': { 'name': levelName }
      },
      'subject': {
        '_id': subjectId,
        'name': subjectName,
        'code': subjectCode
      }
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String token;
  final String? section;
  final int xp;
  final String? profilePicture;
  final List<HandledClassModel>? handledClasses;
  final String? specialty;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.section,
    this.xp = 0,
    this.profilePicture,
    this.handledClasses,
    this.specialty,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      token: json['token'] ?? '',
      section: json['section'] is String ? json['section'] : json['section']?['_id'],
      xp: json['xp'] ?? 0,
      profilePicture: json['profilePicture'],
      handledClasses: (json['handledClasses'] as List<dynamic>?)
          ?.map((e) => HandledClassModel.fromJson(e))
          .toList(),
      specialty: json['specialty'],
    );
  }

  UserModel copyWith({String? profilePicture, List<HandledClassModel>? handledClasses, String? specialty}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      token: token,
      section: section,
      xp: xp,
      profilePicture: profilePicture ?? this.profilePicture,
      handledClasses: handledClasses ?? this.handledClasses,
      specialty: specialty ?? this.specialty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'token': token,
      'section': section,
      'xp': xp,
      'profilePicture': profilePicture,
      'handledClasses': handledClasses?.map((e) => e.toJson()).toList(),
      'specialty': specialty,
    };
  }
}
