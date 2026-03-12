import 'package:flutter/material.dart';

import 'models/app_models.dart';

class MockData {
  static final today = DateTime(2026, 1, 25);

  static final profile = UserProfile(
    name: 'Aditya',
    city: 'Jakarta',
    timezone: 'GMT+7',
    goals: const ['Meetings', 'Client calls', 'Personal plans'],
  );

  static final events = <AppEvent>[
    AppEvent(
      title: 'You Have A Meeting',
      start: const TimeOfDay(hour: 10, minute: 45),
      end: const TimeOfDay(hour: 11, minute: 30),
      location: 'Lotte Lounge',
      attendees: const ['AL', 'RB', 'KT'],
      color: const Color(0xFF9A6B72),
      date: today,
    ),
    AppEvent(
      title: 'You Have A Lunch W/ Client',
      start: const TimeOfDay(hour: 12, minute: 10),
      end: const TimeOfDay(hour: 13, minute: 0),
      location: 'Rodist Resto',
      attendees: const ['EM', 'YA'],
      color: const Color(0xFFE16645),
      date: today,
    ),
    AppEvent(
      title: 'Call Wiz For Update',
      start: const TimeOfDay(hour: 16, minute: 20),
      end: const TimeOfDay(hour: 16, minute: 45),
      location: 'Remote',
      attendees: const ['AV', 'BC'],
      color: const Color(0xFFAEC0C7),
      date: DateTime(2026, 1, 26),
    ),
    AppEvent(
      title: 'Web Update',
      start: const TimeOfDay(hour: 15, minute: 0),
      end: const TimeOfDay(hour: 16, minute: 0),
      location: 'Studio',
      attendees: const ['UI', 'DEV'],
      color: const Color(0xFF8EC9CB),
      date: DateTime(2026, 1, 29),
    ),
  ];

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
