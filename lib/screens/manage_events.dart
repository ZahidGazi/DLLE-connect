import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'event_analytics.dart';
import 'location_picker_sheet.dart';
import '../utils/responsive_helper.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();

  // Location fields
  String? _selectedDisplayAddress;
  double _selectedLat = 0.0;
  double _selectedLng = 0.0;

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  File? _selectedImage;
  String? _existingImageUrl; // URL from Supabase Storage (when editing)

  // Targeting
  List<String> _selectedTargetCourses = []; // empty = "All Courses"
  int? _selectedTargetYear;                 // null = "All Years"
  List<Map<String, dynamic>> _courses = [];

  EventItem? _editingEvent;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await DataService.instance.fetchEvents();
    if (mounted) {
      setState(() {});
    }
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
    if (_selectedTargetCourses.isEmpty) return 4;
    int minYear = 4;
    for (final courseName in _selectedTargetCourses) {
      final course = _courses.firstWhere(
        (c) => c['name'] == courseName,
        orElse: () => {'max_year': 4},
      );
      final maxYear = (course['max_year'] as int?) ?? 4;
      if (maxYear < minYear) minYear = maxYear;
    }
    return minYear;
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
      _selectedDisplayAddress = event.location.isNotEmpty ? event.location : null;
      _selectedLat = event.latitude;
      _selectedLng = event.longitude;
      hoursController.text = event.hours.toString();
      startDate = event.eventdate;
      endDate = event.eventdate;
      startTime = _parseTime(event.starttime);
      endTime = _parseTime(event.endtime);
      _selectedTargetCourses = List<String>.from(event.targetCourses ?? []);
      _selectedTargetYear = event.targetYear;

      // imagepath may be a remote HTTPS URL, a blob URL, or a local file path
      if (event.imagepath != null) {
        if (event.imagepath!.startsWith('https://') ||
            event.imagepath!.startsWith('http://')) {
          // Valid remote URL from Supabase Storage
          _existingImageUrl = event.imagepath;
          _selectedImage = null;
        } else {
          // blob: URLs (web-only, temporary) or unrecognised paths — treat as no image
          _selectedImage = null;
          _existingImageUrl = null;
        }
      } else {
        _selectedImage = null;
        _existingImageUrl = null;
      }
    });
  }

  void _resetForm() {
    setState(() {
      _editingEvent = null;
      titleController.clear();
      descController.clear();
      hoursController.clear();
      _selectedDisplayAddress = null;
      _selectedLat = 0.0;
      _selectedLng = 0.0;
      startDate = null;
      endDate = null;
      startTime = null;
      endTime = null;
      _selectedImage = null;
      _existingImageUrl = null;
      _selectedTargetCourses = [];
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
        padding: ResponsiveHelper.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- IMAGE PICKER --------
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: ResponsiveHelper.imageHeight(context, 160),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: subTextColor.withOpacity(0.3)),
                ),
                child: _selectedImage != null
                    // Newly picked local file
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_selectedImage!,
                            fit: BoxFit.cover),
                      )
                    : _existingImageUrl != null
                        // Existing remote URL from Supabase Storage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image,
                                      size: 40,
                                      color:
                                          subTextColor.withOpacity(0.5)),
                                  const SizedBox(height: 8),
                                  Text("Tap to change image",
                                      style: TextStyle(
                                          color: subTextColor
                                              .withOpacity(0.6))),
                                ],
                              ),
                            ),
                          )
                        // No image
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
            _chooseLocationButton(
                cardColor, textColor, subTextColor, inputFillColor),
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

            // Course targeting — tap to open multi-select dialog
            GestureDetector(
              onTap: () => _showCourseSelectionDialog(
                  cardColor, textColor, subTextColor),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTargetCourses.isEmpty
                            ? "All Courses (visible to everyone)"
                            : "${_selectedTargetCourses.length} course(s) selected",
                        style: TextStyle(
                          color: _selectedTargetCourses.isEmpty
                              ? subTextColor.withOpacity(0.6)
                              : textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down,
                        color: subTextColor, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Year targeting dropdown (only shown when at least one course is selected)
            if (_selectedTargetCourses.isNotEmpty)
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
                    hint: Text(
                      "All Years",
                      style: TextStyle(
                          color: subTextColor.withOpacity(0.6),
                          fontSize: 14),
                    ),
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

            // Targeting summary chips — one per selected course
            if (_selectedTargetCourses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedTargetCourses.map((course) {
                    return Chip(
                      backgroundColor:
                          Colors.blueAccent.withOpacity(0.15),
                      label: Text(
                        _selectedTargetYear == null
                            ? "📌 $course — All Years"
                            : "📌 $course — Year $_selectedTargetYear",
                        style: const TextStyle(
                            color: Colors.blueAccent, fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close,
                          size: 14, color: Colors.blueAccent),
                      onDeleted: () => setState(() {
                        _selectedTargetCourses.remove(course);
                        if (_selectedTargetCourses.isEmpty) {
                          _selectedTargetYear = null;
                        }
                      }),
                    );
                  }).toList(),
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
                      (_selectedDisplayAddress == null ||
                          _selectedDisplayAddress!.isEmpty) ||
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

                  // Upload image to Supabase Storage if a new local file was picked
                  String? finalImageUrl = _existingImageUrl;
                  if (_selectedImage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Uploading image..."),
                          duration: Duration(seconds: 2)),
                    );
                    finalImageUrl = await DataService.instance
                        .uploadEventImage(_selectedImage!);
                    if (finalImageUrl == null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "⚠️ Image upload failed. Event saved without image."),
                            backgroundColor: Colors.orange),
                      );
                    }
                  }

                  if (_editingEvent == null) {
                    final event = EventItem(
                      title: titleController.text,
                      description: descController.text,
                      location: _selectedDisplayAddress!,
                      date: dateStr,
                      hours: int.parse(hoursController.text),
                      imagepath: finalImageUrl,
                      eventdate: startDate!,
                      starttime: startTimeStr,
                      endtime: endTimeStr,
                      latitude: _selectedLat,
                      longitude: _selectedLng,
                      targetCourses: _selectedTargetCourses.isEmpty
                          ? null
                          : _selectedTargetCourses,
                      targetYear: _selectedTargetYear,
                    );
                    await DataService.instance.addEvent(event);
                  } else {
                    final updatedEvent = EventItem(
                      id: _editingEvent!.id,
                      title: titleController.text,
                      description: descController.text,
                      location: _selectedDisplayAddress!,
                      date: dateStr,
                      hours: int.parse(hoursController.text),
                      imagepath: finalImageUrl,
                      joined: _editingEvent!.joined,
                      completed: _editingEvent!.completed,
                      eventdate: startDate!,
                      starttime: startTimeStr,
                      endtime: endTimeStr,
                      latitude: _selectedLat,
                      longitude: _selectedLng,
                      targetCourses: _selectedTargetCourses.isEmpty
                          ? null
                          : _selectedTargetCourses,
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
                                  image: (event.imagepath != null &&
                                          (event.imagepath!.startsWith('https://') ||
                                           event.imagepath!.startsWith('http://')))
                                      ? DecorationImage(
                                          image: NetworkImage(event.imagepath!),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: (event.imagepath == null ||
                                        (!event.imagepath!.startsWith('https://') &&
                                         !event.imagepath!.startsWith('http://')))
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
                                    if (event.targetCourses != null &&
                                        event.targetCourses!.isNotEmpty)
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
                                                ? "📌 ${event.targetCourses!.join(', ')}"
                                                : "📌 ${event.targetCourses!.join(', ')} · Yr ${event.targetYear}",
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

  // -------- MULTI-SELECT COURSE DIALOG --------

  Future<void> _showCourseSelectionDialog(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) async {
    // Work on a temporary copy so Cancel discards changes
    final tempSelected = List<String>.from(_selectedTargetCourses);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text(
              "Select Target Courses",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "All Courses" option — selecting it clears all others
                    CheckboxListTile(
                      title: Text(
                        "All Courses (visible to everyone)",
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      value: tempSelected.isEmpty,
                      activeColor: Colors.blueAccent,
                      checkColor: Colors.white,
                      onChanged: (_) {
                        setDialogState(() => tempSelected.clear());
                      },
                    ),
                    Divider(color: subTextColor.withOpacity(0.2)),
                    // Individual course checkboxes
                    ..._courses.map((course) {
                      final name = course['name'] as String;
                      return CheckboxListTile(
                        title: Text(
                          name,
                          style: TextStyle(color: textColor, fontSize: 14),
                        ),
                        value: tempSelected.contains(name),
                        activeColor: Colors.blueAccent,
                        checkColor: Colors.white,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              tempSelected.add(name);
                            } else {
                              tempSelected.remove(name);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel",
                    style: TextStyle(color: subTextColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _selectedTargetCourses = tempSelected;
                    // Reset year if no courses selected
                    if (_selectedTargetCourses.isEmpty) {
                      _selectedTargetYear = null;
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text("Apply",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
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

  /// "Choose Location" button + selected address preview
  Widget _chooseLocationButton(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color inputFillColor,
  ) {
    final hasLocation = _selectedDisplayAddress != null &&
        _selectedDisplayAddress!.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        final result = await showLocationPicker(
          context,
          initialLat: _selectedLat != 0.0 ? _selectedLat : null,
          initialLng: _selectedLng != 0.0 ? _selectedLng : null,
          initialAddress: _selectedDisplayAddress,
        );
        if (result != null) {
          setState(() {
            _selectedDisplayAddress = result.displayAddress;
            _selectedLat = result.latitude;
            _selectedLng = result.longitude;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasLocation ? inputFillColor : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasLocation
                ? Colors.blueAccent.withOpacity(0.5)
                : subTextColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasLocation ? Icons.location_on : Icons.add_location_alt,
              color: hasLocation
                  ? Colors.blueAccent
                  : subTextColor.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasLocation
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDisplayAddress!,
                          style: TextStyle(
                              color: textColor, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedLat.toStringAsFixed(5)}, ${_selectedLng.toStringAsFixed(5)}',
                          style: TextStyle(
                              color: subTextColor.withOpacity(0.6),
                              fontSize: 11),
                        ),
                      ],
                    )
                  : Text(
                      'Choose Location',
                      style: TextStyle(
                          color: subTextColor.withOpacity(0.6),
                          fontSize: 14),
                    ),
            ),
            Icon(
              Icons.chevron_right,
              color: subTextColor.withOpacity(0.5),
              size: 18,
            ),
          ],
        ),
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
