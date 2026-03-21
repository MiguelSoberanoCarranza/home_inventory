import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/app_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/expiry_screen.dart';
import 'screens/shopping_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const HomeInventoryApp(),
    ),
  );
}

class HomeInventoryApp extends StatelessWidget {
  const HomeInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Hogar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFFBC02D),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const InventoryScreen(),
    const ExpiryScreen(),
    const ShoppingListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Inventario'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Caduci.'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Lista'),
        ],
      ),
    );
  }
}
