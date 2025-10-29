import 'package:flutter/material.dart';

/// CustomSnackbar hiển thị thông báo ở góc trên bên phải.
/// Có thể hiển thị các kiểu: success, error, info.
class CustomSnackbar {
  static void show(
      BuildContext context,
      String message, {
        SnackType type = SnackType.error,
        Duration duration = const Duration(seconds: 3),
      }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // Chọn màu và icon tùy theo loại Snack
    final Color backgroundColor;
    final IconData iconData;
    switch (type) {
      case SnackType.success:
        backgroundColor = Colors.greenAccent.shade700;
        iconData = Icons.check_circle_outline;
        break;
      case SnackType.info:
        backgroundColor = Colors.blueAccent;
        iconData = Icons.info_outline;
        break;
      case SnackType.error:
      default:
        backgroundColor = Colors.redAccent;
        iconData = Icons.error_outline;
        break;
    }

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _SnackbarContainer(
            message: message,
            backgroundColor: backgroundColor,
            iconData: iconData,
            duration: duration,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () => overlayEntry.remove());
  }
}

/// Kiểu thông báo (success, error, info)
enum SnackType { success, error, info }

/// Widget hiển thị nội dung Snackbar với animation fade
class _SnackbarContainer extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData iconData;
  final Duration duration;

  const _SnackbarContainer({
    Key? key,
    required this.message,
    required this.backgroundColor,
    required this.iconData,
    required this.duration,
  }) : super(key: key);

  @override
  State<_SnackbarContainer> createState() => _SnackbarContainerState();
}

class _SnackbarContainerState extends State<_SnackbarContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(top: 50),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.iconData, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
