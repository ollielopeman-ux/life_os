import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_init;
import 'package:flutter_timezone/flutter_timezone.dart';

// ── Payload constants ──────────────────────────────────────────────────────────
const String kPayloadWeight = 'weight';
const String kPayloadGym = 'gym';
const String kPayloadReading = 'reading';
const String kPayloadChecklist = 'checklist';
const String kPayloadCardio = 'cardio';
const String kPayloadAddBook = 'add_book';

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'life_os_reminders';
  static const _channelName = 'Life OS Reminders';

  static const int idWeight = 1;
  static const int idGym = 2;
  static const int idReading = 3;
  static const int idChecklist = 4;
  static const int idCardio = 5;

  /// Set by the notification tap handler; screens consume and clear this.
  static final pendingAction = ValueNotifier<String?>(null);

  // ── Initialisation ──────────────────────────────────────────────────────────

  Future<void> init({required void Function(String? payload) onTap}) async {
    if (_ready) return;

    tz_init.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (d) => onTap(d.payload),
      onDidReceiveBackgroundNotificationResponse: _bgHandler,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);

    _ready = true;
  }

  /// Returns payload if app was cold-started by tapping a notification.
  Future<String?> getLaunchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp == true) {
        return details?.notificationResponse?.payload;
      }
    } catch (_) {
      // Platform (e.g. Windows) may not support launch details
    }
    return null;
  }

  // ── Schedule all ────────────────────────────────────────────────────────────

  /// Call on app launch and when returning to foreground.
  Future<void> scheduleAll({
    required int gymStreakDays,
    required bool todayIsRestDay,
    required String? todayWorkoutName,
    required String? currentBookTitle,
    bool weightEnabled = true,
    int weightHour = 8,
    int weightMinute = 0,
    bool gymEnabled = true,
    int gymHour = 7,
    int gymMinute = 30,
    String gymCustomMessage = '',
    String restCustomMessage = '',
    bool readingEnabled = true,
    int readingHour = 20,
    int readingMinute = 0,
    bool checklistEnabled = true,
    int checklistHour = 10,
    int checklistMinute = 0,
    bool cardioEnabled = true,
    int cardioHour = 18,
    int cardioMinute = 0,
  }) async {
    if (!_ready) return;
    if (weightEnabled) {
      await _scheduleWeight(weightHour, weightMinute);
    } else {
      await _plugin.cancel(idWeight);
    }
    if (gymEnabled) {
      await _scheduleGym(
        streakDays: gymStreakDays,
        isRestDay: todayIsRestDay,
        workoutName: todayWorkoutName,
        hour: gymHour,
        minute: gymMinute,
        customGymMsg: gymCustomMessage,
        customRestMsg: restCustomMessage,
      );
    } else {
      await _plugin.cancel(idGym);
    }
    if (readingEnabled && currentBookTitle != null) {
      await _scheduleReading(bookTitle: currentBookTitle, hour: readingHour, minute: readingMinute);
    } else {
      await _plugin.cancel(idReading);
    }
    if (checklistEnabled) {
      await _scheduleChecklist(checklistHour, checklistMinute);
    } else {
      await _plugin.cancel(idChecklist);
    }
    if (cardioEnabled) {
      await _scheduleCardio(cardioHour, cardioMinute);
    } else {
      await _plugin.cancel(idCardio);
    }
  }

  // ── Individual schedulers ───────────────────────────────────────────────────

  Future<void> _scheduleWeight(int hour, int minute) => _plugin.zonedSchedule(
        idWeight,
        'Good morning ☀️',
        "Don't forget to log your weight",
        _nextInstanceOf(hour, minute),
        _details(),
        payload: kPayloadWeight,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  Future<void> _scheduleGym({
    required int streakDays,
    required bool isRestDay,
    required String? workoutName,
    required int hour,
    required int minute,
    String customGymMsg = '',
    String customRestMsg = '',
  }) {
    final String title;
    final String body;

    if (isRestDay) {
      title = 'Rest day 💆';
      body = customRestMsg.isNotEmpty
          ? customRestMsg
          : _restMessages[DateTime.now().day % _restMessages.length];
    } else if (streakDays >= 2) {
      title = '$streakDays day streak 🔥';
      body = customGymMsg.isNotEmpty
          ? customGymMsg
          : "Don't break it — ${workoutName ?? 'your workout'} is waiting";
    } else {
      title = 'Time to train 🏋️';
      body = customGymMsg.isNotEmpty
          ? customGymMsg
          : workoutName != null
              ? '$workoutName is on the schedule today'
              : 'You usually train at this time — want to start?';
    }

    return _plugin.zonedSchedule(
      idGym,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details(),
      payload: kPayloadGym,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleReading({required String bookTitle, required int hour, required int minute}) =>
      _plugin.zonedSchedule(
        idReading,
        'Have you read today? 📖',
        "Make some progress on '$bookTitle'",
        _nextInstanceOf(hour, minute),
        _details(),
        payload: kPayloadReading,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  Future<void> _scheduleChecklist(int hour, int minute) => _plugin.zonedSchedule(
        idChecklist,
        'Plan your day ✅',
        'What do you want to get done today?',
        _nextInstanceOf(hour, minute),
        _details(),
        payload: kPayloadChecklist,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  Future<void> _scheduleCardio(int hour, int minute) => _plugin.zonedSchedule(
        idCardio,
        'Have you run today? 🏃',
        'Keep your cardio going — every run counts',
        _nextInstanceOf(hour, minute),
        _details(),
        payload: kPayloadCardio,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  // ── Helpers ─────────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

  static const _restMessages = [
    'Recovery is part of the process. You earned it.',
    'Rest well — your muscles are growing stronger today.',
    'Champions rest too. See you tomorrow 💪',
    "Sleep, eat, recover. That's the plan today.",
    'Active rest counts. Go for a walk or stretch.',
  ];
}

@pragma('vm:entry-point')
void _bgHandler(NotificationResponse _) {}
