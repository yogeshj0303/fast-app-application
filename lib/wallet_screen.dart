import 'package:fast_money_app/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Models/user_details.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _walletAmount = 0.0;
  double _totalWithdrawals = 0.0;
  TextEditingController mobileController = TextEditingController();
  TextEditingController upiController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  final ApiService apiService = ApiService();
  Future<UserDetailsResponse?>? _userDetailsFuture;
  int? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details
  }

  Future<void> _fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('id');
    if (userId != null) {
      UserDetailsResponse userDetails = await apiService.getUserDetails(userId!);
      setState(() {
        _walletAmount = userDetails.userDetails?.walletAmount ?? 0.0; // Update wallet amount
        _totalWithdrawals = userDetails.userDetails?.totalWithdraw ?? 0.0; // Update total withdrawals
      });
    }
  }

  void _withdrawal() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found.')),
      );
      return;
    }

    String mobileNo = mobileController.text;
    String upiId = upiController.text;
    double amount = double.tryParse(amountController.text) ?? 0.0;

    if (mobileNo.isEmpty || upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number and UPI ID cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success = await apiService.withdrawalRequest(
      userId: userId!, mobileNo: mobileNo, upiId: upiId, amount: amount,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      mobileController.clear();
      upiController.clear();
      amountController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit withdrawal request'),
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
        backgroundColor: Color(0xFF1381FA),
        title: const Text(
          'Wallet',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildWalletBalanceCard(), // Load wallet balance without FutureBuilder
            const SizedBox(height: 20),
            _buildUPIWithdrawalCard(), // Always display the UPI withdrawal card
          ],
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceInfo(
                  title: "Total Earnings",
                  amount: "\$ $_walletAmount",
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
                _buildBalanceInfo(
                  title: "Total Withdrawals",
                  amount: "\$ $_totalWithdrawals", // Update to use the loaded value
                  color: Colors.red,
                  icon: Icons.arrow_downward,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 10),
            const Text(
              "Manage your earnings and withdrawals efficiently!",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          amount,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();

  Widget _buildUPIWithdrawalCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      shadowColor: Colors.black38,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "USDT Withdrawal",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: mobileController,
                labelText: 'Enter Mobile Number',
                icon: Icons.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: upiController,
                labelText: 'Enter UPI ID',
                icon: Icons.payment,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your UPI ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: amountController,
                labelText: 'Enter Amount',
                icon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  double? amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Color(0xFF1381FA),
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _withdrawal();
                    }
                  },
                  child: const Text(
                    'USDT Wthdraw Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: validator,
    );
  }
}
