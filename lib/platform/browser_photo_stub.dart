import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class BrowserPhoto {
  final Uint8List bytes;
  final String fileName;

  const BrowserPhoto({required this.bytes, required this.fileName});
}

class BrowserLocation {
  final double latitude;
  final double longitude;

  const BrowserLocation(this.latitude, this.longitude);
}

class BrowserCameraController {
  Widget get preview => const SizedBox.shrink();
  Future<void> initialize() async {}
  Future<BrowserPhoto> capture() async =>
      throw UnsupportedError('Browser camera unavailable');
  Future<BrowserLocation?> getLocation() async => null;
  void dispose() {}
}
