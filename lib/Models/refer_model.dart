import 'dart:convert';

class Referral {
  final String referredUserName;
  final String referredUserEmail;
  final String referredUserMobile;
  final String referredAt;

  Referral({
    required this.referredUserName,
    required this.referredUserEmail,
    required this.referredUserMobile,
    required this.referredAt,
  });

  // Factory method to create a Referral object from JSON
  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      referredUserName: json['referred_user_name'],
      referredUserEmail: json['referred_user_email'],
      referredUserMobile: json['referred_user_mobile'],
      referredAt: json['referred_at'],
    );
  }

  // Method to convert a Referral object to JSON
  Map<String, dynamic> toJson() {
    return {
      'referred_user_name': referredUserName,
      'referred_user_email': referredUserEmail,
      'referred_user_mobile': referredUserMobile,
      'referred_at': referredAt,
    };
  }
}

class ReferralResponse {
  final bool error;
  final String message;
  final List<Referral> referrals;

  ReferralResponse({
    required this.error,
    required this.message,
    required this.referrals,
  });

  // Factory method to create a ReferralResponse object from JSON
  factory ReferralResponse.fromJson(Map<String, dynamic> json) {
    var referralsJson = json['referrals'] as List;
    List<Referral> referralsList = referralsJson.map((e) => Referral.fromJson(e)).toList();

    return ReferralResponse(
      error: json['error'],
      message: json['message'],
      referrals: referralsList,
    );
  }

  // Method to convert a ReferralResponse object to JSON
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'message': message,
      'referrals': referrals.map((e) => e.toJson()).toList(),
    };
  }
}

