import 'package:flutter/material.dart';

AppBar appBar() {
    return AppBar(
      title: const Text(
        "Agenda't",
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
    );
  }