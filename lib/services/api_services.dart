import 'dart:convert';
import 'dart:ffi';
import 'package:email_validator/email_validator.dart';
import 'package:fast_money_app/Models/login_user.dart';
import 'package:fast_money_app/Models/user_details.dart';
import 'package:fast_money_app/Models/withdrawal_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Models/refer_model.dart';

class ApiService {
  final String _baseUrl = 'https://fastapp.co.in/api';

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String mobile,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'mobile': mobile,
        'email': email,
        'password': password,
        'referral_code':
            referralCode ?? '', // Use an empty string if referralCode is null
      }),
    );

    // Log the response for debugging purposes
    print('Register Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // Handle specific status codes for better feedback
      if (response.statusCode == 400) {
        throw Exception('Bad Request: Please check your input data.');
      } else if (response.statusCode == 409) {
        throw Exception('Conflict: Email or mobile already in use.');
      } else {
        throw Exception('Failed to register user: ${response.reasonPhrase}');
      }
    }
  }

  Future<LoginResponse?> login(String email_or_mobile, String password) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'email_or_mobile': email_or_mobile,
      'password': password,
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: headers,
        body: body,
      );

      final responseBody = response.body;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Login successful: $responseBody');
        return LoginResponse.fromJson(json.decode(responseBody));
      } else {
        print('Login failed: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }

  // Function to get user details by userId
  Future<UserDetailsResponse> getUserDetails(int userId) async {
    final response = await http.get(Uri.parse(
        'https://fastapp.co.in/api/get-user-details?user_id=$userId'));

    if (response.statusCode == 200) {
      // Parse the response body as JSON and return the parsed object
      return UserDetailsResponse.fromJson(json.decode(response.body));
    } else {
      // Handle errors (could show an error message or handle the error gracefully)
      throw Exception('Failed to load user details');
    }
  }

  Future<ReferralResponse> fetchReferrals() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('id');

      if (userId == null) {
        throw Exception('User ID not found in shared preferences');
      }

      final String url = 'https://fastapp.co.in/api/user/$userId/referrals';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Decode the JSON response into ReferralResponse object
        return ReferralResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load referrals');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }

  Future<bool> withdrawalRequest({
    required int userId,
    required String mobileNo,
    required String upiId,
    required double amount,
  }) async {
    try {
      // Construct the URI with query parameters
      final Uri uri = Uri.parse('https://fastapp.co.in/api/add-withdraw')
          .replace(queryParameters: {
        'user_id': userId.toString(),
        'mobile_no': mobileNo,
        'upi_id': upiId,
        'amount': amount.toString(),
      });

      final response = await http.post(uri);

      // Check if the response is successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      return false;
    }
  }

  Future<WithdrawalResponse?> getWithdrawalResponse(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('https://fastapp.co.in/api/get-withdraw?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        return WithdrawalResponse.fromJson(json.decode(response.body));
      } else {
        print('Failed to load withdrawal data: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }
}
