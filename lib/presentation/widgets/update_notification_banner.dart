import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateNotificationBanner extends StatefulWidget {
  const UpdateNotificationBanner({
    super.key,
    required this.publishedVersion,
    this.iosLink,
    this.androidLink,
    this.macLink,
    this.windowsLink,
    required this.onDismiss,
  });

  final String publishedVersion;
  final String? iosLink;
  final String? androidLink;
  final String? macLink;
  final String? windowsLink;
  final VoidCallback onDismiss;

  @override
  State<UpdateNotificationBanner> createState() =>
      _UpdateNotificationBannerState();
}

class _UpdateNotificationBannerState extends State<UpdateNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation after a short delay to allow the widget to build
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.9),
                  Theme.of(context).primaryColor.withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.update, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Update Available!',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A new version (${widget.publishedVersion}) is available for download.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (_getPlatformLink() != null) ...[
                  TextButton(
                    onPressed: () async {
                      String? link = _getPlatformLink();
                      if (link != null && await canLaunchUrl(Uri.parse(link))) {
                        await launchUrl(
                          Uri.parse(link),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Download'),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getPlatformLink() {
    if (Platform.isIOS) {
      return widget.iosLink;
    } else if (Platform.isAndroid) {
      return widget.androidLink;
    } else if (Platform.isMacOS) {
      return widget.macLink;
    } else if (Platform.isWindows) {
      return widget.windowsLink;
    }
    // Fallback to any available link if we can't determine the platform
    return widget.androidLink ?? widget.iosLink ?? widget.macLink ?? widget.windowsLink;
  }
}
