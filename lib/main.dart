import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/stock_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/customers_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/profit_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المخزون',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    StockScreen(),
    CustomersScreen(),
    SuppliersScreen(),
    SalesScreen(),
    ProfitScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.cardBackground,
          indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'المخزون'),
            NavigationDestination(icon: Icon(Icons.people_outline), label: 'العملاء'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'الموردون'),
            NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), label: 'المبيعات'),
            NavigationDestination(icon: Icon(Icons.trending_up_outlined), label: 'الأرباح'),
          ],
        ),
      ),
    );
  }
}