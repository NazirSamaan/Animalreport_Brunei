import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/widgets.dart';

import 'browser_photo_stub.dart' show BrowserLocation, BrowserPhoto;

int _nextCameraViewId = 0;

class BrowserCameraController {
  late final String _viewType;
  late final html.VideoElement _video;
  html.MediaStream? _stream;

  BrowserCameraController() {
    _viewType = 'wildlife-live-camera-${_nextCameraViewId++}';
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = '#101714';
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _video,
    );
  }

  Widget get preview => HtmlElementView(viewType: _viewType);

  Future<void> initialize() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw StateError('This browser does not support camera access.');
    }
    _stream = await mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': {'ideal': 'environment'},
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });
    _video.srcObject = _stream;
    await _video.play();
  }

  Future<BrowserPhoto> capture() async {
    final width = _video.videoWidth;
    final height = _video.videoHeight;
    if (width <= 0 || height <= 0) {
      throw StateError('The camera is not ready yet.');
    }
    final canvas = html.CanvasElement(width: width, height: height);
    canvas.context2D.drawImage(_video, 0, 0);
    final encoded = canvas.toDataUrl('image/jpeg', 0.92).split(',').last;
    return BrowserPhoto(
      bytes: Uint8List.fromList(base64.decode(encoded)),
      fileName: 'wildlife-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<BrowserLocation?> getLocation() async {
    try {
      final position = await html.window.navigator.geolocation
          .getCurrentPosition(
            enableHighAccuracy: true,
            timeout: const Duration(seconds: 15),
          );
      final latitude = position.coords?.latitude;
      final longitude = position.coords?.longitude;
      if (latitude == null || longitude == null) return null;
      return BrowserLocation(latitude.toDouble(), longitude.toDouble());
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    for (final track in _stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _video.srcObject = null;
  }
}
