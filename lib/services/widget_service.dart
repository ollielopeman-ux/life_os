import 'dart:convert';
import 'dart:io';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const _appGroupId = 'group.com.ollie.life_os';
  static const _androidPackage = 'com.ollie.life_os';

  static bool get _supported => Platform.isIOS || Platform.isAndroid;

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateGymWidget({
    required String workoutName,
    required String exercises,
  }) async {
    if (!_supported) return;
    await HomeWidget.saveWidgetData('gym_workout_name', workoutName);
    await HomeWidget.saveWidgetData('gym_exercises', exercises);
    await HomeWidget.updateWidget(
      iOSName: 'GymWidget',
      androidName: 'GymWidgetProvider',
      qualifiedAndroidName: '$_androidPackage.GymWidgetProvider',
    );
  }

  static Future<void> updateDaysLeftWidget() async {
    if (!_supported) return;
    final now = DateTime.now();
    final yearEnd = DateTime(now.year + 1, 1, 1);
    final daysLeft =
        yearEnd.difference(DateTime(now.year, now.month, now.day)).inDays;
    await HomeWidget.saveWidgetData('days_left', daysLeft);
    await HomeWidget.saveWidgetData('current_year', now.year);
    await HomeWidget.updateWidget(
      iOSName: 'DaysLeftWidget',
      androidName: 'DaysLeftWidgetProvider',
      qualifiedAndroidName: '$_androidPackage.DaysLeftWidgetProvider',
    );
  }

  static Future<void> updateChecklistWidget(
      List<Map<String, dynamic>> items) async {
    if (!_supported) return;
    await HomeWidget.saveWidgetData('checklist_items', jsonEncode(items));
    await HomeWidget.updateWidget(
      iOSName: 'ChecklistWidget',
      androidName: 'ChecklistWidgetProvider',
      qualifiedAndroidName: '$_androidPackage.ChecklistWidgetProvider',
    );
  }
}
