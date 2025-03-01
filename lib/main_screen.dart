import 'package:fast_money_app/Refer_screen.dart';
import 'package:fast_money_app/ledger_screen.dart';
import 'package:fast_money_app/wallet_screen.dart';
import 'package:flutter/material.dart';

import 'Home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Updated to have 4 unique screens for the 4 BottomNavigationBar items
  List<Widget> _getChildren() {
    return [
      HomeScreen(),
      LedgerScreen(),
      WalletScreen(),
      ReferScreen(),
      // Placeholder for More Screen (Replace with actual More Screen)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF126090),
      body: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 70.0),
            // Adjust this value as needed
            child: _getChildren()[_currentIndex],
          ),
          Positioned(
            bottom: 8,
            left: 10,
            right: 10,
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index; // Change the current index on tap
                  });
                },
                backgroundColor: Colors.grey[200],
                type: BottomNavigationBarType.fixed,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      'assets/images/home.png',
                      width: 24,
                      height: 24,
                      color: _currentIndex == 0
                          ? Colors.deepPurple[400]
                          : Colors.black,
                    ),
                    label: 'HOME',
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      'assets/images/transaction.png',
                      width: 24,
                      height: 24,
                      color: _currentIndex == 1
                          ? Colors.deepPurple[400]
                          : Colors.black,
                    ),
                    label: 'LEDGER',
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      'assets/images/money.png',
                      width: 24,
                      height: 24,
                      color: _currentIndex == 2
                          ? Colors.deepPurple[400]
                          : Colors.black,
                    ),
                    label: 'WALLET',
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset(
                      'assets/images/sign.png',
                      width: 24,
                      height: 24,
                      color: _currentIndex == 3
                          ? Colors.deepPurple[400]
                          : Colors.black,
                    ),
                    label: 'REFER',
                  ),
                ],
                unselectedLabelStyle: TextStyle(
                    color: Colors.black, fontSize: 12),
                selectedLabelStyle: TextStyle(
                    color: Colors.deepPurple[400], fontSize: 14),
                selectedItemColor: Colors.deepPurple[400],
                unselectedItemColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
