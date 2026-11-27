import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'di/app_dependencies.dart';
import 'router/app_routes.dart';

/// Root Keepoo application widget.
class KeepooApp extends StatefulWidget {
  const KeepooApp({
    this.dependencies,
    this.useDevicePreview = true,
    super.key,
  });

  final AppDependencies? dependencies;
  final bool useDevicePreview;

  @override
  State<KeepooApp> createState() => _KeepooAppState();
}

class _KeepooAppState extends State<KeepooApp> {
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ?? AppDependencies.mock();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Keepoo',
      locale: widget.useDevicePreview ? DevicePreview.locale(context) : null,
      builder: widget.useDevicePreview ? DevicePreview.appBuilder : null,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      onGenerateRoute: (settings) =>
          AppRoutes.onGenerateRoute(settings, _dependencies),
    );
  }
}
