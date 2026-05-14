import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/utils/PhoneUtils.dart';

void main() {
  const channel = MethodChannel('com.travelpass.app/phone');
  final List<MethodCall> log = <MethodCall>[];

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'makeCall') {
        if (methodCall.arguments['phoneNumber'] == '911') {
          throw PlatformException(code: 'ERROR', message: 'Fail');
        }
        return null;
      }
      return null;
    });
    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('PhoneUtils sanitizes and invokes platform makeCall',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  await PhoneUtils.makeCall(context, '+94 71-234 5678');
                },
                child: const Text('Call'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(log.length, 1);
    expect(log.first.method, 'makeCall');
    expect(log.first.arguments['phoneNumber'], '+94712345678');
  });

  testWidgets('PhoneUtils shows snackbar if phone number becomes empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  await PhoneUtils.makeCall(context, '   ');
                },
                child: const Text('Call Empty'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('No phone number available.'), findsOneWidget);
    expect(log.length, 0);
  });

  testWidgets('PhoneUtils shows snackbar on PlatformException',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  await PhoneUtils.makeCall(context, '911');
                },
                child: const Text('Call Platform Exception'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Error opening dialer'), findsOneWidget);
  });
}
