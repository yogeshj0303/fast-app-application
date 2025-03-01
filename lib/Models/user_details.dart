class UserDetailsResponse {
  bool error;
  String message;
  UserDetails? userDetails; // Made userDetails nullable

  UserDetailsResponse({
    required this.error,
    required this.message,
    this.userDetails, // userDetails is now nullable
  });

  factory UserDetailsResponse.fromJson(Map<String, dynamic> json) {
    return UserDetailsResponse(
      error: json['error'],
      message: json['message'],
      userDetails: json['userDetails'] != null
          ? UserDetails.fromJson(json['userDetails'])
          : null, // Handle null for userDetails
    );
  }
}

class UserDetails {
  int id;
  String lastLoginDate;
  String purchasedReferralCode;
  double walletAmount;
  double totalWithdraw; // Added totalWithdraw to match the response
  String name;
  String mobileNo;
  String email;
  dynamic emailVerifiedAt; // Can be null
  dynamic referralCode; // Can be null
  int? subsId;
  String expiryDate; // Added expiryDate
  String createdAt;
  String updatedAt;
  String planName;
  double planAmount;
  int planValidity;
  double referredUserEarn; // Fixed spelling from "reffered_user_earn" to "referred_user_earn"
  double dailyLoginEarnings; // Adjusted type to double
  String planDetails;

  UserDetails({
    this.id = 0,
    this.lastLoginDate = '',
    this.purchasedReferralCode = '',
    this.walletAmount = 0.0,
    this.totalWithdraw = 0.0, // Default value for totalWithdraw
    this.name = '',
    this.mobileNo = '',
    this.email = '',
    this.emailVerifiedAt,
    this.referralCode,
    this.subsId,
    this.expiryDate = '', // Default value for expiryDate
    this.createdAt = '',
    this.updatedAt = '',
    this.planName = '',
    this.planAmount = 0.0,
    this.planValidity = 0,
    this.referredUserEarn = 0.0,
    this.dailyLoginEarnings = 0.0,
    this.planDetails = '',
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'] ?? 0,
      lastLoginDate: json['last_login_date'] ?? '',
      purchasedReferralCode: json['purchased_referral_code'] ?? '',
      walletAmount: double.tryParse(json['wallet_amount']?.toString() ?? '0.0') ?? 0.0,
      totalWithdraw: double.tryParse(json['total_withdraw']?.toString() ?? '0.0') ?? 0.0, // Added totalWithdraw
      name: json['name'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      referralCode: json['referral_code'],
      subsId: json['subs_id'],
      expiryDate: json['expiry_date'] ?? '', // Added expiryDate
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      planName: json['plan_name'] ?? '',
      planAmount: double.tryParse(json['plan_amount']?.toString() ?? '0.0') ?? 0.0,
      planValidity: json['plan_validity'] ?? 0,
      referredUserEarn: double.tryParse(json['reffered_user_earn']?.toString() ?? '0.0') ?? 0.0, // Fixed spelling
      dailyLoginEarnings: double.tryParse(json['daily_login_earnings']?.toString() ?? '0.0') ?? 0.0,
      planDetails: json['plan_details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = this.id;
    data['last_login_date'] = this.lastLoginDate;
    data['purchased_referral_code'] = this.purchasedReferralCode;
    data['wallet_amount'] = this.walletAmount;
    data['total_withdraw'] = this.totalWithdraw; // Include totalWithdraw in toJson
    data['name'] = this.name;
    data['mobile_no'] = this.mobileNo;
    data['email'] = this.email;
    data['email_verified_at'] = this.emailVerifiedAt;
    data['referral_code'] = this.referralCode;
    data['subs_id'] = this.subsId;
    data['expiry_date'] = this.expiryDate; // Include expiryDate in toJson
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['plan_name'] = this.planName;
    data['plan_amount'] = this.planAmount;
    data['plan_validity'] = this.planValidity;
    data['reffered_user_earn'] = this.referredUserEarn; // Fixed spelling
    data['daily_login_earnings'] = this.dailyLoginEarnings;
    data['plan_details'] = this.planDetails;
    return data;
  }
}
