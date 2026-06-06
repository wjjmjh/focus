import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'models/task_model.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialise Hive
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // initialise notifications (includes timezone setup)
  await NotificationService.init();

  if (!Hive.isAdapterRegistered(TaskAdapter().typeId)) {
    Hive.registerAdapter(TaskAdapter());
  }

  await Hive.openBox<Task>('tasks');

  runApp(const ProviderScope(child: FocusApp()));
}

class FocusApp extends StatelessWidget {
  const FocusApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'focus',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.grey,
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.black,
          secondary: Colors.white,
          surface: Colors.black,
          background: Colors.black,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Colors.grey,
          selectionHandleColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
