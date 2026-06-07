import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/profile_screen.dart';

const supabaseUrl = 'https://ljanqxxpakyndysibzok.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqYW5xeHhwYWt5bmR5c2liem9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzNDk1MzQsImV4cCI6MjA5NTkyNTUzNH0.cJcOmnwGn2BtBazbeaCXJeU5-Y0R7war-tHbW6slcNc';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ReadingLogApp());
}

final supabase = Supabase.instance.client;
final routeObserver = RouteObserver<ModalRoute<void>>();

class ReadingLogApp extends StatelessWidget {
  const ReadingLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession = supabase.auth.currentSession != null;
    return MaterialApp(
      title: 'ReadingLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorObservers: [routeObserver],
      initialRoute: hasSession ? '/home' : '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/home': (_) => const MainScaffold(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/book-detail') {
          final book = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (_) => BookDetailScreen(book: book));
        }
        return null;
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with RouteAware {
  int _currentIndex = 0;
  final _libraryKey = GlobalKey<LibraryScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const SearchScreen(),
      LibraryScreen(key: _libraryKey),
      const TimerScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_currentIndex == 2) _libraryKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.navBg,
        border: Border(top: BorderSide(color: Color(0xFFE8E4DF), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2 && _currentIndex != 2) {
            _libraryKey.currentState?.refresh();
          }
          setState(() => _currentIndex = i);
        },
        items: List.generate(5, (i) => _navItem(_icons[i], i)),
      ),
    );
  }

  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.search,
    Icons.library_books_outlined,
    Icons.av_timer,
    Icons.person_outline,
  ];

  BottomNavigationBarItem _navItem(IconData icon, int index) {
    final selected = _currentIndex == index;
    return BottomNavigationBarItem(
      label: '',
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? AppTheme.navIndicator : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}
