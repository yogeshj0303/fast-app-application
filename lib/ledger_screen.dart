import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Models/refer_model.dart';
import 'services/api_services.dart';
import 'Models/withdrawal_model.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Referral> _referrals = [];
  List<Withdrawal> _withdrawals = [];
  bool _isLoadingReferrals = true;
  bool _isLoadingWithdrawals = true;
  String? _errorMessageReferrals;
  String? _errorMessageWithdrawals;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchReferrals(); // Fetch referrals when the screen loads
    _fetchWithdrawals(); // Fetch withdrawals when the screen loads
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch referral data
  void _fetchReferrals() async {
    setState(() {
      _isLoadingReferrals = true;
      _errorMessageReferrals = null; // Reset error message
    });

    try {
      final referralResponse = await ApiService().fetchReferrals();
      if (referralResponse != null && referralResponse.referrals.isNotEmpty) {
        setState(() {
          _referrals = referralResponse.referrals;
          _isLoadingReferrals = false;
        });
      } else {
        setState(() {
          _errorMessageReferrals = 'No referrals found';
          _isLoadingReferrals = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessageReferrals = 'Failed to load referrals: $e';
        _isLoadingReferrals = false;
      });
    }
  }

  // Fetch withdrawal data
  void _fetchWithdrawals() async {
    setState(() {
      _isLoadingWithdrawals = true;
      _errorMessageWithdrawals = null; // Reset error message
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('id');

      if (userId != null) {
        final withdrawalResponse = await ApiService().getWithdrawalResponse(userId);

        if (withdrawalResponse != null && withdrawalResponse.data.isNotEmpty) {
          setState(() {
            _withdrawals = withdrawalResponse.data;
            _isLoadingWithdrawals = false;
          });
        } else {
          setState(() {
            _errorMessageWithdrawals = 'No withdrawals found';
            _isLoadingWithdrawals = false;
          });
        }
      } else {
        setState(() {
          _errorMessageWithdrawals = 'User ID not found';
          _isLoadingWithdrawals = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessageWithdrawals = 'Failed to load withdrawals: $e';
        _isLoadingWithdrawals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF126090),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1381FA),
        title: const Text(
          'Earning',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: Colors.white70),
          indicatorPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Successful Referrals'),
            Tab(text: 'Withdrawals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1 - Successful Referrals
          _buildReferralsTab(),

          // Tab 2 - Withdrawals
          _buildWithdrawalsTab(),
        ],
      ),
    );
  }

  // Build content for the "Successful Referrals" tab
  Widget _buildReferralsTab() {
    if (_isLoadingReferrals) {
      return _buildTabContent(
        message: 'Loading Successful Referrals...',
        showLoadingIndicator: true,
      );
    }

    if (_errorMessageReferrals != null) {
      return _buildTabContent(
        message: _errorMessageReferrals!,
        showLoadingIndicator: false,
      );
    }

    if (_referrals.isEmpty) {
      return _buildTabContent(
        message: 'No Successful Referrals Yet!',
        showLoadingIndicator: false,
      );
    }

    return ListView.builder(
      clipBehavior: Clip.none,
      itemCount: _referrals.length,
      itemBuilder: (context, index) {
        final referral = _referrals[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(referral.referredUserName),
            subtitle: Text(
              'Email: ${referral.referredUserEmail}\n'
                  'Mobile: ${referral.referredUserMobile}\n'
                  'Referred At: ${referral.referredAt}',
            ),
            // trailing: IconButton(
            //   icon: const Icon(Icons.share),
            //   onPressed: () => _shareReferral(referral),
            // ),
          ),
        );
      },
    );
  }

  // Build content for the "Withdrawals" tab
  Widget _buildWithdrawalsTab() {
    if (_isLoadingWithdrawals) {
      return _buildTabContent(
        message: 'Loading Withdrawals...',
        showLoadingIndicator: true,
      );
    }

    if (_errorMessageWithdrawals != null) {
      return _buildTabContent(
        message: _errorMessageWithdrawals!,
        showLoadingIndicator: false,
      );
    }

    if (_withdrawals.isEmpty) {
      return _buildTabContent(
        message: 'No Withdrawals Yet!',
        showLoadingIndicator: false,
      );
    }

    return ListView.builder(
      clipBehavior: Clip.none,
      itemCount: _withdrawals.length,
      itemBuilder: (context, index) {
        final withdrawal = _withdrawals[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text('Amount: ${withdrawal.amount}'),
            trailing: Text(
              'Status: ${withdrawal.status}',
              style: TextStyle(
                color: withdrawal.status == 'pending'
                    ? Colors.orange
                    : withdrawal.status == 'approved'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            subtitle: Text(
              'Mobile: ${withdrawal.mobileNo}\n'
                  'UPI ID: ${withdrawal.upiId}\n'
                  'Status: ${withdrawal.status}\n'
                  'Requested At: ${withdrawal.createdAt}',
            ),
          ),
        );
      },
    );
  }

  // // Method to share referral details
  // void _shareReferral(Referral referral) {
  //   String message = 'I referred ${referral.referredUserName}!\n'
  //       'Email: ${referral.referredUserEmail}\n'
  //       'Mobile: ${referral.referredUserMobile}\n'
  //       'Referred at: ${referral.referredAt}';
  //
  //   if (message.isNotEmpty) {
  //     Share.share(message);
  //   } else {
  //     print("Sharing message is empty.");
  //   }
  // }

  // Helper method to build the content for a tab
  Widget _buildTabContent({
    required String message,
    required bool showLoadingIndicator,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showLoadingIndicator)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            else
              const SizedBox.shrink(),

            const SizedBox(height: 20),

            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
