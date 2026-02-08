import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_details.dart';
import 'event_model.dart';
import 'event_details_admin.dart';

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

  @override
  Widget build(BuildContext context) {
    final events = DataService.instance.events;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Manage Events"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------- CREATE EVENT ----------
            label("Event Title"),
            input(titleController, "Enter event title"),

            label("Description"),
            input(descController, "Enter description", maxLines: 3),

            label("Location"),
            input(locationController, "Enter location"),

            label("Hours"),
            input(hoursController, "Enter hours",
                keyboardType: TextInputType.number),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: dateBox(
                    "Start Date",
                    startDate,
                        () => pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: dateBox(
                    "End Date",
                    endDate,
                        () => pickDate(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty ||
                      descController.text.isEmpty ||
                      locationController.text.isEmpty ||
                      hoursController.text.isEmpty ||
                      startDate == null ||
                      endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  final event = EventItem(
                    title: titleController.text,
                    description: descController.text,
                    Location: locationController.text,
                    date:
                    "${startDate!.day}/${startDate!.month}/${startDate!.year}",
                    hours: int.parse(hoursController.text),
                  );

                  DataService.instance.addEvent(event);

                  titleController.clear();
                  descController.clear();
                  locationController.clear();
                  hoursController.clear();
                  startDate = null;
                  endDate = null;

                  setState(() {});
                },
                child: const Text("Create Event"),
              ),
            ),

            const SizedBox(height: 30),

            // ---------- EXISTING EVENTS ----------
            const Text(
              "Existing Events",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            events.isEmpty
                ? const Text(
              "No events created yet",
              style: TextStyle(color: Colors.white54),
            )
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
                            EventDetailsScreen(event: event),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2933),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: Colors.blue),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Date: ${event.date}",
                                style: const TextStyle(
                                    color: Colors.white54),
                              ),
                              Text(
                                "Hours: ${event.hours}",
                                style: const TextStyle(
                                    color: Colors.white54),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          event.completed
                              ? "Completed"
                              : event.joined
                              ? "Ongoing"
                              : "Upcoming",
                          style: TextStyle(
                            color: event.completed
                                ? Colors.greenAccent
                                : event.joined
                                ? Colors.orangeAccent
                                : Colors.blueAccent,
                            fontSize: 12,
                          ),
                        ),
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

  // ---------- UI HELPERS ----------

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget input(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget dateBox(
      String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null
                      ? "Select date"
                      : "${date.day}/${date.month}/${date.year}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const Icon(Icons.calendar_today,
                    color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
