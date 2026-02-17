import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data_service.dart';
import 'event_details.dart';
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
  File? _selectedImage;

  // ✅ Edit Mode Variable
  EventItem? _editingEvent;

  // ✅ Function to Pick Image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        isStart ? startDate = picked : endDate = picked;
      });
    }
  }

  // ✅ Populate form for editing
  void _startEdit(EventItem event) {
    setState(() {
      _editingEvent = event;
      titleController.text = event.title;
      descController.text = event.description;
      locationController.text = event.Location;
      hoursController.text = event.hours.toString();

      // Parse date string back to DateTime (Simple logic assuming DD/MM/YYYY)
      try {
        List<String> parts = event.date.split('/');
        if (parts.length == 3) {
          startDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          endDate = startDate; // Simplify for now
        }
      } catch (e) {
        startDate = DateTime.now();
      }

      if (event.imagepath != null) {
        _selectedImage = File(event.imagepath!);
      } else {
        _selectedImage = null;
      }
    });
  }

  // ✅ Clear form
  void _resetForm() {
    setState(() {
      _editingEvent = null;
      titleController.clear();
      descController.clear();
      locationController.clear();
      hoursController.clear();
      startDate = null;
      endDate = null;
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = DataService.instance.events;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: Text(_editingEvent == null ? "Create Event" : "Edit Event"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------- IMAGE PICKER ----------
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2933),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.white54),
                    SizedBox(height: 8),
                    Text("Tap to add Event Image", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),

            // ---------- FORM INPUTS ----------
            label("Event Title"),
            input(titleController, "Enter event title"),

            label("Description"),
            input(descController, "Enter description", maxLines: 3),

            label("Location"),
            input(locationController, "Enter location"),

            label("Hours"),
            input(hoursController, "Enter hours", keyboardType: TextInputType.number),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: dateBox("Start Date", startDate, () => pickDate(true))),
                const SizedBox(width: 12),
                Expanded(child: dateBox("End Date", endDate, () => pickDate(false))),
              ],
            ),

            const SizedBox(height: 20),

            // ---------- ACTION BUTTON ----------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty ||
                      descController.text.isEmpty ||
                      locationController.text.isEmpty ||
                      hoursController.text.isEmpty ||
                      startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  String dateStr = "${startDate!.day}/${startDate!.month}/${startDate!.year}";

                  if (_editingEvent == null) {
                    // ✅ CREATE NEW EVENT
                    final event = EventItem(
                      title: titleController.text,
                      description: descController.text,
                      Location: locationController.text,
                      date: dateStr,
                      hours: int.parse(hoursController.text),
                      imagepath: _selectedImage?.path, eventdate: _editingEvent!.eventdate, starttime: '', endtime: '', // Save Image Path
                    );
                    DataService.instance.addEvent(event);
                  } else {
                    // ✅ UPDATE EXISTING EVENT
                    final updatedEvent = EventItem(
                      title: titleController.text,
                      description: descController.text,
                      Location: locationController.text,
                      date: dateStr,
                      hours: int.parse(hoursController.text),
                      imagepath: _selectedImage?.path,
                      // Preserve existing stats
                      joined: _editingEvent!.joined,
                      completed: _editingEvent!.completed,
                      joinedcount: _editingEvent!.joinedcount,
                      completedcount: _editingEvent!.completedcount, eventdate: _editingEvent!.eventdate, starttime: '', endtime: '',
                    );
                    DataService.instance.updateEvent(_editingEvent!, updatedEvent);
                  }

                  _resetForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editingEvent == null ? Colors.blueAccent : Colors.green,
                ),
                child: Text(_editingEvent == null ? "Create Event" : "Update Event"),
              ),
            ),

            if (_editingEvent != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _resetForm,
                    child: const Text("Cancel Edit", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // ---------- EXISTING EVENTS ----------
            const Text(
              "Existing Events",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            events.isEmpty
                ? const Text("No events created yet", style: TextStyle(color: Colors.white54))
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
                        builder: (_) => EventParticipationScreen(event: event),
                      ),
                    );
                  },
                child:  Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2933),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black26,
                          image: event.imagepath != null
                              ? DecorationImage(image: FileImage(File(event.imagepath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: event.imagepath == null
                            ? const Icon(Icons.event, color: Colors.blue)
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(event.date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),

                      // ✅ Edit/Delete Buttons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                            onPressed: () => _startEdit(event),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              DataService.instance.deleteEvent(event);
                              setState(() {});
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                )
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI HELPERS ----------
  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget input(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1F2933),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget dateBox(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1F2933), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date == null ? "Select date" : "${date.day}/${date.month}/${date.year}", style: const TextStyle(color: Colors.white70)),
                const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}