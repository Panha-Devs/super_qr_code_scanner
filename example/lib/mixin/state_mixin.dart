import 'package:flutter/material.dart';

/// Mixin to provide safe setState functionality
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  /// Safely calls setState only if the widget is mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}
