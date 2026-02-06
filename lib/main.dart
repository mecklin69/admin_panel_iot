import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'amplifyconfiguration.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Amplify.addPlugins([AmplifyAPI()]);
    await Amplify.configure(amplifyconfig);
    safePrint('Amplify configured');
  } catch (e) {
    safePrint('Amplify error: $e');
  }

  runApp(const AdminPanelApp());
}