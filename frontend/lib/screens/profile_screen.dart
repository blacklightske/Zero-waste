import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/django_auth_service.dart';
import '../services/django_data_service.dart';
import '../services/notification_service.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      final notificationService = NotificationService();
      final hasPermission = await NotificationService.areNotificationsEnabled();
      
      if (mounted) {
        setState(() {
          _notificationsEnabled = hasPermission;
        });
      }
    } catch (e) {
      // Handle error gracefully
      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header
            _buildProfileHeader(),
            
            const SizedBox(height: 24),
            
            // App Statistics
            _buildStatisticsSection(),
            
            const SizedBox(height: 24),
            
            // Settings Section
            _buildSettingsSection(),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildAboutSection(),
            
            const SizedBox(height: 24),
            
            // Account Actions
            _buildAccountActions(),
            
            const SizedBox(height: 32),
            
            // SDG Footer
            _buildSDGFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Consumer<DjangoAuthService>(
      builder: (context, authService, child) {
        final user = authService.user;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authService.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authService.userEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ZeroWaste Champion',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatisticsSection() {
    return Consumer<DjangoDataService>(
      builder: (context, dataService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Impact',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.kitchen,
                    title: 'Food Items',
                    value: '${dataService.foodItems.length}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.restaurant_menu,
                    title: 'Saved Recipes',
                    value: '${dataService.allRecipes.length}',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.assignment_turned_in,
                    title: 'Completed Tasks',
                    value: '${dataService.todos.where((todo) => todo.isCompleted).length}',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.eco,
                    title: 'Waste Prevented',
                    value: '${dataService.foodItems.where((item) => item.isExpired).length}',
                    color: Colors.orange,
                    subtitle: 'items saved',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Food expiry and daily reminders',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.refresh,
                title: 'Sync Data',
                subtitle: 'Refresh your data from cloud',
                trailing: const Icon(Icons.chevron_right),
                onTap: _syncData,
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.storage,
                title: 'Clear Cache',
                subtitle: 'Free up local storage space',
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearCache,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
  
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: 'ZeroWaste Lite v1.0.0',
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAppInfo,
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'Get help using the app',
                trailing: const Icon(Icons.chevron_right),
                onTap: _showHelp,
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'How we protect your data',
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPrivacyPolicy,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSDGFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco,
            size: 48,
            color: Colors.green[700],
          ),
          const SizedBox(height: 12),
          Text(
            'Built for SDG 12',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Responsible Consumption and Production',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.green[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Together, we can reduce food waste and create a more sustainable future. Every meal saved makes a difference!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final notificationService = NotificationService();
      
      if (value) {
        await notificationService.requestPermissions();
        final hasPermission = await notificationService.hasNotificationPermission();
        setState(() {
          _notificationsEnabled = hasPermission;
        });
        
        if (hasPermission && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications enabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await NotificationService.cancelAllNotifications();
        setState(() {
          _notificationsEnabled = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _syncData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataService = Provider.of<DjangoDataService>(context, listen: false);
      await dataService.loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all locally stored data. Your cloud data will remain safe. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ZeroWaste Lite'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A Flutter app designed to help reduce household food waste and promote responsible consumption.'),
            SizedBox(height: 12),
            Text('Features:'),
            Text('• Food inventory tracking'),
            Text('• AI-powered recipe suggestions'),
            Text('• Custom recipe management'),
            Text('• Task planning'),
            Text('• Expiry notifications'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Getting Started:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('1. Add food items to your pantry'),
            Text('2. Set expiry dates to get notifications'),
            Text('3. Generate recipes with AI'),
            Text('4. Save your favorite recipes'),
            Text('5. Create tasks for meal planning'),
            SizedBox(height: 12),
            Text('Need more help?'),
            Text('Contact us at: support@zerowastelite.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Collection:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('We collect only the data necessary to provide our services:'),
              Text('• Food items and expiry dates'),
              Text('• Saved and custom recipes'),
              Text('• Task lists'),
              SizedBox(height: 12),
              Text('Data Storage:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Your data is securely stored on our Django backend server and is only accessible by you.'),
              SizedBox(height: 12),
              Text('Data Sharing:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('We do not share your personal data with third parties.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final authService = Provider.of<DjangoAuthService>(context, listen: false);
        await authService.signOut();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}