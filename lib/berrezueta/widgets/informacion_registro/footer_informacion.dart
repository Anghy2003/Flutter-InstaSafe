 import 'package:flutter/material.dart';

Widget buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Center(
          child: Text(
            '©IstaSafe',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }