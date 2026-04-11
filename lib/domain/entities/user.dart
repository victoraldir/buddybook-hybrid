// lib/domain/entities/user.dart

import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl;
  final DateTime? lastActivity;
  final String tier; // 'free' or 'paid'

  const User({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.lastActivity,
    this.tier = 'free',
  });

  /// Copy with method for immutability
  User copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoUrl,
    DateTime? lastActivity,
    String? tier,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      lastActivity: lastActivity ?? this.lastActivity,
      tier: tier ?? this.tier,
    );
  }

  @override
  List<Object?> get props => [uid, email, username, photoUrl, lastActivity, tier];
}
