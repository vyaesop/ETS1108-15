import 'package:flutter/material.dart';

import 'models/app_models.dart';

class MockData {
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static final defaultProfile = UserProfile(
    id: 1,
    name: 'Aditya',
    city: 'Jakarta',
    timezone: 'GMT+7',
    goals: 'Meetings|Client calls|Personal plans',
  );

  static List<AppEvent> seedEvents() {
    return [
      AppEvent(
        title: 'You Have A Meeting',
        start: const TimeOfDay(hour: 10, minute: 45),
        end: const TimeOfDay(hour: 11, minute: 30),
        location: 'Lotte Lounge',
        attendees: const ['AL', 'RB', 'KT'],
        colorValue: const Color(0xFF9A6B72).value,
        date: today,
        reminder: true,
      ),
      AppEvent(
        title: 'You Have A Lunch W/ Client',
        start: const TimeOfDay(hour: 12, minute: 10),
        end: const TimeOfDay(hour: 13, minute: 0),
        location: 'Rodist Resto',
        attendees: const ['EM', 'YA'],
        colorValue: const Color(0xFFE16645).value,
        date: today,
        reminder: true,
      ),
      AppEvent(
        title: 'Call Wiz For Update',
        start: const TimeOfDay(hour: 16, minute: 20),
        end: const TimeOfDay(hour: 16, minute: 45),
        location: 'Remote',
        attendees: const ['AV', 'BC'],
        colorValue: const Color(0xFFAEC0C7).value,
        date: today.add(const Duration(days: 1)),
        reminder: false,
      ),
      AppEvent(
        title: 'Web Update',
        start: const TimeOfDay(hour: 15, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 0),
        location: 'Studio',
        attendees: const ['UI', 'DEV'],
        colorValue: const Color(0xFF8EC9CB).value,
        date: today.add(const Duration(days: 4)),
        reminder: true,
      ),
    ];
  }

  static final monthPalette = <Color>[
    const Color(0xFFAED39A),
    const Color(0xFFB2AEDF),
    const Color(0xFFB57E7E),
    const Color(0xFF494949),
    const Color(0xFF1D3D53),
    const Color(0xFF2D87A7),
    const Color(0xFF59677A),
    const Color(0xFFC1D665),
    const Color(0xFFA4C7E5),
    const Color(0xFFE8C47D),
    const Color(0xFF7D87B1),
    const Color(0xFFB2B2B2),
  ];
}
