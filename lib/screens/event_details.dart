import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'event_model.dart';
import 'data_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventItem event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isJoining = false;

  Future<void> _joinEvent() async {
    final studentId = DataService.instance.studentId;
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to join an event")),
      );
      return;
    }

    // Check if event date has passed
    if (!DataService.instance.canJoinEvent(widget.event)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This event has already passed and cannot be joined")),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      await DataService.instance.joinEvent(widget.event, studentId);
      if (mounted) {
        setState(() {
          widget.event.joined = true;
          _isJoining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You joined ${widget.event.title}")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to join event: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardColor = Theme.of(context).cardTheme.color ?? const Color(0xFF1F2933);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Event Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- EVENT IMAGE --------
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: widget.event.imagepath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(
                              widget.event.imagepath!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(
                                Icons.broken_image,
                                size: 60,
                                color: subTextColor.withOpacity(0.5),
                              ),
                            )
                          : Image.file(
                              File(widget.event.imagepath!),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(
                                Icons.broken_image,
                                size: 60,
                                color: subTextColor.withOpacity(0.5),
                              ),
                            ),
                    )
                  : Icon(Icons.image, size: 60, color: subTextColor.withOpacity(0.5)),
            ),

            const SizedBox(height: 20),

            // -------- STATUS BADGE --------
            if (widget.event.completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 6),
                    Text("Completed", style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else if (widget.event.joined)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.how_to_reg, color: Colors.orangeAccent, size: 16),
                    SizedBox(width: 6),
                    Text("Joined", style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            // -------- TITLE --------
            Text(
              widget.event.title,
              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // -------- INFO CARDS --------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.calendar_today, "Date", widget.event.date, textColor, subTextColor),
                  const SizedBox(height: 12),
                  _infoRow(Icons.access_time, "Time", "${widget.event.starttime} - ${widget.event.endtime}", textColor, subTextColor),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on, "Location", widget.event.location, textColor, subTextColor),
                  const SizedBox(height: 12),
                  _infoRow(Icons.timer, "Duration", "${widget.event.hours} Hours", textColor, subTextColor),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------- DESCRIPTION --------
            Text(
              "Description",
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: TextStyle(color: subTextColor, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 30),

            // -------- JOIN BUTTON --------
            if (!widget.event.completed)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.event.joined || _isJoining ? null : _joinEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.event.joined
                        ? Colors.grey
                        : Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.event.joined ? "Already Joined ✓" : "Join Event",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

            // -------- COMPLETED INFO --------
            if (widget.event.completed && widget.event.completedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.greenAccent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        "Event Completed!",
                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "+${widget.event.hours} Hours earned",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color textColor, Color subTextColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: textColor, fontSize: 15)),
          ],
        ),
      ],
    );
  }
}
