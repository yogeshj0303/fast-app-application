import 'package:fast_money_app/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Razorpay_screen.dart';

class SubscriptionScreen extends StatefulWidget {

  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<dynamic> membershipPlans = [];
  bool isLoading = true;
  bool hasError = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getUserIdFromPreferences();
  }

  // Fetch user ID from shared preferences
  Future<void> _getUserIdFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId =
          prefs.getInt('id')?.toString(); // Get user_id from SharedPreferences
    });
    if (_userId != null) {
      _fetchMembershipPlans();
    } else {
      setState(() {
        hasError = true; // If user_id is not found, show error
      });
    }
  }

  Future<void> _fetchMembershipPlans() async {
    if (_userId == null) return;

    try {
      final response = await http.get(Uri.parse(
          'https://fastapp.co.in/api/get-membership-plan?user_id=$_userId'));

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

  @override
  void dispose() {
    super.dispose();
  }

  // Razorpay checkout function for Buy Now
  void _onBuyNow(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RazorpayScreen(
          planId: plan['id'].toString(),
          userEmail: 'user@example.com', // Replace with actual user email
          userName: 'User Name', // Replace with actual user name
          userPhone: '1234567890', // Replace with actual user phone
          userId: _userId!,
          plan: plan,
        ),
      ),
    ).then((paymentSuccess) {
      if (paymentSuccess == true) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>MainScreen()));
            }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF126090),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        backgroundColor: Color(0xFF1381FA),
        title: const Text(
          'Membership Plans',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Failed to load plans.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: membershipPlans.length,
                  itemBuilder: (context, index) {
                    final plan = membershipPlans[index];
                    return SubscriptionCard(
                      title: plan['plan_name'],
                      price: '₹ ${plan['plan_amount']}',
                      duration: '${plan['plan_validity']} Days',
                      description:
                          'Earn ${plan['daily_login_earnings']} daily login earnings.',
                      onBuyNow: () => _onBuyNow(plan),
                    );
                  },
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

  const SubscriptionCard({
    required this.title,
    required this.price,
    required this.duration,
    required this.description,
    required this.onBuyNow,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
