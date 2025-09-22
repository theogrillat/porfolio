import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/firebase_options.dart';
import 'package:portfolio/views/home/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');
    print('isRunningWithWasm: $isRunningWithWasm');
    return MaterialApp(
      title: 'Théo Grillat',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: HomeView(isUsingWasm: isRunningWithWasm),
    );
  }
}
