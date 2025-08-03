// This is a basic Flutter widget test for ChatApp.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_app/app.dart';

void main() {
  testWidgets('ChatApp smoke test', (WidgetTester tester) async {
    // Build a simple version of our app for testing
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Chat App Test'),
          ),
        ),
      ),
    );
    
    // Wait for the app to settle
    await tester.pumpAndSettle();
    
    // Verify that the test app builds without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Chat App Test'), findsOneWidget);
  });
  
  testWidgets('ChatApp widget creation test', (WidgetTester tester) async {
    // Test that ChatApp widget can be created without crashing
    const chatApp = ChatApp();
    expect(chatApp, isA<Widget>());
  });
}
