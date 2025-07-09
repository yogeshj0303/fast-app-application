import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/nowpayments_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class NowPaymentsScreen extends StatefulWidget {
  final String planId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final String userId;
  final Map<String, dynamic> plan;

  const NowPaymentsScreen({
    Key? key,
    required this.planId,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.userId,
    required this.plan,
  }) : super(key: key);

  @override
  _NowPaymentsScreenState createState() => _NowPaymentsScreenState();
}

class _NowPaymentsScreenState extends State<NowPaymentsScreen> {
  final NowPaymentsService _nowPaymentsService = NowPaymentsService();
  bool isLoading = false;
  String? invoiceUrl;
  String? paymentAmount;
  String? paymentCurrency;
  String? paymentId;
  String? debugMessage;
  double? usdAmount;
  bool isAmountTooLow = false;

  @override
  void initState() {
    super.initState();
    print('NowPaymentsScreen initialized with plan: ${widget.plan}');
    _createInvoice();
  }

  void _showDebugMessage(String message) {
    print('DEBUG: $message');
    setState(() {
      debugMessage = message;
    });
  }

  Future<void> _createInvoice() async {
    try {
      _showDebugMessage('Creating invoice...');
      setState(() {
        isLoading = true;
        isAmountTooLow = false;
      });

      final planAmount = widget.plan['plan_amount'].toString();
      _showDebugMessage('Plan amount: $planAmount');
      
      final response = await _nowPaymentsService.createInvoice(
        priceAmount: double.parse(planAmount),
        priceCurrency: 'USD',
        orderId: 'ORDER_${widget.planId}_${DateTime.now().millisecondsSinceEpoch}',
        orderDescription: '${widget.plan['plan_name']} Subscription',
        ipnCallbackUrl: 'https://fastapp.co.in/api/nowpayments-callback',
        successUrl: 'https://fastapp.co.in/payment-success',
        cancelUrl: 'https://fastapp.co.in/payment-cancel',
        partiallyPaidUrl: 'https://fastapp.co.in/payment-partial',
        isFixedRate: true,
        isFeePaidByUser: false,
      );

      _showDebugMessage('Invoice created successfully: ${response.toString()}');

      // Store payment ID in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('payment_id', response['id'].toString());

      setState(() {
        paymentId = response['id'].toString();
        invoiceUrl = response['invoice_url'];
        paymentAmount = response['price_amount'].toString();
        paymentCurrency = response['price_currency'];
        usdAmount = double.parse(paymentAmount!);
        isLoading = false;
      });

      _showDebugMessage('Payment ID: $paymentId');
      _showDebugMessage('Invoice URL: $invoiceUrl');
      _showDebugMessage('Amount: $paymentAmount $paymentCurrency');

      // Debug the entire response
      _showDebugMessage('Full response: ${json.encode(response)}');
    } catch (e, stackTrace) {
      _showDebugMessage('Error creating invoice: $e\nStack trace: $stackTrace');
      setState(() {
        isLoading = false;
        if (e.toString().contains('Amount too low')) {
          isAmountTooLow = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openPaymentPage() async {
    if (invoiceUrl == null) {
      _showDebugMessage('Cannot open payment page: invoiceUrl is null');
      return;
    }

    try {
      _showDebugMessage('Attempting to open invoice URL...');
      _showDebugMessage('Invoice URL: $invoiceUrl');
      
      final uri = Uri.parse(invoiceUrl!);
      if (await canLaunchUrl(uri)) {
        _showDebugMessage('Launching invoice URL...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showDebugMessage('Invoice URL launched successfully');
      } else {
        _showDebugMessage('Could not launch invoice URL, showing details dialog');
        // Show payment details dialog as fallback
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Payment Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please visit this URL to complete your payment:'),
                SizedBox(height: 8),
                SelectableText(
                  invoiceUrl!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                Text('Amount: $paymentAmount $paymentCurrency'),
                SizedBox(height: 8),
                Text('Payment ID: $paymentId'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      _showDebugMessage('Error while showing payment details: $e\nStack trace: $stackTrace');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Could not open payment page. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (paymentId == null) {
      _showDebugMessage('Cannot check payment status: paymentId is null');
      return;
    }

    try {
      _showDebugMessage('Checking invoice status for ID: $paymentId');
      
      final response = await http.get(
        Uri.parse('https://api.nowpayments.io/v1/invoice/$paymentId'),
        headers: {
          'x-api-key': 'VW82WMY-A1WMPRZ-GZ2QKVC-1C8MPCN',
          'Content-Type': 'application/json',
        },
      );

      _showDebugMessage('Invoice status response: ${response.body}');
      
      final responseData = json.decode(response.body);
      
      if (responseData['status'] == false) {
        throw Exception(responseData['message'] ?? 'Invoice not found');
      }
      
      if (response.statusCode == 200) {
        final status = responseData;
        
        if (status['payment_status'] == 'finished') {
          _showDebugMessage('Payment finished successfully');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Payment Successful'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Status: ${status['payment_status']}'),
                  SizedBox(height: 8),
                  Text('Amount Paid: ${status['actually_paid']} ${status['pay_currency']}'),
                  SizedBox(height: 8),
                  Text('Transaction Hash: ${status['payin_hash']}'),
                  SizedBox(height: 8),
                  Text('Payment Type: ${status['type']}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateSubscription();
                    Navigator.pop(context, true);
                  },
                  child: Text('Continue'),
                ),
              ],
            ),
          );
        } else if (status['payment_status'] == 'failed' || 
                   status['payment_status'] == 'expired') {
          _showDebugMessage('Payment ${status['payment_status']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment ${status['payment_status']}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          _showDebugMessage('Payment status: ${status['payment_status']}');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Payment Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${status['payment_status']}'),
                  SizedBox(height: 8),
                  Text('Pay Address: ${status['pay_address']}'),
                  SizedBox(height: 8),
                  Text('Amount: ${status['price_amount']} ${status['price_currency']}'),
                  SizedBox(height: 8),
                  Text('Created: ${status['created_at']}'),
                  SizedBox(height: 8),
                  Text('Last Updated: ${status['updated_at']}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Failed to get invoice status: ${response.body}');
      }
    } catch (e, stackTrace) {
      _showDebugMessage('Error checking invoice status: $e\nStack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking payment status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateSubscription() async {
    try {
      _showDebugMessage('Updating subscription...');
      final response = await http.post(
        Uri.parse('https://fastapp.co.in/api/purchase-membership'),
        body: {
          'user_id': widget.userId,
          'membership_plan_id': widget.planId,
          'payment_id': paymentId,
          'payment_provider': 'nowpayments',
        },
      );

      _showDebugMessage('Subscription update response: ${response.body}');
      final data = json.decode(response.body);
      
      if (data['error'] == false) {
        _showDebugMessage('Subscription updated successfully');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt("subs_id", 1);
        await prefs.setBool('hasFetchedPlanData', true);
        await prefs.setString('purchasedPlanData', json.encode(data['membership_plan']));
        _showDebugMessage('User preferences updated');
      } else {
        _showDebugMessage('Failed to update subscription: ${data['message']}');
        throw Exception(data['message']?.toString() ?? "Failed to process payment");
      }
    } catch (e, stackTrace) {
      _showDebugMessage('Error updating subscription: $e\nStack trace: $stackTrace');
      throw Exception('Error updating subscription: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Payment'),
        backgroundColor: Color(0xFF1381FA),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (debugMessage != null)
                    Card(
                      color: Colors.grey[200],
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Debug: $debugMessage',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (isAmountTooLow)
                    Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount Too Low',
                              style: TextStyle(
                                color: Colors.red[900],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'The minimum payment amount for crypto payments is \$5 USD (approximately ₹427 INR).',
                              style: TextStyle(
                                color: Colors.red[900],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please choose a higher value plan or use a different payment method.',
                              style: TextStyle(
                                color: Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          if (usdAmount != null)
                            Text(
                              'Amount: \$${usdAmount!.toStringAsFixed(2)} USD',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          SizedBox(height: 16),
                          if (!isAmountTooLow)
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _openPaymentPage,
                                icon: Icon(Icons.payment),
                                label: Text('Open Payment Page'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1381FA),
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (!isAmountTooLow)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instructions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text('1. Click "Open Payment Page" to proceed with payment'),
                            SizedBox(height: 8),
                            Text('2. Choose your preferred cryptocurrency'),
                            SizedBox(height: 8),
                            Text('3. Follow the instructions on the payment page'),
                            SizedBox(height: 8),
                            Text('4. Your subscription will be activated automatically after payment'),
                          ],
                        ),
                      ),
                    ),
                  if (!isAmountTooLow)
                    SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
} 