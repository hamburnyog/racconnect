import 'package:flutter/material.dart';

class OfflineModeProvider extends InheritedWidget {
  final bool isOfflineMode;

  const OfflineModeProvider({
    super.key,
    required this.isOfflineMode,
    required super.child,
  });

  static OfflineModeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OfflineModeProvider>();
  }

  @override
  bool updateShouldNotify(OfflineModeProvider oldWidget) {
    return oldWidget.isOfflineMode != isOfflineMode;
  }
}