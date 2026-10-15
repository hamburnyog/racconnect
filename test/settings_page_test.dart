// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racconnect/presentation/pages/settings_page.dart';
import 'package:racconnect/utility/pocketbase_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesAsync();
    await prefs.remove(PocketBaseClient.customUrlKey);
    await PocketBaseClient.resetToDefault();
  });

  testWidgets('SettingsPage renders with Backend Server and Email & SMTP tabs', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Tabs
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Backend Server'), findsOneWidget);
    expect(find.text('Email & SMTP'), findsOneWidget);

    // Default tab is Backend Server
    expect(find.text('PocketBase Backend URL'), findsOneWidget);
    expect(find.text('Save & Apply URL'), findsOneWidget);
    expect(find.text('Test Connection'), findsOneWidget);

    // Switch to Email & SMTP tab
    await tester.tap(find.text('Email & SMTP'));
    await tester.pumpAndSettle();

    expect(find.text('SMTP Credentials & Security'), findsOneWidget);
    expect(find.text('Google App Password'), findsOneWidget);
    expect(find.text('Test SMTP Connection'), findsOneWidget);
  });

  testWidgets('SettingsPage allows updating and resetting PocketBase URL', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Enter a local PocketBase IP
    final urlField = find.byType(TextFormField).first;
    await tester.enterText(urlField, 'http://192.168.1.50:8090');
    await tester.pump();

    // Click Save & Apply URL
    await tester.tap(find.text('Save & Apply URL'));
    await tester.pumpAndSettle();

    // Verify PocketBaseClient URL updated
    expect(PocketBaseClient.instance.baseURL, 'http://192.168.1.50:8090');
    expect(find.text('Active: Custom Server URL'), findsOneWidget);

    // Click Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Verify reset to default
    expect(find.text('Active: Default Environment URL'), findsOneWidget);
  });
}
