import 'package:fast_money_app/Auth/login_screen.dart';
import 'package:fast_money_app/purchase_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contact_us.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'nowpayments_screen.dart';
import 'services/nowpayments_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _walletAmount = 0.0;
  bool _isLoading = true;
  bool hasError = false;
  bool isLoading = false;
  String? _userEmail;
  String? _userName;
  String? _userid;
  String? _userPhone;
  int? _subsId;
  List<dynamic> membershipPlans = [];
  String? selectedPlanId;
  Map<String, dynamic>? purchasedPlanData;
  bool hasFetchedPlanData = false;

  _loadSubsId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? subsId = prefs.getInt("subs_id");
    bool fetchedPlanData = prefs.getBool('hasFetchedPlanData') ?? false;
    
    setState(() {
      _subsId = subsId;
      hasFetchedPlanData = fetchedPlanData;
      if (subsId == 1) {
        membershipPlans = [];
      }
    });

    if (subsId == 0) {
      await _fetchMembershipPlans();
    } else if (!fetchedPlanData || subsId == 1) {
      await _fetchPurchasedPlanData();
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadSubsId();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _userid = prefs.getInt('id')?.toString();
      });
      _userEmail = prefs.getString('email');
      _walletAmount = prefs.getDouble('wallet_amount') ?? 0.0;
      _userName = prefs.getString('name');
      _userPhone = prefs.getString('mobile');

      String? savedPlanData = prefs.getString('purchasedPlanData');

      if (_subsId == 0) {
        _fetchMembershipPlans();
      } else if (savedPlanData != null) {
        setState(() {
          purchasedPlanData = json.decode(savedPlanData);
          _isLoading = false;
        });
      } else {
        await _fetchPurchasedPlanData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        hasError = true;
      });
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchPurchasedPlanData() async {
    setState(() {
      _isLoading = true;
      hasError = false;
      purchasedPlanData = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? paymentId = prefs.getString('payment_id');
      
      // Get payment status from NOWPayments API
      final nowPaymentsService = NowPaymentsService();
      final paymentStatus = await nowPaymentsService.getPaymentStatus(paymentId!);

      final response = await http.post(
        Uri.parse('https://fastapp.co.in/api/purchase-membership?user_id=$_userid&membership_plan_id=$_subsId'),
        body: {
          'payment_id': paymentStatus['payment_id'].toString(),
          'payment_status': paymentStatus['payment_status'],
          'pay_address': paymentStatus['pay_address'],
          'price_amount': paymentStatus['price_amount'].toString(),
          'pay_currency': paymentStatus['pay_currency'],
          'order_id': paymentStatus['order_id'],
          'order_description': paymentStatus['order_description'],
          'purchase_id': paymentStatus['purchase_id'].toString(),
          'payin_hash': paymentStatus['payin_hash']?.toString() ?? '',
          'created_at': paymentStatus['created_at'],
          'updated_at': paymentStatus['updated_at'],
          'type': paymentStatus['type'],
          'payment_provider': 'nowpayments',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data != null && !data['error']) {
          await prefs.setString('purchasedPlanData', json.encode(data['membership_plan']));
          await prefs.setBool('hasFetchedPlanData', true);

          setState(() {
            purchasedPlanData = data['membership_plan'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            hasError = true;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        hasError = true;
      });
      print('Error fetching purchased plan data: $e');
    }
  }

  Future<void> _fetchMembershipPlans() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://fastapp.co.in/api/get-membership-plan?user_id=$_userid'));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (!data['error']) {
          setState(() {
            membershipPlans = data['membership_plans'];
            isLoading = false;
          });
        } else {
          setState(() => hasError = true);
        }
      } else {
        setState(() => hasError = true);
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _openNowPaymentsCheckout(String planId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final plan = membershipPlans.firstWhere(
        (plan) => plan['id'].toString() == planId,
        orElse: () => null,
      );

      if (plan == null) {
        throw Exception("Selected plan not found");
      }

      if (_userPhone == null || _userEmail == null || _userid == null) {
        throw Exception("Missing user details");
      }

      setState(() {
        selectedPlanId = planId;
        isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NowPaymentsScreen(
            planId: planId,
            userEmail: _userEmail!,
            userName: _userName!,
            userPhone: _userPhone!,
            userId: _userid!,
            plan: plan,
          ),
        ),
      ).then((paymentSuccess) {
        if (paymentSuccess == true) {
          setState(() {
            _subsId = 1;
            membershipPlans = [];
            purchasedPlanData = plan;
            hasFetchedPlanData = true;
          });
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF126090),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsScreen()),
                );
              },
              icon: Image.asset('assets/images/customer-service.png',
                  width: 30, height: 30)),
          IconButton(
            onPressed: () {
              _showLogoutConfirmation(context);
            },
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
        ],
        backgroundColor: Color(0xFF1381FA),
        title: const Text(
          'Refer & Earn',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ListView(
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $_userName',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Amount in your wallet',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.account_balance_wallet, color: Colors.blue, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$$_walletAmount',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: const AssetImage('assets/images/fast_money_large.jpg'),
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _subsId == null
                ? Center(child: Text("No Plan Found!", style: TextStyle(fontSize: 16, color: Colors.white)))
                : _subsId == 1
                    ? Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Purchased Plan: ${purchasedPlanData?['plan_name']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPlanDetailRow("Amount", "\$${purchasedPlanData?['plan_amount']}"),
                              const SizedBox(height: 6),
                              _buildPlanDetailRow("Validity", "${purchasedPlanData?['plan_validity']} Days"),
                              const SizedBox(height: 6),
                              _buildPlanDetailRow("Earn daily", "\$${purchasedPlanData?['daily_login_earnings']}"),
                            ],
                          ),
                        ),
                      )
                    : _subsId == 0
                        ? SizedBox(
                            height: 260,
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    clipBehavior: Clip.none,
                                    physics: const BouncingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    itemCount: membershipPlans.length,
                                    itemBuilder: (context, index) {
                                      final plan = membershipPlans[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: SubscriptionCard(
                                          title: plan['plan_name'],
                                          price: '${plan['plan_amount']}\$',
                                          duration: '${plan['plan_validity']} Days',
                                          description: 'Daily ${plan['daily_login_earnings']}\$ USDT',
                                          onBuyNow: () {
                                            _openNowPaymentsCheckout(plan['id'].toString());
                                          },
                                          isLoading: isLoading,
                                        ),
                                      );
                                    },
                                  ),
                          )
                        : Center(child: Text("No Plan Found!", style: TextStyle(fontSize: 16, color: Colors.white))),
            const SizedBox(height: 8),
            _buildInfoCard(
              'Earn rewards with every day login',
              'Your wallet balance increases by +1 FAP Token for every login.',
              'assets/images/get_money.png',
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              'What Will I Get?',
              '10% of every referral package',
              'assets/images/get_money.png',
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              'How to Refer?',
              'Share your referral code with your friends.',
              'assets/images/referral.png',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String description, String assetPath) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(assetPath, width: 30, height: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String duration;
  final String description;
  final VoidCallback onBuyNow;
  final bool isLoading;

  const SubscriptionCard({
    required this.title,
    required this.price,
    required this.duration,
    required this.description,
    required this.onBuyNow,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.blue)
                  : ElevatedButton(
                      onPressed: onBuyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Buy Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

