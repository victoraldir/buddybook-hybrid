// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      photoUrl: json['photoUrl'] as String?,
      lastActivity: _lastActivityFromJson(json['lastActivity']),
      tier: json['tier'] as String? ?? 'free',
      folders: (json['folders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, FolderModel.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'username': instance.username,
      'photoUrl': instance.photoUrl,
      'lastActivity': _lastActivityToJson(instance.lastActivity),
      'tier': instance.tier,
      'folders': instance.folders?.map((k, e) => MapEntry(k, e.toJson())),
    };
