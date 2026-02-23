import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';

class EditEventScreen extends StatefulWidget {
  final EventItem event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController locationController;
  late TextEditingController hoursController;
  late DateTime selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    descController = TextEditingController(text: widget.event.description);
    locationController = TextEditingController(text: widget.event.location);
    hoursController = TextEditingController(text: widget.event.hours.toString());
    selectedDate = widget.event.eventdate;
    startTime = _parseTime(widget.event.starttime);
    endTime = _parseTime(widget.event.endtime);
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
      if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "Select time";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? startTime : endTime) ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() {
        isStart ? startTime = picked : endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardColor = Theme.of(context).cardTheme.color ?? const Color(0xFF1F2933);
    final inputFillColor = Theme.of(context).inputDecorationTheme.fillColor ?? const Color(0xFF1F2933);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Edit Event")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Title", textColor),
            _input("Title", titleController, inputFillColor, textColor, subTextColor),
            const SizedBox(height: 12),
            _label("Description", textColor),
            _input("Description", descController, inputFillColor, textColor, subTextColor, maxLines: 3),
            const SizedBox(height: 12),
            _label("Location", textColor),
            _input("Location", locationController, inputFillColor, textColor, subTextColor),
            const SizedBox(height: 12),
            _label("Hours", textColor),
            _input("Hours", hoursController, inputFillColor, textColor, subTextColor, keyboardType: TextInputType.number),

            const SizedBox(height: 16),

            // -------- DATE PICKER --------
            _label("Event Date", textColor),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    Icon(Icons.calendar_today, color: subTextColor, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // -------- TIME PICKERS --------
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Start Time", style: TextStyle(color: textColor.withOpacity(0.7))),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(startTime), style: TextStyle(color: textColor.withOpacity(0.7))),
                              Icon(Icons.access_time, color: subTextColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("End Time", style: TextStyle(color: textColor.withOpacity(0.7))),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(endTime), style: TextStyle(color: textColor.withOpacity(0.7))),
                              Icon(Icons.access_time, color: subTextColor, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // -------- SAVE BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  String dateStr = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                  String startTimeStr = _formatTime(startTime);
                  String endTimeStr = _formatTime(endTime);

                  final updated = EventItem(
                    id: widget.event.id,
                    title: titleController.text,
                    description: descController.text,
                    location: locationController.text,
                    date: dateStr,
                    eventdate: selectedDate,
                    hours: int.parse(hoursController.text),
                    starttime: startTimeStr,
                    endtime: endTimeStr,
                    joined: widget.event.joined,
                    completed: widget.event.completed,
                  );

                  await DataService.instance.updateEvent(updated);

                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
    );
  }

  Widget _input(
    String hint,
    TextEditingController controller,
    Color fillColor,
    Color textColor,
    Color hintColor, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
