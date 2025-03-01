class LoginResponse {
  final bool error;
  final String message;
  final User user;

  LoginResponse({
    required this.error,
    required this.message,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? 'No message',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class User {
  final String name;
  final String mobileNo;
  final String email;
  final double walletAmount;
  final String purchasedReferralCode;
  final int subsId;
  final int id;

  User({
    required this.name,
    required this.mobileNo,
    required this.email,
    required this.walletAmount,
    required this.purchasedReferralCode,
    required this.id,
    required this.subsId
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      email: json['email'] ?? '',
      walletAmount:
          double.tryParse(json['wallet_amount']?.toString() ?? '') ?? 0.0,
      purchasedReferralCode: json['purchased_referral_code'] ?? '',
      id: json['id'] ?? 0,
      subsId: json['subs_id']??0
    );
  }
}
