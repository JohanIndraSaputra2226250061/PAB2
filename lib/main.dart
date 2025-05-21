import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rupa_nusa/models/user.dart';
import 'package:rupa_nusa/screens/category_screen.dart';
import 'package:rupa_nusa/screens/detail_screen.dart';
import 'package:rupa_nusa/screens/favorite_screen.dart';
import 'package:rupa_nusa/screens/search_screen.dart';
import 'package:rupa_nusa/screens/setting_screen.dart';
import 'package:rupa_nusa/screens/signup_screen.dart';
import 'package:rupa_nusa/screens/edit_profile_screen.dart';
import 'package:rupa_nusa/screens/change_password_screen.dart';
import 'package:rupa_nusa/screens/splash_screen.dart';
import 'package:url_strategy/url_strategy.dart'; 
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_posting_screen.dart'; 
import 'screens/profile_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
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
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/': (context) => const LandingScreen(),
            '/main': (context) => const MainScreen(),
            '/search': (context) => const SearchScreen(),
            '/category': (context) => const CategoryScreen(),
            '/detail': (context) => const DetailScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/home': (context) => const HomeScreen(),
            '/edit-profile': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as AppUser?;
              if (args == null) {
                return Scaffold(
                  body: Center(
                    child: Text('Pengguna tidak ditemukan'),
                  ),
                );
              }
              return EditProfileScreen(appUser: args);
            },
            '/admin-posting': (context) => const AdminPostingScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 0 
                            ? Colors.orange.withOpacity(0.2) 
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.home_outlined,
                        color: _selectedIndex == 0 
                            ? Colors.orange 
                            : isDarkMode ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.orange,
                      ),
                    ),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 1 
                            ? Colors.orange.withOpacity(0.2) 
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        color: _selectedIndex == 1 
                            ? Colors.orange 
                            : isDarkMode ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.orange,
                      ),
                    ),
                    label: 'Favorit',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 2 
                            ? Colors.orange.withOpacity(0.2) 
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: _selectedIndex == 2 
                            ? Colors.orange 
                            : isDarkMode ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.orange,
                      ),
                    ),
                    label: 'Profil',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.orange,
                unselectedItemColor: isDarkMode ? Colors.grey : Colors.grey.shade600,
                backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                elevation: 0,
                onTap: _onItemTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
