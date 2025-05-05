import 'package:fast_money_app/Auth/login_screen.dart';
import 'package:fast_money_app/Subscription.dart';
import 'package:fast_money_app/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'Models/user_details.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  String? _referralCode;
  bool _hasFetchedUserDetails = false;
  int? _userId;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('id');

      if (_userId != null) {
        // Fetch user details from the API
        UserDetailsResponse response =
            await ApiService().getUserDetails(_userId!);
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
      MaterialPageRoute(builder: (context) => SubscriptionScreen(
        
      )),
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

  // Account deletion function
  Future<void> _deleteAccount() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://fastapp.co.in/api/delete-account?delete_account_status=1&user_id=$_userId'),
      );

      final data = json.decode(response.body);

      setState(() {
        _isDeleting = false;
      });

      if (data['error'] == false) {
        // Account deleted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Account deleted successfully')),
        );
        
        // Clear preferences and navigate to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
      } else {
        // Error in deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to delete account')),
        );
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Show confirmation dialog before deleting account
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
          SizedBox(height: 30),
          
          // Account Deletion Section
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 40),
                  ),
                  onPressed: _isDeleting ? null : _showDeleteConfirmation,
                  child: _isDeleting 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
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
