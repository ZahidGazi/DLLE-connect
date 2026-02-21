import 'dart:io';
import 'package:flutter/material.dart';
import 'event_model.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventItem event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ DISPLAY UPLOADED IMAGE OR PLACEHOLDER
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(14),
              ),
              child: widget.event.imagepath != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(widget.event.imagepath!),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 60, color: Colors.white38),
                ),
              )
                  : const Icon(Icons.image, size: 60, color: Colors.white38),
            ),

            const SizedBox(height: 20),

            Text(
              widget.event.title,
              style: const TextStyle( fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(widget.event.date),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 6),
                Text(widget.event.location),
              ],
            ),
            const SizedBox(height: 20),

            const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(widget.event.description),

            const Spacer(),

            // Join Button Logic
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.event.joined
                    ? null
                    : () {
                  setState(() {
                    // In a real app, you'd call DataService.instance.joinEvent here
                    widget.event.joined = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("You joined ${widget.event.title}")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.event.joined ? Colors.white70 : Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.event.joined ? "Already Joined" : "Join Event",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}