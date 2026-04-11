// lib/data/models/user_model.dart

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';
import 'folder_model.dart';

part 'user_model.g.dart';

/// Custom converter for lastActivity that can be either a String or int
int? _lastActivityFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    // Try parsing the Java-format date string "YYYY-MM-DD HH:MM:SS"
    try {
      final dt = DateTime.parse(value.replaceFirst(' ', 'T'));
      return dt.millisecondsSinceEpoch;
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Write lastActivity as a Java-compatible string format
String? _lastActivityToJson(int? value) {
  if (value == null) return null;
  final dt = DateTime.fromMillisecondsSinceEpoch(value);
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

@JsonSerializable(explicitToJson: true)
class UserModel {
  final String uid;
  final String email;
  final String username;
  @JsonKey(name: 'photoUrl')
  final String? photoUrl;
  @JsonKey(
    name: 'lastActivity',
    fromJson: _lastActivityFromJson,
    toJson: _lastActivityToJson,
  )
  final int? lastActivity; // Stored internally as milliseconds timestamp
  @JsonKey(defaultValue: 'free')
  final String tier;
  final Map<String, FolderModel>? folders;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.lastActivity,
    this.tier = 'free',
    this.folders,
  });

  /// Convert to domain entity
  User toEntity() {
    return User(
      uid: uid,
      email: email,
      username: username,
      photoUrl: photoUrl,
      lastActivity: lastActivity != null
          ? DateTime.fromMillisecondsSinceEpoch(lastActivity!)
          : null,
      tier: tier,
    );
  }

  /// Create from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      username: user.username,
      photoUrl: user.photoUrl,
      lastActivity: user.lastActivity?.millisecondsSinceEpoch,
      tier: user.tier,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoUrl,
    int? lastActivity,
    String? tier,
    Map<String, FolderModel>? folders,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      lastActivity: lastActivity ?? this.lastActivity,
      tier: tier ?? this.tier,
      folders: folders ?? this.folders,
    );
  }
}
