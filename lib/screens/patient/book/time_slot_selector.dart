import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeSlotSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<String> bookedSlots;
  final String? selectedTime;
  final Function(String) onSlotSelected;

  const TimeSlotSelector({
    super.key,
    required this.selectedDate,
    required this.bookedSlots,
    required this.selectedTime,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(now, selectedDate);

    final timeSlots = List.generate(20, (index) {
      final hour = 9 + (index ~/ 2);
      final minute = (index % 2) * 30;
      return TimeOfDay(hour: hour, minute: minute);
    }).where((timeOfDay) {
      if (!isToday) return true;
      final slotDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      return slotDateTime.isAfter(now);
    }).map((tod) {
      final dt = DateTime(0, 1, 1, tod.hour, tod.minute);
      return DateFormat('HH:mm').format(dt);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Available Time Slots',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((slot) {
              final isBooked = bookedSlots.contains(slot);
              final isSelected = selectedTime == slot;

              return SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 4,
                child: ChoiceChip(
                  label: Text(
                    slot,
                    style: TextStyle(
                      color: isBooked
                          ? Colors.grey
                          : isSelected
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: isBooked ? null : (_) => onSlotSelected(slot),
                  selectedColor: Colors.blueAccent,
                  backgroundColor: isBooked
                      ? Colors.grey.shade300
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
