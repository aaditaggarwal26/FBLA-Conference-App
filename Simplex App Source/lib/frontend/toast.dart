import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class Toasts {
  static void toast(String message, bool error) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      backgroundColor: error ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
