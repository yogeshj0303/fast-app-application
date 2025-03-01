import 'package:fast_money_app/Subscription.dart';
import 'package:fast_money_app/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Models/user_details.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  String? _referralCode;
  bool _hasFetchedUserDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('id');

      if (userId != null) {
        // Fetch user details from the API
        UserDetailsResponse response =
            await ApiService().getUserDetails(userId);
        setState(() {
          _hasFetchedUserDetails = true;
          // Check if the subscription ID is 1, and set the referral code accordingly
          if (response.userDetails != null &&
              response.userDetails!.subsId == 1) {
            setState(() {
              _referralCode = response.userDetails!.purchasedReferralCode;
            });
          } else {
            _referralCode = null; // No referral code available
          }
        });
      } else {
        print('User ID not found in shared preferences');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found')),
        );
      }
    } catch (e) {
      print('Failed to fetch user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user details')),
      );
    }
  }

  // Display membership plans when no plan is purchased
  void _showMembershipPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubscriptionScreen()),
    );
  }

  // Share referral code via share_plus
  void _shareReferralCode() {
    if (_referralCode != null) {
      // Share the referral code if it exists
      Share.share(
          'Use my referral code: $_referralCode to join and earn rewards!');
    } else {
      // Show message if referral code is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Referral code is not available yet')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF126090),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF1381FA),
        title: const Text('Refer',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 0),
            child: Image.asset(
              'assets/images/refer_page.png',
              width: 300,
              height: 245,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 15),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  'Get ₹100\nFor every new user you refer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _hasFetchedUserDetails
                    ? (_referralCode != null)
                        ? Text(
                            'Your Referral Code: $_referralCode',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Color(0xFF1381FA),
                                minimumSize: Size(double.infinity, 40),
                              ),
                              onPressed: () => _showMembershipPlans(),
                              child: Text(
                                'Get Referral Code',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          )
                    : CircularProgressIndicator(),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Step 1: Share
                          Expanded(
                            child: _buildStep(
                              icon: Icons.share,
                              title: 'Share',
                              description:
                                  'Share your referral code with friends',
                            ),
                          ),
                          // Step 2: Friend Joins
                          Expanded(
                            child: _buildStep(
                              icon: Icons.person_add,
                              title: 'Friend Joins',
                              description: 'Your friend joins using your code',
                            ),
                          ),
                          // Step 3: Earn Reward
                          Expanded(
                            child: _buildStep(
                              icon: Icons.card_giftcard,
                              title: 'Earn Reward',
                              description: 'You earn a confirmed reward',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          _hasFetchedUserDetails
              ? (_referralCode != null)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Color(0xFF1381FA),
                          minimumSize: Size(double.infinity, 40),
                        ),
                        onPressed:
                            _shareReferralCode, // Share the referral code
                        child: Text('Refer',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Color(0xFF1381FA),
                          minimumSize: Size(double.infinity, 40),
                        ),
                        onPressed: () => _showMembershipPlans(),
                        child: Text(
                          'Refer',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    )
              : Center(child: CircularProgressIndicator()),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20),
          //   child: ElevatedButton(
          //     style: ElevatedButton.styleFrom(
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       backgroundColor: Color(0xFF1381FA),
          //       minimumSize: Size(double.infinity, 40),
          //     ),
          //     onPressed: _showPaymentOptions,
          //     child: Text('Refer',
          //         style: TextStyle(color: Colors.white, fontSize: 16)),
          //   ),
          // ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper method to build the steps with icons and text
  Widget _buildStep(
      {required IconData icon,
      required String title,
      required String description}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurple[600],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
