import 'package:hive/hive.dart';

part 'credential.g.dart';

@HiveType(typeId: 0)
class Credential extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String appName;

  @HiveField(2)
  String profileName;

  @HiveField(3)
  String username;

  @HiveField(4)
  String encryptedPassword;

  @HiveField(5)
  String? website;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  String? iconUrl;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  bool isFavorite;

  @HiveField(11)
  String? category;

  Credential({
    required this.id,
    required this.appName,
    required this.profileName,
    required this.username,
    required this.encryptedPassword,
    this.website,
    this.notes,
    this.iconUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.category,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'profileName': profileName,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'website': website,
      'notes': notes,
      'iconUrl': iconUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'category': category,
    };
  }

  // Create from Map (Firebase)
  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'],
      appName: map['appName'],
      profileName: map['profileName'],
      username: map['username'],
      encryptedPassword: map['encryptedPassword'],
      website: map['website'],
      notes: map['notes'],
      iconUrl: map['iconUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isFavorite: map['isFavorite'] ?? false,
      category: map['category'],
    );
  }

  Credential copyWith({
    String? id,
    String? appName,
    String? profileName,
    String? username,
    String? encryptedPassword,
    String? website,
    String? notes,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? category,
  }) {
    return Credential(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      profileName: profileName ?? this.profileName,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
    );
  }
}
