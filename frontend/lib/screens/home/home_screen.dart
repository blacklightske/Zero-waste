import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/django_data_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/notification_service.dart';
import '../../utils/animations.dart';
import '../pantry/pantry_screen.dart';
import '../recipes/my_recipes_screen.dart';
import '../todo_screen.dart';
import '../profile_screen.dart';
import '../marketplace/marketplace_screen.dart';
import 'dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardTab(),
    const PantryScreen(),
    const MarketplaceScreen(),
    const MyRecipesScreen(),
    const TodoScreen(),
    const ProfileScreen(),
  ];
  
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      activeIcon: Icon(Icons.inventory_2),
      label: 'Pantry',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.storefront_outlined),
      activeIcon: Icon(Icons.storefront),
      label: 'Market',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_outlined),
      activeIcon: Icon(Icons.restaurant),
      label: 'Recipes',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.checklist_outlined),
      activeIcon: Icon(Icons.checklist),
      label: 'To-Do',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outlined),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Load user data
    final dataService = Provider.of<DjangoDataService>(context, listen: false);
    await dataService.loadUserData();
    
    // Load marketplace data
    final marketplaceService = Provider.of<MarketplaceService>(context, listen: false);
    await marketplaceService.loadAllData();
    
    // Schedule daily pantry reminder
    await NotificationService.scheduleDailyPantryReminder();
    
    // Update food expiry notifications
    await NotificationService.updateFoodItemNotifications(dataService.foodItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppAnimations.fadeIn(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: AppAnimations.slideInFromBottom(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          items: _navItems,
          elevation: 8,
        ),
      ),
    );
  }
}