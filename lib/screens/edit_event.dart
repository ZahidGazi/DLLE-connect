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

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    descController = TextEditingController(text: widget.event.description);
    locationController = TextEditingController(text: widget.event.Location);
    hoursController =
        TextEditingController(text: widget.event.hours.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(title: const Text("Edit Event")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            input("Title", titleController),
            const SizedBox(height: 12),
            input("Description", descController, maxLines: 3),
            const SizedBox(height: 12),
            input("Location", locationController),
            const SizedBox(height: 12),
            input("Hours", hoursController,
                keyboardType: TextInputType.number),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final updated = EventItem(
                    title: titleController.text,
                    description: descController.text,
                    Location: locationController.text,
                    date: widget.event.date,
                    eventdate: widget.event.eventdate,
                    hours: int.parse(hoursController.text),
                    starttime: widget.event.starttime,
                    endtime: widget.event.endtime,
                    joined: widget.event.joined,
                    completed: widget.event.completed,
                  );

                  DataService.instance.updateEvent(widget.event, updated);

                  Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget input(
      String hint,
      TextEditingController controller, {
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
}
