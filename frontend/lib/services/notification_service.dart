import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/food_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Skip initialization on web platform
      if (kIsWeb) {
        debugPrint('Notifications not supported on web platform');
        _initialized = true;
        return;
      }
      
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialize the plugin
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Request permissions for iOS
      await _requestPermissions();
      
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      _initialized = true; // Mark as initialized to prevent repeated attempts
    }
  }
  
  // Request notification permissions
  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Android permissions are handled automatically by the plugin
  }
  
  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigate to pantry screen when notification is tapped
    // This will be handled by the main app navigation
  }
  
  // Schedule notification for food item expiry
  static Future<void> scheduleFoodExpiryNotification(FoodItem foodItem) async {
    if (kIsWeb) return; // Skip on web platform
    if (!_initialized) await initialize();
    
    try {
      // Calculate notification time (2 days before expiry)
      final notificationTime = foodItem.expiryDate.subtract(const Duration(days: 2));
      
      // Don't schedule if the notification time is in the past
      if (notificationTime.isBefore(DateTime.now())) {
        return;
      }
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'food_expiry',
      'Food Expiry Alerts',
      channelDescription: 'Notifications for food items about to expire',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50),
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
      // Schedule the notification
      await _notifications.zonedSchedule(
        foodItem.id.hashCode, // Use food item ID hash as notification ID
        'Food Expiry Alert! 🍎',
        '${foodItem.name} expires in 2 days. Use it soon to avoid waste!',
        tz.TZDateTime.from(notificationTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'food_expiry:${foodItem.id}',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling food expiry notification: $e');
    }
  }
  
  // Schedule notifications for multiple food items
  static Future<void> scheduleMultipleFoodExpiryNotifications(
      List<FoodItem> foodItems) async {
    for (final foodItem in foodItems) {
      await scheduleFoodExpiryNotification(foodItem);
    }
  }
  
  // Cancel notification for a specific food item
  static Future<void> cancelFoodExpiryNotification(String foodItemId) async {
    if (kIsWeb) return; // Skip on web platform
    try {
      await _notifications.cancel(foodItemId.hashCode);
    } catch (e) {
      debugPrint('Error canceling food expiry notification: $e');
    }
  }

  // Cancel notification (alias for cancelFoodExpiryNotification)
  static Future<void> cancelNotification(int notificationId) async {
    if (kIsWeb) return; // Skip on web platform
    try {
      await _notifications.cancel(notificationId);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return; // Skip on web platform
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
  
  // Show immediate notification
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // Skip on web platform
    if (!_initialized) await initialize();
    
    try {
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }
  
  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      if (!_initialized) await initialize();
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }
  
  // Schedule daily reminder to check pantry
  static Future<void> scheduleDailyPantryReminder() async {
    if (kIsWeb) return; // Skip on web platform
    if (!_initialized) await initialize();
    
    try {
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminders',
      channelDescription: 'Daily reminders to check your pantry',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Schedule for 6 PM daily
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 18, 0);
    
    // If it's already past 6 PM today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
      await _notifications.zonedSchedule(
        999999, // Fixed ID for daily reminder
        'Check Your Pantry! 🥬',
        'Take a moment to review your food items and plan your meals.',
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'daily_reminder',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling daily pantry reminder: $e');
    }
  }
  
  // Update notifications when food items change
  static Future<void> updateFoodItemNotifications(List<FoodItem> foodItems) async {
    if (kIsWeb) return; // Skip on web platform
    
    try {
      // Cancel all existing food expiry notifications
      final pendingNotifications = await getPendingNotifications();
      for (final notification in pendingNotifications) {
        if (notification.payload?.startsWith('food_expiry:') == true) {
          await _notifications.cancel(notification.id);
        }
      }
      
      // Schedule new notifications
      await scheduleMultipleFoodExpiryNotifications(foodItems);
    } catch (e) {
      debugPrint('Error updating food item notifications: $e');
    }
  }
  
  // Check notification permissions
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false; // Not supported on web platform
    if (!_initialized) await initialize();
    
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
      
      return true; // Assume enabled for iOS
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }

  Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return false; // No notifications on web
    if (!_initialized) await initialize();
    
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
      
      return true; // Assume enabled for iOS
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
      return false;
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return; // No notifications on web
    if (!_initialized) await initialize();
    
    try {
      // Request Android permissions
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
      
      // Request iOS permissions
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }
}