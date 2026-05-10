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

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) =>
      UserProfile(
        uid:            uid,
        name:           data['name']            as String? ?? '',
        bio:            data['bio']             as String? ?? '',
        nativeLanguage: data['native_language'] as String? ?? 'en',
        photoUrl:       data['photo_url']       as String?,
      );

  Map<String, dynamic> toMap() => {
    'name':            name,
    'bio':             bio,
    'native_language': nativeLanguage,
    if (photoUrl != null) 'photo_url': photoUrl,
  };
}
