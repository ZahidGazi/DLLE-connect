import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'event_analytics.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  File? _selectedImage;

  // Targeting
  String? _selectedTargetCourse; // null = "All Courses"
  int? _selectedTargetYear;      // null = "All Years"
  List<Map<String, dynamic>> _courses = [];

  EventItem? _editingEvent;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    await DataService.instance.fetchCourses();
    if (mounted) {
      setState(() {
        _courses = DataService.instance.courses;
      });
    }
  }

  int get _currentMaxYear {
    if (_selectedTargetCourse == null) return 4;
    final course = _courses.firstWhere(
      (c) => c['name'] == _selectedTargetCourse,
      orElse: () => {'max_year': 4},
    );
    return (course['max_year'] as int?) ?? 4;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => isStart ? startDate = picked : endDate = picked);
    }
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? startTime : endTime) ??
          const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => isStart ? startTime = picked : endTime = picked);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "Select time";
    final hour =
        time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
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

  void _startEdit(EventItem event) {
    setState(() {
      _editingEvent = event;
      titleController.text = event.title;
      descController.text = event.description;
      locationController.text = event.location;
      hoursController.text = event.hours.toString();
      startDate = event.eventdate;
      endDate = event.eventdate;
      startTime = _parseTime(event.starttime);
      endTime = _parseTime(event.endtime);
      _selectedTargetCourse = event.targetCourse;
      _selectedTargetYear = event.targetYear;

      if (event.imagepath != null) {
        _selectedImage = File(event.imagepath!);
      } else {
        _selectedImage = null;
      }
    });
  }

  void _resetForm() {
    setState(() {
      _editingEvent = null;
      titleController.clear();
      descController.clear();
      locationController.clear();
      hoursController.clear();
      startDate = null;
      endDate = null;
      startTime = null;
      endTime = null;
      _selectedImage = null;
      _selectedTargetCourse = null;
      _selectedTargetYear = null;
    });
  }

  Future<void> _confirmDelete(EventItem event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text("Delete Event",
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(
          "Are you sure you want to delete \"${event.title}\"? This will also remove all student registrations for this event.",
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && event.id != null) {
      await DataService.instance.deleteEvent(event.id!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = DataService.instance.events;
    final cardColor =
        Theme.of(context).cardTheme.color ?? const Color(0xFF1F2933);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final inputFillColor =
        Theme.of(context).inputDecorationTheme.fillColor ??
            const Color(0xFF1F2933);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:
            Text(_editingEvent == null ? "Create Event" : "Edit Event"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- IMAGE PICKER --------
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: subTextColor.withOpacity(0.3)),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: kIsWeb
                            ? Image.network(_selectedImage!.path,
                                fit: BoxFit.cover)
                            : Image.file(_selectedImage!,
                                fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 40,
                              color: subTextColor.withOpacity(0.6)),
                          const SizedBox(height: 8),
                          Text("Tap to add Event Image",
                              style: TextStyle(
                                  color:
                                      subTextColor.withOpacity(0.6))),
                        ],
                      ),
              ),
            ),

            // -------- FORM FIELDS --------
            _label("Event Title", textColor),
            _input(titleController, "Enter event title", inputFillColor,
                textColor, subTextColor),
            _label("Description", textColor),
            _input(descController, "Enter description", inputFillColor,
                textColor, subTextColor,
                maxLines: 3),
            _label("Location", textColor),
            _input(locationController, "Enter location", inputFillColor,
                textColor, subTextColor),
            _label("Hours", textColor),
            _input(hoursController, "Enter hours", inputFillColor,
                textColor, subTextColor,
                keyboardType: TextInputType.number),

            const SizedBox(height: 12),

            // -------- DATE PICKERS --------
            Row(
              children: [
                Expanded(
                    child: _dateBox("Start Date", startDate,
                        () => pickDate(true), cardColor, textColor, subTextColor)),
                const SizedBox(width: 12),
                Expanded(
                    child: _dateBox("End Date", endDate,
                        () => pickDate(false), cardColor, textColor, subTextColor)),
              ],
            ),

            const SizedBox(height: 12),

            // -------- TIME PICKERS --------
            Row(
              children: [
                Expanded(
                    child: _timeBox("Start Time", startTime,
                        () => pickTime(true), cardColor, textColor, subTextColor)),
                const SizedBox(width: 12),
                Expanded(
                    child: _timeBox("End Time", endTime,
                        () => pickTime(false), cardColor, textColor, subTextColor)),
              ],
            ),

            const SizedBox(height: 16),

            // -------- TARGETING --------
            Text(
              "Target Audience",
              style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Course targeting dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: inputFillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedTargetCourse,
                  isExpanded: true,
                  dropdownColor: cardColor,
                  style: TextStyle(color: textColor, fontSize: 14),
                  hint: Text("All Courses (visible to everyone)",
                      style: TextStyle(
                          color: subTextColor.withOpacity(0.6),
                          fontSize: 14)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text("All Courses",
                          style: TextStyle(color: textColor)),
                    ),
                    ..._courses.map((course) => DropdownMenuItem<String?>(
                          value: course['name'] as String,
                          child: Text(course['name'] as String,
                              style: TextStyle(color: textColor)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTargetCourse = value;
                      _selectedTargetYear = null;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Year targeting dropdown (only shown when a course is selected)
            if (_selectedTargetCourse != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedTargetYear,
                    isExpanded: true,
                    dropdownColor: cardColor,
                    style: TextStyle(color: textColor, fontSize: 14),
                    hint: Text("All Years in $_selectedTargetCourse",
                        style: TextStyle(
                            color: subTextColor.withOpacity(0.6),
                            fontSize: 14)),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text("All Years",
                            style: TextStyle(color: textColor)),
                      ),
                      ...List.generate(_currentMaxYear, (i) => i + 1)
                          .map((year) => DropdownMenuItem<int?>(
                                value: year,
                                child: Text("Year $year",
                                    style: TextStyle(color: textColor)),
                              )),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedTargetYear = value),
                  ),
                ),
              ),

            // Targeting summary chip
            if (_selectedTargetCourse != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  children: [
                    Chip(
                      backgroundColor: Colors.blueAccent.withOpacity(0.15),
                      label: Text(
                        _selectedTargetYear == null
                            ? "📌 $_selectedTargetCourse — All Years"
                            : "📌 $_selectedTargetCourse — Year $_selectedTargetYear",
                        style: const TextStyle(
                            color: Colors.blueAccent, fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close,
                          size: 14, color: Colors.blueAccent),
                      onDeleted: () => setState(() {
                        _selectedTargetCourse = null;
                        _selectedTargetYear = null;
                      }),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // -------- SUBMIT BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty ||
                      descController.text.isEmpty ||
                      locationController.text.isEmpty ||
                      hoursController.text.isEmpty ||
                      startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  String dateStr =
                      "${startDate!.day}/${startDate!.month}/${startDate!.year}";
                  String startTimeStr = _formatTime(
                      startTime ??
                          const TimeOfDay(hour: 10, minute: 0));
                  String endTimeStr = _formatTime(
                      endTime ?? const TimeOfDay(hour: 14, minute: 0));

                  if (_editingEvent == null) {
                    final event = EventItem(
                      title: titleController.text,
                      description: descController.text,
                      location: locationController.text,
                      date: dateStr,
                      hours: int.parse(hoursController.text),
                      imagepath: _selectedImage?.path,
                      eventdate: startDate!,
                      starttime: startTimeStr,
                      endtime: endTimeStr,
                      targetCourse: _selectedTargetCourse,
                      targetYear: _selectedTargetYear,
                    );
                    await DataService.instance.addEvent(event);
                  } else {
                    final updatedEvent = EventItem(
                      id: _editingEvent!.id,
                      title: titleController.text,
                      description: descController.text,
                      location: locationController.text,
                      date: dateStr,
                      hours: int.parse(hoursController.text),
                      imagepath: _selectedImage?.path,
                      joined: _editingEvent!.joined,
                      completed: _editingEvent!.completed,
                      eventdate: startDate!,
                      starttime: startTimeStr,
                      endtime: endTimeStr,
                      targetCourse: _selectedTargetCourse,
                      targetYear: _selectedTargetYear,
                    );
                    await DataService.instance.updateEvent(updatedEvent);
                  }

                  _resetForm();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editingEvent == null
                      ? Colors.blueAccent
                      : Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _editingEvent == null ? "Create Event" : "Update Event",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),

            if (_editingEvent != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _resetForm,
                    child: const Text("Cancel Edit",
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // -------- EXISTING EVENTS LIST --------
            Text(
              "Existing Events",
              style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            events.isEmpty
                ? Text("No events created yet",
                    style: TextStyle(color: subTextColor))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventParticipationScreen(event: event),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black26,
                                  image: event.imagepath != null
                                      ? DecorationImage(
                                          image: kIsWeb
                                              ? NetworkImage(
                                                      event.imagepath!)
                                                  as ImageProvider
                                              : FileImage(
                                                  File(event.imagepath!)),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: event.imagepath == null
                                    ? const Icon(Icons.event,
                                        color: Colors.blueAccent)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(event.title,
                                        style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(event.date,
                                        style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12)),
                                    Text(
                                        "${event.starttime} - ${event.endtime}",
                                        style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12)),
                                    // Targeting badge
                                    if (event.targetCourse != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            event.targetYear == null
                                                ? "📌 ${event.targetCourse}"
                                                : "📌 ${event.targetCourse} · Yr ${event.targetYear}",
                                            style: const TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blueAccent,
                                        size: 20),
                                    onPressed: () => _startEdit(event),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent,
                                        size: 20),
                                    onPressed: () =>
                                        _confirmDelete(event),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // -------- HELPER WIDGETS --------

  Widget _label(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(text,
          style: TextStyle(color: textColor.withOpacity(0.7))),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint,
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
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _dateBox(String label, DateTime? date, VoidCallback onTap,
      Color cardColor, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: textColor.withOpacity(0.7))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null
                      ? "Select date"
                      : "${date.day}/${date.month}/${date.year}",
                  style:
                      TextStyle(color: textColor.withOpacity(0.7)),
                ),
                Icon(Icons.calendar_today,
                    color: subTextColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeBox(String label, TimeOfDay? time, VoidCallback onTap,
      Color cardColor, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: textColor.withOpacity(0.7))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(time),
                  style:
                      TextStyle(color: textColor.withOpacity(0.7)),
                ),
                Icon(Icons.access_time,
                    color: subTextColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
