import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseClientProvider.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://jtrhmxmlztuagnlhbgzr.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0cmhteG1senR1YWdubGhiZ3pyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1MDU5ODMsImV4cCI6MjA5MTA4MTk4M30.BE5TE3EM31cjM3JMms788RjHvLCFvwuvx5-45SLwbYw',
    ),
  );

  runApp(const AdminApp());
}
