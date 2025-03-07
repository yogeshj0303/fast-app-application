import 'package:fast_money_app/Auth/login_screen.dart';
import 'package:fast_money_app/purchase_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contact_us.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'Razorpay_screen.dart';

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
  String? selectedPlanId; // To store the selected planId
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
        membershipPlans = []; // Clear membership plans if user has subscription
      }
    });

    // Load the relevant data based on _subsId
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
    _loadSubsId(); // Load the subscription ID and related data
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getUserData() async {
    setState(() {
      _isLoading = true; // Show loading spinner when fetching user data
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _userid = prefs.getInt('id')?.toString();
      });
      // Load other user-related data
      _userEmail = prefs.getString('email');
      _walletAmount = prefs.getDouble('wallet_amount') ?? 0.0;
      _userName = prefs.getString('name');
      _userPhone = prefs.getString('mobile');

      // Check if the purchased plan is already in SharedPreferences
      String? savedPlanData = prefs.getString('purchasedPlanData');

      if (_subsId == 0) {
        _fetchMembershipPlans(); // Fetch membership plans if subsId is 0
      } else if (savedPlanData != null) {
        setState(() {
          purchasedPlanData = json.decode(savedPlanData);
          _isLoading = false; // Stop loading if plan data is already available
        });
      } else {
        // If no plan data, proceed to fetch and store it
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
      final response = await http.post(Uri.parse(
          'https://fastapp.co.in/api/purchase-membership?user_id=$_userid&membership_plan_id=$_subsId'));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data != null && !data['error']) {
          // Save the fetched plan data to SharedPreferences for future use
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'purchasedPlanData', json.encode(data['membership_plan']));

          // Save the flag to indicate the data has been fetched
          await prefs.setBool('hasFetchedPlanData', true);

          setState(() {
            purchasedPlanData = data['membership_plan'];
            _isLoading = false; // Stop loading once data is fetched
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

  void _openRazorpayCheckout(String planId) async {
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

      // Validate user data
      if (_userPhone == null || _userEmail == null || _userid == null) {
        throw Exception("Missing user details");
      }

      setState(() {
        selectedPlanId = planId;
        isLoading = false;
      });

      // Navigate to RazorpayScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RazorpayScreen(
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
          // Handle post-payment success actions
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListView(
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, $_userName',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text('Amount in your wallet',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Icon(Icons.account_balance_wallet,
                                color: Colors.black),
                          ],
                        ),
                        Text(
                          '₹ $_walletAmount',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: const AssetImage(
                          'assets/images/fast_money_large.jpg'),
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            _subsId == null
                ? Text("No Plan Found!")
                : _subsId == 1
                    ? Card(
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Purchased Plan: ${purchasedPlanData?['plan_name']}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Amount: ₹${purchasedPlanData?['plan_amount']}",
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Validity: ${purchasedPlanData?['plan_validity']} Days",
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Earn daily: ${purchasedPlanData?['daily_login_earnings']}",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _subsId == 0
                        ? SizedBox(
                            height: 270,
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(10.0),
                                    itemCount: membershipPlans.length,
                                    itemBuilder: (context, index) {
                                      final plan = membershipPlans[index];
                                      return SubscriptionCard(
                                        title: plan['plan_name'],
                                        price: '₹ ${plan['plan_amount']}',
                                        duration:
                                            '${plan['plan_validity']} Days',
                                        description:
                                            'Earn ${plan['daily_login_earnings']} daily login earnings.',
                                        onBuyNow: () {
                                          _openRazorpayCheckout(
                                              plan['id'].toString());
                                        },
                                        isLoading: isLoading,
                                      );
                                    },
                                  ),
                          )
                        : Text("No Plan Found!"),
            _buildInfoCard(
              'Earn rewards with every day login',
              'Your wallet balance increases by +₹1 for every login.',
              'assets/images/get_money.png',
            ),
            _buildInfoCard(
              'What Will I Get?',
              '10% of every referral package',
              'assets/images/get_money.png',
            ),
            _buildInfoCard(
              'How to Refer?',
              'Share your referral code with your friends.',
              'assets/images/referral.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, String assetPath) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Image.asset(assetPath, width: 35, height: 35),
        title: Text(title),
        subtitle: Text(description),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              duration,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                      onPressed: onBuyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Buy Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
