import 'package:flutter/material.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> membershipDetails;

  const PurchaseSuccessScreen({required this.membershipDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text('Purchase Successful', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1381FA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Center(
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'You have successfully purchased the plan.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 20),

            // Plan Info Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan: ${membershipDetails['plan_name']}',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '₹ ${membershipDetails['plan_amount']}',
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Validity: ${membershipDetails['plan_validity']} days',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Daily Earnings: ₹ ${membershipDetails['daily_login_earnings']}',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Plan Details: ${membershipDetails['plan_details']}',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Button Section
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to the home screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1381FA),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
