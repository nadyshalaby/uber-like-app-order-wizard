import 'package:flutter/material.dart';

/// Get screen sizing in different formats
class Sizing {
  BuildContext context;

  Sizing(this.context);

  ///Calculate width in [percentage] value based on screen width.
  double wp(double percentage) {
    double screenWidth = MediaQuery.of(context).size.width;
    return percentage * screenWidth / 100;
  }

  ///Calculate height in [percentage] value based on screen height.
  double hp(double percentage) {
    double screenHeight = MediaQuery.of(context).size.height;
    return percentage * screenHeight / 100;
  }
}
