import 'package:flutter/material.dart';

class RightControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const RightControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: color.withOpacity(0.25),
        highlightColor: color.withOpacity(0.18),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.22),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.2),
            ),
            child:
                Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
