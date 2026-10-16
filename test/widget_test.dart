import 'package:camera/camera.dart';
import 'package:first_flutter_project/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    const fakeCamera = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );
    await tester.pumpWidget(const MyApp(camera: fakeCamera));
    expect(find.text('Open Camera with Location'), findsOneWidget);
  });
}