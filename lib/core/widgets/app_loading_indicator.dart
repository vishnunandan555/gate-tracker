import 'package:flutter/material.dart';
import '../theme/theme_context_ext.dart';

class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double strokeWidth;
  final double? value;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.strokeWidth = 4.0,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      value: value,
      strokeWidth: strokeWidth,
      color: color ?? context.appColors.primaryAccent,
    );
  }
}

class AppLoadingScreen extends StatelessWidget {
  final Color? color;
  final double strokeWidth;

  const AppLoadingScreen({
    super.key,
    this.color,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      body: Center(
        child: AppLoadingIndicator(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
