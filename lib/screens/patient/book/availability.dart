import 'package:flutter/material.dart';

class AvailabilityRange {
  final TimeOfDay start;
  final TimeOfDay end;

  AvailabilityRange({required this.start, required this.end});

  Map<String, String> toMap() => {
    'start': '${start.hour}:${start.minute}',
    'end': '${end.hour}:${end.minute}',
  };

  static AvailabilityRange fromMap(Map<String, dynamic> map) {
    final startParts = (map['start'] as String).split(':');
    final endParts = (map['end'] as String).split(':');
    return AvailabilityRange(
      start: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      end: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
    );
  }
}
