import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rupa_nusa/screens/category_screen.dart';
import 'package:rupa_nusa/screens/detail_screen.dart';
import 'package:rupa_nusa/screens/favorite_screen.dart';
import 'package:rupa_nusa/screens/home_screen.dart';
import 'package:rupa_nusa/screens/profile_screen.dart';
import 'package:rupa_nusa/screens/search_screen.dart';
import 'package:rupa_nusa/screens/setting_screen.dart';
import 'package:rupa_nusa/screens/signup_screen.dart';
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const RupaNusaApp(),
    ),
  );
}

class RupaNusaApp extends StatelessWidget {
  const RupaNusaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'RupaNusa',
          theme: themeProvider.isDarkMode ? ThemeData.dark().copyWith(
            primaryColor: Colors.orange,
            scaffoldBackgroundColor: Colors.grey[900],
            textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
          ) : ThemeData.light().copyWith(
            primaryColor: Colors.orange,
            scaffoldBackgroundColor: Colors.white,
            textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const LandingScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            '/search': (context) => const SearchScreen(),
            '/category': (context) => const CategoryScreen(),
            '/detail': (context) => const DetailScreen(),
            '/favorites': (context) => const FavoritesScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}