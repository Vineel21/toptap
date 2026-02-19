import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

Color redColor = const Color.fromRGBO(202, 42, 36, 1);
Color greenColor = const Color.fromRGBO(55, 224, 4, 1);
Color lightRedColor =
    const Color.fromRGBO(202, 42, 36, 1).withOpacity(0.5);
Color lightGreenColor =
    const Color.fromRGBO(55, 224, 4, 1).withOpacity(0.5);

class LoaderWidget extends StatelessWidget {
  final Color? color;

  const LoaderWidget({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/search_animation.json',
        width: 100,
        height: 100,
        repeat: true,
        animate: true,
      ),
    );
  }
}
