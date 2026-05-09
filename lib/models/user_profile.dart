import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    this.name        = '',
    this.bio         = '',
    this.nativeLanguage = 'en',
    this.photoUrl,
  });

  final String  uid;
  final String  name;
  final String  bio;
  final String  nativeLanguage;
  final String? photoUrl;

  UserProfile copyWith({
    String? name,
    String? bio,
    String? nativeLanguage,
    String? photoUrl,
  }) => UserProfile(
    uid:            uid,
    name:           name           ?? this.name,
    bio:            bio            ?? this.bio,
    nativeLanguage: nativeLanguage ?? this.nativeLanguage,
    photoUrl:       photoUrl       ?? this.photoUrl,
  );

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) =>
      UserProfile(
        uid:            uid,
        name:           data['name']           as String? ?? '',
        bio:            data['bio']            as String? ?? '',
        nativeLanguage: data['nativeLanguage'] as String? ?? 'en',
        photoUrl:       data['photoUrl']       as String?,
      );

  Map<String, dynamic> toFirestore() => {
    'name':           name,
    'bio':            bio,
    'nativeLanguage': nativeLanguage,
    if (photoUrl != null) 'photoUrl': photoUrl,
  };
}
