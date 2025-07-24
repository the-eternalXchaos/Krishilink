class UserModel {
  final String? uid;
  final String fullName;
  final String? email;
  final String? token;
  final String? phoneNumber;
  final String role;
  final String? address;
  final String? gender;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? accessToken;
  final String? refreshToken;
  final String? expiration;
  final bool isActive;
  final String deviceId;

  UserModel({
    required this.uid,
    this.fullName = '',
    this.email,
    this.token,
    this.phoneNumber,
    required this.role,
    this.address,
    this.gender,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
    this.accessToken,
    this.refreshToken,
    this.expiration,
    required this.deviceId,
    this.isActive = false,
  });

  /// Factory to create a user from JSON, handling all fallback keys
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['uid'] ?? json['id'] ?? '').toString(),
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '9800000000',
      role: json['role'] ?? 'buyer',
      address: json['address'] ?? 'N/A',
      gender: json['gender'] ?? 'N/A',
      profileImageUrl:
          json['profile_image_url'] ??
          json['profile_image'] ??
          json['profileImageUrl'],
      token: json['token'],
      deviceId: json['device_id'] ?? json['deviceId'] ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString())
              : null,
      accessToken: json['access_token'] ?? json['accessToken'],
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      expiration: json['expiration'],
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? false,
    );
  }

  /// Convert to JSON - you can choose either snake_case or camelCase for API
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'full_name': fullName,
    'email': email,
    'phone_number': phoneNumber ?? '9800000000',
    'role': role,
    'address': address,
    'gender': gender,
    'profile_image_url': profileImageUrl,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'token': token,
    'device_id': deviceId,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expiration': expiration,
    'is_active': isActive,
  };

  /// Make editable clone
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? token,
    String? phoneNumber,
    String? role,
    String? address,
    String? gender,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    String? accessToken,
    String? refreshToken,
    String? expiration,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      token: token ?? this.token,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiration: expiration ?? this.expiration,
      isActive: isActive ?? this.isActive,
    );
  }
}
