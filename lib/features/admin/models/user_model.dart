class UserModel {
  final String id;
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
  final String? deviceId;
  final String? accessToken;
  final String? refreshToken;
  final String? expiration;
  final bool isActive;
  final String? globalPlusCode;
  final String? city;
  final String? province;
  final String? country;
  final int reputationCount;
  final int reportCount;
  final bool isBlocked;

  UserModel({
    required this.id,
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
    this.deviceId,
    this.accessToken,
    this.refreshToken,
    this.expiration,
    this.isActive = false,
    this.globalPlusCode,
    this.city,
    this.province,
    this.country,
    this.reputationCount = 0,
    this.reportCount = 0,
    this.isBlocked = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['uid'] ?? '').toString(),
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '9800000000',
      role: json['role'] ?? 'buyer', // Fallback to 'buyer' as in original
      address: json['address'] ?? 'N/A',
      gender: json['gender'] ?? 'N/A',
      profileImageUrl:
          json['profileImageUrl'] ??
          json['profile_image_url'] ??
          json['profile_image'],
      token: json['token'],
      deviceId: json['deviceId'] ?? json['device_id'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString())
              : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
      accessToken: json['accessToken'] ?? json['access_token'],
      refreshToken: json['refreshToken'] ?? json['refresh_token'],
      expiration: json['expiration'],
      isActive:
          json['isActive'] as bool? ?? json['is_active'] as bool? ?? false,
      globalPlusCode: json['globalPlusCode'],
      city: json['city'],
      province: json['province'],
      country: json['country'],
      reputationCount: json['reputationCount'] as int? ?? 0,
      reportCount: json['reportCount'] as int? ?? 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber ?? '9800000000',
    'role': role,
    'address': address,
    'gender': gender,
    'profileImageUrl': profileImageUrl,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'token': token,
    'deviceId': deviceId,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiration': expiration,
    'isActive': isActive,
    'globalPlusCode': globalPlusCode,
    'city': city,
    'province': province,
    'country': country,
    'reputationCount': reputationCount,
    'reportCount': reportCount,
    'isBlocked': isBlocked,
  };

  UserModel copyWith({
    String? id,
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
    String? globalPlusCode,
    String? city,
    String? province,
    String? country,
    int? reputationCount,
    int? reportCount,
    bool? isBlocked,
  }) {
    return UserModel(
      id: id ?? this.id,
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
      globalPlusCode: globalPlusCode ?? this.globalPlusCode,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      reputationCount: reputationCount ?? this.reputationCount,
      reportCount: reportCount ?? this.reportCount,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
