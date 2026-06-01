import 'package:flutter/material.dart';

enum AppNotificationType { outage, roadClosure, news, event }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.dateTime,
    required this.icon,
    required this.color,
    required this.type,
    required this.originalData,
  });

  final String id;
  final String title;
  final String body;
  final DateTime dateTime;
  final IconData icon;
  final Color color;
  final AppNotificationType type;
  final Object? originalData;
}
