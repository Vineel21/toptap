import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterController extends BaseController {
  void openGettingStarted() {
    _showHelpDialog('Getting Started',
        'Welcome to TapTop! Here you can learn how to create your first video, set up your profile, and discover amazing content from other creators.');
  }

  void openAccountHelp() {
    _showHelpDialog('Account & Profile',
        'Learn how to manage your account settings, edit your profile, verify your account, and control your privacy settings.');
  }

  void openContentHelp() {
    _showHelpDialog('Creating Content',
        'Tips and tricks for creating engaging videos, using filters and effects, adding music, and optimizing your content for discovery.');
  }

  void openPrivacyHelp() {
    _showHelpDialog('Privacy & Safety',
        'Understand your privacy options, how to block and report users, and keep your account safe and secure.');
  }

  void openEarningsHelp() {
    _showHelpDialog('Earnings & Payments',
        'Learn about monetization options, gift system, withdrawal process, and payment methods.');
  }

  void openLiveStreamHelp() {
    _showHelpDialog('Live Streaming',
        'How to start a live stream, interact with your audience, manage live goals, and streaming best practices.');
  }

  void openCommentsHelp() {
    _showHelpDialog('Comments & Chat',
        'Managing comments on your videos, chat features during live streams, and moderation tools.');
  }

  void openFollowHelp() {
    _showHelpDialog('Following & Followers',
        'Understanding the follower system, managing your following list, and growing your audience.');
  }

  void openHashtagHelp() {
    _showHelpDialog('Hashtags & Discovery',
        'How to use hashtags effectively, get discovered by new viewers, and explore trending content.');
  }

  void openConnectionHelp() {
    _showHelpDialog('Connection Issues',
        'Troubleshooting network problems, improving video quality, and resolving streaming issues.');
  }

  void openUploadHelp() {
    _showHelpDialog('Video Upload Problems',
        'Solutions for upload failures, video format issues, and compression problems.');
  }

  void openNotificationHelp() {
    _showHelpDialog('Notification Issues',
        'How to enable notifications, troubleshoot notification problems, and manage notification preferences.');
  }

  void openAudioHelp() {
    _showHelpDialog('Audio Problems',
        'Fixing audio sync issues, microphone problems, and sound quality improvements.');
  }

  void openLiveChat() {
    Get.snackbar(
      'Live Chat',
      'Connecting you to our support team...',
      snackPosition: SnackPosition.BOTTOM,
    );
    // In a real app, this would open a chat interface
  }

  void sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@TapTop.com',
      query:
          'subject=Support Request&body=Please describe your issue:',
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open email client. Please email us at support@TapTop.com',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void callSupport() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+1-800-TAPTOP',
    );

    try {
      await launchUrl(phoneLaunchUri);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open phone dialer. Please call us at +1-800-TAPTOP',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void openForum() {
    _launchURL('https://community.TapTop.com');
  }

  void openFAQ() {
    _launchURL('https://TapTop.com/faq');
  }

  void openTutorials() {
    _launchURL('https://TapTop.com/tutorials');
  }

  void _showHelpDialog(String title, String content) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              sendEmail();
            },
            child: Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri,
          mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open URL: $url',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
