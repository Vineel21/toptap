import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/extensions/common_extension.dart';
import 'package:shortzz/common/extensions/string_extension.dart';
import 'package:shortzz/common/manager/haptic_manager.dart';
import 'package:shortzz/common/widget/text_button_custom.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/livestream/livestream.dart';
import 'package:shortzz/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:shortzz/screen/live_stream/livestream_screen/widget/live_goal_progress_widget.dart';
import 'package:shortzz/utilities/asset_res.dart';
import 'package:shortzz/utilities/color_res.dart';
import 'package:shortzz/utilities/text_style_custom.dart';
import 'package:shortzz/utilities/theme_res.dart';

class LiveStreamHostTopView extends StatelessWidget {
  final LivestreamScreenController controller;

  const LiveStreamHostTopView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      minimum: EdgeInsets.only(top: AppBar().preferredSize.height * 0.3),
      child: Obx(() {
        Livestream stream = controller.liveData.value;
        int count = stream.watchingCount ?? 0;
        int watchingCount = count >= 0 ? count : 0;
        bool isVisible = controller.isViewVisible.value;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: isVisible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identity, engagement and stream controls.
                  Row(
                    children: [
                      // User Profile Picture
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child:
                              (controller.myUser.value?.profilePhoto ?? '')
                                  .isNotEmpty
                              ? Image.network(
                                  controller.myUser.value!.profilePhoto!
                                      .addBaseURL(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    controller.myUser.value?.username ?? 'User',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyleCustom.outFitSemiBold600(
                                      color: whitePure(context),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.favorite,
                                  color: ColorRes.likeRed,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  (stream.likeCount ?? 0).numberFormat,
                                  style: TextStyleCustom.outFitRegular400(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: controller.showEditLiveTitleDialog,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      stream.description ?? 'Add LIVE title',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyleCustom.outFitRegular400(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // View Count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AssetRes.icEye_2,
                              height: 16,
                              width: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              watchingCount.numberFormat,
                              style: TextStyleCustom.outFitRegular400(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Start Battle Button (only when users available)
                      if (_shouldShowStartBattleButton())
                        GestureDetector(
                          onTap: () {
                            print('🚀 Start Battle button tapped!'); // Debug
                            controller.startBattle();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColorRes.themeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                      if (_shouldShowStartBattleButton())
                        const SizedBox(width: 8),

                      // Stop Button
                      GestureDetector(
                        onTap: controller.onStopButtonTap,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColorRes.likeRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.power_settings_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  LiveGoalProgressWidget(controller: controller),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  bool _shouldShowStartBattleButton() {
    // Show Start Battle button only when:
    // 1. Battle is not currently running (battle type is INITIATE)
    // 2. Stream type is not already battle
    // 3. There are enough users to start a battle (at least 1 other user besides host)

    Livestream stream = controller.liveData.value;
    return stream.battleType == BattleType.initiate &&
        stream.type != LivestreamType.battle &&
        controller.canStartBattle;
  }
}

class StopLiveStreamSheet extends StatelessWidget {
  final VoidCallback onTap;
  final String? title;
  final String? description;
  final String? positiveText;

  const StopLiveStreamSheet({
    super.key,
    required this.onTap,
    this.title,
    this.description,
    this.positiveText,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          width: double.infinity,
          decoration: ShapeDecoration(
            color: adaptiveBackground(context),
            shape: const SmoothRectangleBorder(
              side: BorderSide(),
              borderRadius: SmoothBorderRadius.vertical(
                top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: .5,
                  color: textLightGrey(context),
                  width: 100,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                title ?? LKey.endStreamTitle.tr,
                style: TextStyleCustom.unboundedRegular400(
                  fontSize: 15,
                  color: adaptiveTextColor(context),
                ),
              ),
              Text(
                description ?? LKey.endStreamMessage.tr,
                style: TextStyleCustom.outFitLight300(
                  fontSize: 17,
                  color: ColorRes.textlightGreenColor,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButtonCustom(
                      onTap: Get.back,
                      title: LKey.cancel.tr,
                      backgroundColor: ColorRes.whitePure,
                    ),
                  ),
                  Expanded(
                    child: TextButtonCustom(
                      onTap: () {
                        Get.back();
                        onTap();
                      },
                      title: positiveText ?? LKey.yes.tr,
                      backgroundColor: themeAccentSolid(context),
                      titleColor: whitePure(context),
                      horizontalMargin: 5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppBar().preferredSize.height),
            ],
          ),
        ),
      ],
    );
  }
}

class LiveStreamBorderButton extends StatelessWidget {
  final Color? backgroundColor;
  final String title;
  final String imageIcon;
  final Color? imageColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const LiveStreamBorderButton({
    super.key,
    this.backgroundColor,
    required this.title,
    this.imageIcon = '',
    this.imageColor,
    this.onTap,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    double width = Get.width / 5.5;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 30,
        width: width,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(cornerRadius: 30),
            side: BorderSide(color: whitePure(context).withValues(alpha: .3)),
          ),
          shadows: shadow,
          color: backgroundColor ?? blackPure(context).withValues(alpha: .1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            if (imageIcon.isNotEmpty)
              Image.asset(imageIcon, height: 16, width: 16, color: imageColor),
            Text(
              title,
              style: TextStyleCustom.outFitRegular400(
                color: whitePure(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveStreamCircleBorderButton extends StatelessWidget {
  final String image;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Size? size;
  final Color? iconColor;
  final Color? borderColor;
  final Color? bgColor;
  final double? iconSize;

  const LiveStreamCircleBorderButton({
    super.key,
    required this.image,
    this.margin,
    this.onTap,
    this.size,
    this.iconColor,
    this.borderColor,
    this.iconSize,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticManager.shared.light();
        onTap?.call();
      },
      child: Container(
        height: size?.height ?? 32,
        width: size?.width ?? 32,
        margin: margin,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(cornerRadius: 30),
            side: BorderSide(
              color: borderColor ?? whitePure(context).withValues(alpha: .3),
            ),
          ),
          color: (bgColor ?? blackPure(context)).withValues(alpha: .1),
        ),
        child: Image.asset(
          image,
          height: iconSize ?? 20,
          width: iconSize ?? 20,
          color: iconColor ?? whitePure(context).withValues(alpha: .3),
        ),
      ),
    );
  }
}

final livestreamShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: .15),
    offset: const Offset(0, 2),
    blurRadius: 5,
  ),
];
