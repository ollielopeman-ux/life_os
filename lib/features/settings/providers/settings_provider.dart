import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettings {
  final bool weightEnabled;
  final int weightHour;
  final int weightMinute;
  final bool gymEnabled;
  final int gymHour;
  final int gymMinute;
  final String gymCustomMessage;
  final String restCustomMessage;
  final bool readingEnabled;
  final int readingHour;
  final int readingMinute;
  final bool checklistEnabled;
  final int checklistHour;
  final int checklistMinute;
  final bool cardioEnabled;
  final int cardioHour;
  final int cardioMinute;
  final bool isDarkMode;
  final double uiScale;
  final double navBarScale;
  final double navBarBottom;
  final double navBarHPad;
  final bool hapticsEnabled;
  final String weightUnit; // 'kg' or 'lbs'
  final bool showNavLabels;
  final int restTimerSeconds;
  final double? targetWeightKg;
  final int readingGoal;
  final String accentColor; // hex without #, e.g. '5B7FA8'
  final double weightStep;  // kg per step: 1.25, 2.5, 5, 10
  final bool weekStartsMonday;
  final double pageTopPad;

  const AppSettings({
    this.weightEnabled = true,
    this.weightHour = 8,
    this.weightMinute = 0,
    this.gymEnabled = true,
    this.gymHour = 7,
    this.gymMinute = 30,
    this.gymCustomMessage = '',
    this.restCustomMessage = '',
    this.readingEnabled = true,
    this.readingHour = 20,
    this.readingMinute = 0,
    this.checklistEnabled = true,
    this.checklistHour = 10,
    this.checklistMinute = 0,
    this.cardioEnabled = true,
    this.cardioHour = 18,
    this.cardioMinute = 0,
    this.isDarkMode = true,
    this.uiScale = 1.0,
    this.navBarScale = 1.0,
    this.navBarBottom = 8.0,
    this.navBarHPad = 20.0,
    this.hapticsEnabled = true,
    this.weightUnit = 'kg',
    this.showNavLabels = false,
    this.restTimerSeconds = 90,
    this.targetWeightKg,
    this.readingGoal = 0,
    this.accentColor = '5B7FA8',
    this.weightStep = 2.5,
    this.weekStartsMonday = true,
    this.pageTopPad = 20.0,
  });

  AppSettings copyWith({
    bool? weightEnabled,
    int? weightHour,
    int? weightMinute,
    bool? gymEnabled,
    int? gymHour,
    int? gymMinute,
    String? gymCustomMessage,
    String? restCustomMessage,
    bool? readingEnabled,
    int? readingHour,
    int? readingMinute,
    bool? checklistEnabled,
    int? checklistHour,
    int? checklistMinute,
    bool? cardioEnabled,
    int? cardioHour,
    int? cardioMinute,
    bool? isDarkMode,
    double? uiScale,
    double? navBarScale,
    double? navBarBottom,
    double? navBarHPad,
    bool? hapticsEnabled,
    String? weightUnit,
    bool? showNavLabels,
    int? restTimerSeconds,
    double? targetWeightKg,
    bool clearTargetWeight = false,
    int? readingGoal,
    String? accentColor,
    double? weightStep,
    bool? weekStartsMonday,
    double? pageTopPad,
  }) =>
      AppSettings(
        weightEnabled: weightEnabled ?? this.weightEnabled,
        weightHour: weightHour ?? this.weightHour,
        weightMinute: weightMinute ?? this.weightMinute,
        gymEnabled: gymEnabled ?? this.gymEnabled,
        gymHour: gymHour ?? this.gymHour,
        gymMinute: gymMinute ?? this.gymMinute,
        gymCustomMessage: gymCustomMessage ?? this.gymCustomMessage,
        restCustomMessage: restCustomMessage ?? this.restCustomMessage,
        readingEnabled: readingEnabled ?? this.readingEnabled,
        readingHour: readingHour ?? this.readingHour,
        readingMinute: readingMinute ?? this.readingMinute,
        checklistEnabled: checklistEnabled ?? this.checklistEnabled,
        checklistHour: checklistHour ?? this.checklistHour,
        checklistMinute: checklistMinute ?? this.checklistMinute,
        cardioEnabled: cardioEnabled ?? this.cardioEnabled,
        cardioHour: cardioHour ?? this.cardioHour,
        cardioMinute: cardioMinute ?? this.cardioMinute,
        isDarkMode: isDarkMode ?? this.isDarkMode,
        uiScale: uiScale ?? this.uiScale,
        navBarScale: navBarScale ?? this.navBarScale,
        navBarBottom: navBarBottom ?? this.navBarBottom,
        navBarHPad: navBarHPad ?? this.navBarHPad,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        weightUnit: weightUnit ?? this.weightUnit,
        showNavLabels: showNavLabels ?? this.showNavLabels,
        restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
        targetWeightKg: clearTargetWeight ? null : (targetWeightKg ?? this.targetWeightKg),
        readingGoal: readingGoal ?? this.readingGoal,
        accentColor: accentColor ?? this.accentColor,
        weightStep: weightStep ?? this.weightStep,
        weekStartsMonday: weekStartsMonday ?? this.weekStartsMonday,
        pageTopPad: pageTopPad ?? this.pageTopPad,
      );

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        weightEnabled: m['weightEnabled'] ?? true,
        weightHour: m['weightHour'] ?? 8,
        weightMinute: m['weightMinute'] ?? 0,
        gymEnabled: m['gymEnabled'] ?? true,
        gymHour: m['gymHour'] ?? 7,
        gymMinute: m['gymMinute'] ?? 30,
        gymCustomMessage: m['gymCustomMessage'] ?? '',
        restCustomMessage: m['restCustomMessage'] ?? '',
        readingEnabled: m['readingEnabled'] ?? true,
        readingHour: m['readingHour'] ?? 20,
        readingMinute: m['readingMinute'] ?? 0,
        checklistEnabled: m['checklistEnabled'] ?? true,
        checklistHour: m['checklistHour'] ?? 10,
        checklistMinute: m['checklistMinute'] ?? 0,
        cardioEnabled: m['cardioEnabled'] ?? true,
        cardioHour: m['cardioHour'] ?? 18,
        cardioMinute: m['cardioMinute'] ?? 0,
        isDarkMode: m['isDarkMode'] ?? true,
        uiScale: (m['uiScale'] as num?)?.toDouble() ?? 1.0,
        navBarScale: (m['navBarScale'] as num?)?.toDouble() ?? 1.0,
        navBarBottom: (m['navBarBottom'] as num?)?.toDouble() ?? 8.0,
        navBarHPad: (m['navBarHPad'] as num?)?.toDouble() ?? 20.0,
        hapticsEnabled: m['hapticsEnabled'] ?? true,
        weightUnit: m['weightUnit'] ?? 'kg',
        showNavLabels: m['showNavLabels'] ?? false,
        restTimerSeconds: m['restTimerSeconds'] ?? 90,
        targetWeightKg: (m['targetWeightKg'] as num?)?.toDouble(),
        readingGoal: m['readingGoal'] ?? 0,
        accentColor: m['accentColor'] ?? '5B7FA8',
        weightStep: (m['weightStep'] as num?)?.toDouble() ?? 2.5,
        weekStartsMonday: m['weekStartsMonday'] ?? true,
        pageTopPad: (m['pageTopPad'] as num?)?.toDouble() ?? 20.0,
      );

  Map<String, dynamic> toMap() => {
        'weightEnabled': weightEnabled,
        'weightHour': weightHour,
        'weightMinute': weightMinute,
        'gymEnabled': gymEnabled,
        'gymHour': gymHour,
        'gymMinute': gymMinute,
        'gymCustomMessage': gymCustomMessage,
        'restCustomMessage': restCustomMessage,
        'readingEnabled': readingEnabled,
        'readingHour': readingHour,
        'readingMinute': readingMinute,
        'checklistEnabled': checklistEnabled,
        'checklistHour': checklistHour,
        'checklistMinute': checklistMinute,
        'cardioEnabled': cardioEnabled,
        'cardioHour': cardioHour,
        'cardioMinute': cardioMinute,
        'isDarkMode': isDarkMode,
        'uiScale': uiScale,
        'navBarScale': navBarScale,
        'navBarBottom': navBarBottom,
        'navBarHPad': navBarHPad,
        'hapticsEnabled': hapticsEnabled,
        'weightUnit': weightUnit,
        'showNavLabels': showNavLabels,
        'restTimerSeconds': restTimerSeconds,
        'targetWeightKg': targetWeightKg,
        'readingGoal': readingGoal,
        'accentColor': accentColor,
        'weightStep': weightStep,
        'weekStartsMonday': weekStartsMonday,
        'pageTopPad': pageTopPad,
      };
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(_load());

  static AppSettings _load() {
    final box = Hive.box('settings');
    final raw = box.get('app_settings');
    if (raw is Map) {
      try {
        return AppSettings.fromMap(Map<String, dynamic>.from(raw));
      } catch (_) {}
    }
    return const AppSettings();
  }

  void update(AppSettings settings) {
    state = settings;
    Hive.box('settings').put('app_settings', settings.toMap());
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (_) => SettingsNotifier(),
);
