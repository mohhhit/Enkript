import 'package:cloud_firestore/cloud_firestore.dart';

class Credential {
  String id;
  String appName;
  String profileName;
  String username;
  String encryptedPassword;
  String? website;
  String? notes;
  String? iconUrl;
  DateTime createdAt;
  DateTime updatedAt;
  bool isFavorite;
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

  // Convert to Map for Firestore
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'category': category,
    };
  }

  // Create from Map (Firestore Document)
  factory Credential.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic dateVal) {
      if (dateVal is Timestamp) {
        return dateVal.toDate();
      } else if (dateVal is String) {
        return DateTime.parse(dateVal);
      }
      return DateTime.now();
    }

    return Credential(
      id: docId ?? map['id'] ?? '',
      appName: map['appName'] ?? '',
      profileName: map['profileName'] ?? '',
      username: map['username'] ?? '',
      encryptedPassword: map['encryptedPassword'] ?? '',
      website: map['website'],
      notes: map['notes'],
      iconUrl: map['iconUrl'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
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