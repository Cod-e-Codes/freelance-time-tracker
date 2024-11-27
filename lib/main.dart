import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/time_log.dart';  // Import TimeLogAdapter
import 'screens/home_screen.dart';
import 'providers/project_provider.dart';
import 'models/project.dart';

void main() async {
  // Initialize Hive and register the adapters for the models
  await Hive.initFlutter();
  Hive.registerAdapter(ProjectAdapter());  // Register Project adapter
  Hive.registerAdapter(TimeLogAdapter());  // Register TimeLog adapter

  // Open the Hive boxes for projects and goals
  await Hive.openBox<Project>('projects');
  await Hive.openBox('goals');  // Assuming this is the global goals box

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Freelance Time Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 14),
          ),
        ),
        darkTheme: ThemeData.dark(),
        home: const HomeScreenWrapper(),
      ),
    );
  }
}

// Wrapper to ensure that projects are loaded before the home screen is displayed
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<ProjectProvider>(context, listen: false).loadProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Error loading projects. Please try again.'),
            ),
          );
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
