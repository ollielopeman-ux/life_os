import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/services/notification_service.dart';
import 'services/widget_service.dart';
import 'features/schedule/providers/schedule_provider.dart';
import 'features/gym/providers/gym_provider.dart';
import 'features/reading/providers/reading_provider.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('gym');
  await Hive.openBox('reading');
  await Hive.openBox('body');
  await Hive.openBox('schedule');
  await Hive.openBox('cardio');
  await Hive.openBox('plyo');
  await Hive.openBox('checklist');
  await Hive.openBox('settings');

  await NotificationService.instance.init(onTap: _handleNotificationTap);
  await WidgetService.init();

  runApp(const ProviderScope(child: LifeOsApp()));
}

void _handleNotificationTap(String? payload) {
  if (payload == null) return;
  NotificationService.pendingAction.value = payload;
  switch (payload) {
    case kPayloadWeight:
      appRouter.go('/body');
    case kPayloadGym:
      appRouter.go('/gym');
    case kPayloadReading:
      appRouter.go('/reading');
    case kPayloadChecklist:
      appRouter.go('/checklist');
    case kPayloadCardio:
      appRouter.go('/cardio');
  }
}

class LifeOsApp extends ConsumerStatefulWidget {
  const LifeOsApp({super.key});

  @override
  ConsumerState<LifeOsApp> createState() => _LifeOsAppState();
}

class _LifeOsAppState extends ConsumerState<LifeOsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Handle cold-start from notification tap
      final payload = await NotificationService.instance.getLaunchPayload();
      if (payload != null) _handleNotificationTap(payload);
      _scheduleNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleNotifications();
  }

  void _scheduleNotifications() {
    final tasks = ref.read(scheduleProvider);
    final gym = ref.read(gymProvider);
    final books = ref.read(booksProvider);
    final settings = ref.read(settingsProvider);

    final todayWeekday = DateTime.now().weekday;
    final todayDay = gym.selectedSplit?.days
        .where((d) => d.weekdays.contains(todayWeekday))
        .firstOrNull;

    // Update home screen widgets
    WidgetService.updateDaysLeftWidget();
    WidgetService.updateGymWidget(
      workoutName: (todayDay == null || todayDay.isRestDay)
          ? ''
          : todayDay.name,
      exercises: todayDay?.exercises.map((e) => e.name).join(' · ') ?? '',
    );

    final currentBook = books.where((b) => b.status == 'reading').firstOrNull;

    NotificationService.instance.scheduleAll(
      gymStreakDays: _gymStreak(tasks),
      todayIsRestDay: todayDay?.isRestDay ?? false,
      todayWorkoutName: (todayDay?.isRestDay ?? true) ? null : todayDay?.name,
      currentBookTitle: currentBook?.title,
      weightEnabled: settings.weightEnabled,
      weightHour: settings.weightHour,
      weightMinute: settings.weightMinute,
      gymEnabled: settings.gymEnabled,
      gymHour: settings.gymHour,
      gymMinute: settings.gymMinute,
      gymCustomMessage: settings.gymCustomMessage,
      restCustomMessage: settings.restCustomMessage,
      readingEnabled: settings.readingEnabled,
      readingHour: settings.readingHour,
      readingMinute: settings.readingMinute,
      checklistEnabled: settings.checklistEnabled,
      checklistHour: settings.checklistHour,
      checklistMinute: settings.checklistMinute,
      cardioEnabled: settings.cardioEnabled,
      cardioHour: settings.cardioHour,
      cardioMinute: settings.cardioMinute,
    );
  }

  int _gymStreak(List tasks) {
    final today = DateTime.now();
    final gymDates = tasks
        .where((t) => t.isWorkout == true)
        .map((t) {
          final d = t.date as DateTime;
          return DateTime(d.year, d.month, d.day);
        })
        .toSet();

    var streak = 0;
    var d = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 1));
    while (gymDates.contains(d)) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsProvider.select((s) => s.isDarkMode));
    return MaterialApp.router(
      title: 'OAL OS',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
