import 'dart:convert';

class CustomField {
  const CustomField({required this.label, required this.value});

  final String label;
  final String value;

  Map<String, String> toMap() => {'label': label, 'value': value};

  factory CustomField.fromMap(Map<String, dynamic> map) {
    return CustomField(
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }
}

enum AvatarGender { female, male }

AvatarGender avatarGenderFromValue(String? value) {
  return value == 'male' ? AvatarGender.male : AvatarGender.female;
}

String avatarGenderToValue(AvatarGender value) {
  return value == AvatarGender.male ? 'male' : 'female';
}

class PersonSummary {
  const PersonSummary({
    required this.id,
    required this.name,
    required this.nicknames,
    required this.school,
    required this.course,
    required this.age,
    required this.primaryPhotoPath,
    required this.avatarStyle,
    required this.avatarGender,
    required this.customFields,
    required this.isPinned,
  });

  final int id;
  final String name;
  final String nicknames;
  final String school;
  final String course;
  final int? age;
  final String? primaryPhotoPath;
  final int avatarStyle;
  final AvatarGender avatarGender;
  final List<CustomField> customFields;
  final bool isPinned;

  factory PersonSummary.fromMap(Map<String, Object?> map) {
    return PersonSummary(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      nicknames: map['nicknames'] as String? ?? '',
      school: map['school'] as String? ?? '',
      course: map['course'] as String? ?? '',
      age: map['age'] as int?,
      primaryPhotoPath: map['profile_photo_path'] as String?,
      avatarStyle: map['avatar_style'] as int? ?? 0,
      avatarGender: avatarGenderFromValue(map['avatar_gender'] as String?),
      customFields: customFieldsFromJson(map['custom_fields'] as String?),
      isPinned: ((map['is_pinned'] as int?) ?? 0) == 1,
    );
  }
}

class PersonRecord {
  const PersonRecord({
    required this.id,
    required this.name,
    required this.nicknames,
    required this.school,
    required this.course,
    required this.birthday,
    required this.age,
    required this.details,
    required this.profilePhotoPath,
    required this.avatarStyle,
    required this.avatarGender,
    required this.customFields,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String nicknames;
  final String school;
  final String course;
  final DateTime? birthday;
  final int? age;
  final String details;
  final String? profilePhotoPath;
  final int avatarStyle;
  final AvatarGender avatarGender;
  final List<CustomField> customFields;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PersonRecord.fromMap(Map<String, Object?> map) {
    return PersonRecord(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      nicknames: map['nicknames'] as String? ?? '',
      school: map['school'] as String? ?? '',
      course: map['course'] as String? ?? '',
      birthday: map['birthday'] == null
          ? null
          : DateTime.tryParse(map['birthday'] as String),
      age: map['age'] as int?,
      details: map['details'] as String? ?? '',
      profilePhotoPath: map['profile_photo_path'] as String?,
      avatarStyle: map['avatar_style'] as int? ?? 0,
      avatarGender: avatarGenderFromValue(map['avatar_gender'] as String?),
      customFields: customFieldsFromJson(map['custom_fields'] as String?),
      isPinned: ((map['is_pinned'] as int?) ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    return {
      if (includeId) 'id': id,
      'name': name,
      'nicknames': nicknames,
      'school': school,
      'course': course,
      'birthday': birthday?.toIso8601String(),
      'age': age,
      'details': details,
      'profile_photo_path': profilePhotoPath,
      'avatar_style': avatarStyle,
      'avatar_gender': avatarGenderToValue(avatarGender),
      'custom_fields': customFieldsToJson(customFields),
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class NoteEntry {
  const NoteEntry({
    required this.id,
    required this.personId,
    required this.content,
    required this.createdAt,
    required this.isPinned,
  });

  final int id;
  final int personId;
  final String content;
  final DateTime createdAt;
  final bool isPinned;

  factory NoteEntry.fromMap(Map<String, Object?> map) {
    return NoteEntry(
      id: map['id'] as int,
      personId: map['person_id'] as int,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      isPinned: ((map['is_pinned'] as int?) ?? 0) == 1,
    );
  }
}

class PhotoAttachment {
  const PhotoAttachment({
    required this.id,
    required this.personId,
    required this.path,
    required this.createdAt,
  });

  final int id;
  final int personId;
  final String path;
  final DateTime createdAt;

  factory PhotoAttachment.fromMap(Map<String, Object?> map) {
    return PhotoAttachment(
      id: map['id'] as int,
      personId: map['person_id'] as int,
      path: map['path'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class PersonDetails {
  const PersonDetails({
    required this.person,
    required this.notes,
    required this.photos,
    required this.primaryPhotoPath,
  });

  final PersonRecord person;
  final List<NoteEntry> notes;
  final List<PhotoAttachment> photos;
  final String? primaryPhotoPath;
}

class GlobalSearchResult {
  const GlobalSearchResult({required this.people, required this.notes});

  final List<PersonSummary> people;
  final List<MatchedNote> notes;
}

class MatchedNote {
  const MatchedNote({required this.note, required this.person});

  final NoteEntry note;
  final PersonSummary person;
}

class StorageSummary {
  const StorageSummary({
    required this.totalBytes,
    required this.databaseBytes,
    required this.imageBytes,
    required this.backupBytes,
  });

  final int totalBytes;
  final int databaseBytes;
  final int imageBytes;
  final int backupBytes;
}

List<CustomField> customFieldsFromJson(String? value) {
  if (value == null || value.isEmpty) {
    return const [];
  }

  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }

  return decoded
      .whereType<Map>()
      .map((item) => CustomField.fromMap(Map<String, dynamic>.from(item)))
      .where(
        (field) =>
            field.label.trim().isNotEmpty && field.value.trim().isNotEmpty,
      )
      .toList();
}

String customFieldsToJson(List<CustomField> fields) {
  return jsonEncode(fields.map((field) => field.toMap()).toList());
}
