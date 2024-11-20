import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'constants/supabase_constants.dart';
import 'screens/profile_page.dart';
import 'constants/app_colors.dart';
import 'models/premium_app.dart';
import 'package:intl/intl.dart';
import 'screens/product_detail_screen.dart';
import 'screens/transaction_history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    authFlowType: AuthFlowType.pkce,
  );

  runApp(const MyApp());
}


final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Needed',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const TransactionHistoryScreen(),
    const ProfilePage(),
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Jelajahi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PremiumApp> premiumApps = [];
  bool isLoading = true;
  RealtimeChannel? _premiumAppsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPremiumApps();
    _initializeRealtimeSubscription();
  }

  @override
  void dispose() {
    _premiumAppsSubscription?.unsubscribe();
    super.dispose();
  }

  void _initializeRealtimeSubscription() {
    _premiumAppsSubscription = supabase.channel('public:premium_apps').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'premium_apps',
      ),
      (payload, [ref]) {
        if (!mounted) return;
        _loadPremiumApps();
      },
    );

    _premiumAppsSubscription?.subscribe();
  }

  Future<void> _loadPremiumApps() async {
    try {
      final response = await supabase.from('premium_apps').select().execute();

      if (response.data != null) {
        setState(() {
          premiumApps = (response.data as List)
              .map((item) => PremiumApp.fromJson(item))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildCategoryCard(String title, IconData icon) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 30,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAppCard(PremiumApp app) {
    final formatCurrency = NumberFormat.decimalPattern('id_ID');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          print('App data: ${app.toString()}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(app: app),
            ),
          );
        },
        title: Text(
          app.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(app.provider),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  'Rp ${formatCurrency.format(app.originalPrice)}/bln',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rp ${formatCurrency.format(app.discountPrice)}/bln',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Beli'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari aplikasi premium...',
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.primaryOrange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.primaryOrange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryCard('Produktivitas', Icons.work),
                        _buildCategoryCard('Streaming', Icons.play_circle),
                        _buildCategoryCard('Editing', Icons.edit),
                        _buildCategoryCard('Edukasi', Icons.school),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Promo Spesial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...premiumApps
                      .map((app) => _buildPremiumAppCard(app))
                      .toList(),
                ],
              ),
      ),
    );
  }
}

// Ganti placeholder screens
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Jelajahi Aplikasi Premium'));
  }
}
