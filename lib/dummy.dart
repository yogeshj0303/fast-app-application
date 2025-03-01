import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class DottedBorderContainer extends StatelessWidget {
  const DottedBorderContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: DottedBorder(
          color: Colors.black, // Border color
          strokeWidth: 2, // Border width
          dashPattern: [6, 3], // Defines the dash pattern [length of dash, space between dashes]
          child: Container(
            height: 100,
            width: 100,
            color: Colors.grey[200], // Background color of the container
            child: Center(child: Text('Dotted Border')),
          ),
        ),
      ),
    );
  }
}