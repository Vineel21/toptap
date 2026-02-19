import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/config/agora_config.dart';
import 'package:shortzz/model/user_model/user_model.dart';
import 'package:shortzz/screen/call_screen/call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String channelId;
  final bool isVideoCall;
  final String? token;
  final User caller;

  const IncomingCallScreen({
    super.key,
    required this.channelId,
    required this.isVideoCall,
    required this.caller,
    this.token,
  });

  @override
  State<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState
    extends State<IncomingCallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildAvatar(),
              const SizedBox(height: 24),
              Text(
                widget.caller.username ??
                    widget.caller.fullname ??
                    'Incoming call',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isVideoCall
                    ? 'Video call'
                    : 'Voice call',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.call_end,
                            size: 24),
                        label: const Text('Decline',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _acceptCall,
                        icon: Icon(
                          widget.isVideoCall
                              ? Icons.videocam
                              : Icons.call,
                          size: 24,
                        ),
                        label: const Text('Accept',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptCall() async {
    final effectiveChannel =
        AgoraConfig.effectiveChannelId(widget.channelId);

    // Navigate to the call screen
    Get.off(() => CallScreen(
          user: widget.caller,
          isVideoCall: widget.isVideoCall,
          channelId: effectiveChannel,
          token: widget.token,
        ));
  }

  Widget _buildAvatar() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: (widget.caller.profilePhoto ?? '').isNotEmpty
            ? Image.network(
                widget.caller.profilePhoto!,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey.shade700,
                child: const Icon(Icons.person,
                    color: Colors.white, size: 72),
              ),
      ),
    );
  }
}
