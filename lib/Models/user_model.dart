class User {
  final String name;
  final String mobileNo;
  final String email;
  final String? referralCode;
  final double walletAmount;
  final DateTime updatedAt;
  final DateTime createdAt;
  final int id;

  User({
    required this.name,
    required this.mobileNo,
    required this.email,
    this.referralCode,
    required this.walletAmount,
    required this.updatedAt,
    required this.createdAt,
    required this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      mobileNo: json['mobile_no'],
      email: json['email'],
      referralCode: json['referral_code'],
      walletAmount: json['wallet_amount'].toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
      createdAt: DateTime.parse(json['created_at']),
      id: json['id'],
    );
  }
}

class RegisterResponse {
  final bool error;
  final String message;
  final User? user;

  RegisterResponse({
    required this.error,
    required this.message,
    this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      error: json['error'],
      message: json['message'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}
