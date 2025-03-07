import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RazorpayScreen extends StatefulWidget {
  final String planId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final String userId;
  final Map<String, dynamic> plan;

  const RazorpayScreen({
    Key? key,
    required this.planId,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.userId,
    required this.plan,
  }) : super(key: key);

  @override
  _RazorpayScreenState createState() => _RazorpayScreenState();
}

class _RazorpayScreenState extends State<RazorpayScreen> {
  late Razorpay _razorpay;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _openRazorpayCheckout();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openRazorpayCheckout() {
    var options = {
      'key': 'rzp_test_FzTdXjqOxscHxj',
      'amount': (double.parse(widget.plan['plan_amount'].toString()) * 100).toInt().toString(),
      'name': 'Refer&Earn',
      'description': '${widget.plan['plan_name']} Subscription',
      'prefill': {
        'contact': widget.userPhone,
        'email': widget.userEmail,
        'name': widget.userName,
      },
      'theme': {'color': '#1381FA'},
      'external': {
        'wallets': ['paytm'],
      },
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt("subs_id", 1);
      await prefs.setBool('hasFetchedPlanData', true);

      final apiUrl = 'https://fastapp.co.in/api/purchase-membership';
      final apiResponse = await http.post(
        Uri.parse(apiUrl),
        body: {
          'user_id': widget.userId,
          'membership_plan_id': widget.planId,
          'payment_id': response.paymentId ?? '',
          'order_id': response.orderId ?? '',
          'signature': response.signature ?? '',
        },
      );

      final data = json.decode(apiResponse.body);

      if (data['error'] == false) {
        await prefs.setString('purchasedPlanData', json.encode(data['membership_plan']));
        Navigator.pop(context, true);
      } else {
        throw Exception(data['message']?.toString() ?? "Failed to process payment");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isLoading = false;
    });

    String errorMessage = response.error?['description'] ?? "Payment failed";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet: ${response.walletName}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Razorpay Checkout'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Text('Processing Payment...'),
      ),
    );
  }
} 