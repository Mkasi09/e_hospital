import 'package:flutter/material.dart';

class TimeSlotSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<String> availableSlots;
  final List<String> bookedSlots; // <-- add this
  final String? selectedTime;
  final Function(String) onSlotSelected;

  const TimeSlotSelector({
    super.key,
    required this.selectedDate,
    required this.availableSlots,
    required this.bookedSlots,
    required this.selectedTime,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableSlots.isEmpty) {
      return const Center(child: Text('No available slots for this day.'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children:
            availableSlots.map((slot) {
              final isBooked = bookedSlots.contains(slot);
              final isSelected = selectedTime == slot;

              return SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 4,
                child: ChoiceChip(
                  label: Text(
                    slot,
                    style: TextStyle(
                      color:
                          isBooked
                              ? Colors.grey
                              : isSelected
                              ? Colors.white
                              : Colors.black,
                      decoration: isBooked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: isBooked ? null : (_) => onSlotSelected(slot),
                  selectedColor: Colors.blueAccent,
                  backgroundColor: Colors.grey.shade100,
                ),
              );
            }).toList(),
      ),
    );
  }
}
