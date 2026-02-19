import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/widget/custom_shimmer_fill_text.dart';
import 'package:shortzz/screen/splash_screen/splash_screen_controller.dart';
import 'package:shortzz/utilities/app_res.dart';
import 'package:shortzz/utilities/text_style_custom.dart';
import 'package:shortzz/utilities/theme_res.dart';
import 'package:shortzz/utilities/color_res.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashScreenController());

    return Scaffold(
      //backgroundColor: Color(0xFFE6ECEF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Optional: Add background blur or color here
          //const ThemeBlurBg(),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/Toptap_logo.png',
                  // ensure this path is correct in pubspec.yaml
                  //'assets/videos/Toptap_logo.png',
                  // 'assets/videos/TopTap.gif',
                  // width: double.infinity,
                  // height: double.infinity,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                CustomShimmerFillText(
                  text: AppRes.appName.toUpperCase(),
                  baseColor: ColorRes.themeGradient1,
                  duration: const Duration(seconds: 7),
                  textStyle:
                      TextStyleCustom.unboundedBlack900(
                    color: ColorRes.themeGradient1,
                    fontSize: 30,
                  ),
                  finalColor: ColorRes.themeGradient2,
                  shimmerColor: ColorRes.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
