import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rupa_nusa/screens/category_screen.dart';
import 'package:rupa_nusa/screens/detail_screen.dart';
import 'package:rupa_nusa/screens/favorite_screen.dart';
import 'package:rupa_nusa/screens/search_screen.dart';
import 'package:rupa_nusa/screens/setting_screen.dart';
import 'package:rupa_nusa/screens/signup_screen.dart';
import 'package:url_strategy/url_strategy.dart'; // Tambahkan package
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  // Menghapus hash (#) dari URL
  setPathUrlStrategy();
  
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
          theme: themeProvider.isDarkMode
              ? ThemeData.dark().copyWith(
                  primaryColor: Colors.orange,
                  scaffoldBackgroundColor: Colors.grey[900],
                  textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
                )
              : ThemeData.light().copyWith(
                  primaryColor: Colors.orange,
                  scaffoldBackgroundColor: Colors.white,
                  textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
                ),
          initialRoute: '/',
          routes: {
            '/': (context) => const LandingScreen(),
            '/main': (context) => const MainScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/search': (context) => const SearchScreen(),
            '/category': (context) => const CategoryScreen(),
            '/detail': (context) => const DetailScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        onTap: _onItemTapped,
      ),
    );
  }
}