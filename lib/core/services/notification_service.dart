import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:iron_mind/features/challenge/data/models/challenge_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    // 1. Initialize timezone database
    tz.initializeTimeZones();

    // 2. Detect and set device timezone
    _configureLocalTimezone();
    debugPrint('tz.local is now: ${tz.local.name}');
    debugPrint('tz.local current time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('Device DateTime.now(): ${DateTime.now()}');

    // 3. Initialize notification plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    _initialized = true;
    debugPrint('NotificationService core initialized');

    // 4. Request permissions for Android 13+ (non-blocking)
    await _requestPermissions();
    debugPrint('NotificationService fully initialized');
  }

  static void _configureLocalTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    debugPrint(
      'Device timezone offset: $offset (${offset.inHours}h ${offset.inMinutes % 60}m)',
    );
    debugPrint('Device timeZoneName: ${now.timeZoneName}');

    // Strategy 1: Try to find by common timezone name mappings
    final nameMap = <String, String>{
      'PKT': 'Asia/Karachi',
      'IST': 'Asia/Kolkata',
      'EST': 'America/New_York',
      'CST': 'America/Chicago',
      'MST': 'America/Denver',
      'PST': 'America/Los_Angeles',
      'GMT': 'Europe/London',
      'CET': 'Europe/Paris',
      'JST': 'Asia/Tokyo',
      'KST': 'Asia/Seoul',
      'HKT': 'Asia/Hong_Kong',
      'SGT': 'Asia/Singapore',
      'AEST': 'Australia/Sydney',
    };

    final deviceTzName = now.timeZoneName;
    if (nameMap.containsKey(deviceTzName)) {
      try {
        final location = tz.getLocation(nameMap[deviceTzName]!);
        tz.setLocalLocation(location);
        debugPrint('Set timezone via name map: ${location.name}');
        return;
      } catch (e) {
        debugPrint('Name map lookup failed: $e');
      }
    }

    // Strategy 2: Try using the timeZoneName directly (sometimes it's like "Asia/Karachi")
    try {
      final location = tz.getLocation(deviceTzName);
      tz.setLocalLocation(location);
      debugPrint('Set timezone directly from name: ${location.name}');
      return;
    } catch (_) {
      // Not a valid tz database name
    }

    // Strategy 3: Find by offset match
    for (final location in tz.timeZoneDatabase.locations.values) {
      final tzNow = tz.TZDateTime.now(location);
      if (tzNow.timeZoneOffset == offset) {
        tz.setLocalLocation(location);
        debugPrint('Set timezone via offset match: ${location.name}');
        return;
      }
    }

    debugPrint('WARNING: Could not find matching timezone! Using UTC.');
  }

  static Future<void> _requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        try {
          final bool? granted = await androidImplementation
              .requestNotificationsPermission();
          debugPrint('Notification permission granted: $granted');
        } catch (e) {
          debugPrint('Notification permission request failed: $e');
        }

        try {
          final bool? exactAlarmGranted = await androidImplementation
              .requestExactAlarmsPermission();
          debugPrint('Exact alarm permission granted: $exactAlarmGranted');
        } catch (e) {
          debugPrint('Exact alarm permission failed (OK): $e');
        }
      }
    } catch (e) {
      debugPrint('Permission request failed entirely: $e');
    }
  }

  static Future<void> scheduleDailyNotification({
    required TimeOfDay time,
    ChallengeModel? activeChallenge,
  }) async {
    if (!_initialized) {
      debugPrint('ERROR: NotificationService not initialized!');
      return;
    }

    await _notificationsPlugin.cancelAll();

    final String title = _getMotivationalTitle();
    final String body = _getNotificationBody(activeChallenge);

    // Calculate delay from now to target time
    final now = DateTime.now();
    var targetDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (targetDateTime.isBefore(now)) {
      targetDateTime = targetDateTime.add(const Duration(days: 1));
    }
    final delay = targetDateTime.difference(now);

    debugPrint('=== SCHEDULING NOTIFICATION ===');
    debugPrint('Current time: $now');
    debugPrint('Target time: $targetDateTime');
    debugPrint('Delay: $delay');
    debugPrint('tz.local: ${tz.local.name}');
    debugPrint('==============================');

    // Check exact alarm permission status
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      try {
        final canSchedule = await androidImpl.canScheduleExactNotifications();
        debugPrint('canScheduleExactNotifications: $canSchedule');
      } catch (e) {
        debugPrint('canScheduleExactNotifications check failed: $e');
      }
    }

    // Try zonedSchedule with inexactAllowWhileIdle (doesn't need SCHEDULE_EXACT_ALARM)
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
      debugPrint('TZ scheduledDate: $scheduledDate');

      await _notificationsPlugin.zonedSchedule(
        0,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription:
                'Reminds you to check your progress and challenges',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('zonedSchedule succeeded!');

      // Verify it was registered
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('Pending notifications count: ${pending.length}');
      for (final p in pending) {
        debugPrint('  Pending: id=${p.id}, title=${p.title}');
      }
    } catch (e, stack) {
      debugPrint('zonedSchedule FAILED: $e');
      debugPrint('Stack: $stack');
    }

    // Also use Future.delayed as a reliable backup (works while app is alive)
    debugPrint('Setting Future.delayed backup ($delay)');
    Future.delayed(delay, () async {
      try {
        await _notificationsPlugin.show(
          1,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder',
              'Daily Reminder',
              channelDescription:
                  'Reminds you to check your progress and challenges',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      } catch (_) {}
    });

    debugPrint('Notification scheduled (both methods)!');
  }

  /// Schedule a test notification 10 seconds from now using Future.delayed
  /// This bypasses AlarmManager entirely to test if the issue is with scheduling
  static Future<void> scheduleTestIn30Seconds() async {
    if (!_initialized) {
      debugPrint('ERROR: NotificationService not initialized!');
      return;
    }

    debugPrint('=== SCHEDULING TEST via Future.delayed (10s) ===');
    debugPrint('Current time: ${DateTime.now()}');
    debugPrint(
      'Will fire at: ${DateTime.now().add(const Duration(seconds: 10))}',
    );
    debugPrint('================================================');

    Future.delayed(const Duration(seconds: 10), () async {
      debugPrint('Future.delayed fired! Showing notification now...');
      await _notificationsPlugin.show(
        98,
        'Delayed Test',
        'This was scheduled 10 seconds ago via Future.delayed!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription: 'Test notification',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      debugPrint('Delayed test notification shown!');
    });

    debugPrint('Future.delayed test scheduled (keep app open for 10 seconds)');
  }

  /// Show a test notification immediately
  static Future<void> showTestNotification() async {
    debugPrint('Firing immediate test notification...');
    await _notificationsPlugin.show(
      99,
      'Test Notification',
      'If you see this, notifications are working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription:
              'Reminds you to check your progress and challenges',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint('Test notification fired!');
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static String _getMotivationalTitle() {
    final List<String> titles = [
      "UNSTOPPABLE FORCE",
      "DISCIPLINE IS FREEDOM",
      "KEEP THE FIRE BURNING",
      "CHAMPION MINDSET",
      "STAY FOCUSED",
    ];
    titles.shuffle();
    return titles.first;
  }

  static String _getNotificationBody(ChallengeModel? challenge) {
    if (challenge == null) {
      return "Don't let the day slip away. Check your progress and stay on track!";
    }

    final int remaining = challenge.daysRemaining;
    final int streak = challenge.currentStreak;

    String message = "Do today's challenge: ${challenge.name}. ";

    if (streak > 0) {
      message += "Don't break your $streak day streak! ";
    } else {
      message += "Start your streak today! ";
    }

    if (remaining <= 5) {
      message += "Only $remaining days left! Finish strong.";
    } else {
      message += "Keep pushing, $remaining days to go.";
    }

    return message;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
