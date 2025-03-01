import 'dart:convert';

// Model for the individual withdrawal entry
class Withdrawal {
  final int id;
  final int userId;
  final String mobileNo;
  final String upiId;
  final String amount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Withdrawal({
    required this.id,
    required this.userId,
    required this.mobileNo,
    required this.upiId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a Withdrawal from JSON
  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'],
      userId: json['user_id'],
      mobileNo: json['mobile_no'],
      upiId: json['upi_id'],
      amount: json['amount'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

// Model for the overall response
class WithdrawalResponse {
  final bool error;
  final List<Withdrawal> data;

  WithdrawalResponse({
    required this.error,
    required this.data,
  });

  // Factory method to create a WithdrawalResponse from JSON
  factory WithdrawalResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<Withdrawal> withdrawalData = dataList.map((e) => Withdrawal.fromJson(e)).toList();

    return WithdrawalResponse(
      error: json['error'],
      data: withdrawalData,
    );
  }
}
