import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';

class EventParticipationScreen extends StatefulWidget {
  final EventItem event;

  const EventParticipationScreen({super.key, required this.event});

  @override
  State<EventParticipationScreen> createState() => _EventParticipationScreenState();
}

class _EventParticipationScreenState extends State<EventParticipationScreen> {
  String _selectedFilter = "All"; // Options: All, Registered, Completed
  List<Student> _allStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final students = await DataService.instance.getAllStudents();
    setState(() {
      _allStudents = students;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardColor = Theme.of(context).cardTheme.color ?? const Color(0xFF1F2933);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter students who have at least JOINED this event
    List<Student> participants = _allStudents.where((s) {
      return s.joinedEvents.contains(widget.event.title);
    }).toList();

    // Apply Status Filter
    List<Student> filteredList = participants.where((s) {
      bool isCompleted = s.completedEvents.contains(widget.event.title);

      if (_selectedFilter == "Completed") return isCompleted;
      if (_selectedFilter == "Registered") return !isCompleted;
      return true; // "All"
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.event.title),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: cardColor,
                value: _selectedFilter,
                icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
                style: TextStyle(color: textColor),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilter = newValue!;
                  });
                },
                items: <String>['All', 'Registered', 'Completed']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Participants: ${participants.length}",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Showing: ${filteredList.length}",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: subTextColor.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          "No students found",
                          style: TextStyle(color: subTextColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final student = filteredList[index];
                      final isCompleted = student.completedEvents.contains(widget.event.title);
                      return _buildParticipantCard(student, isCompleted, cardColor, textColor, subTextColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Student student, bool isCompleted, Color cardColor, Color textColor, Color subTextColor) {
    final statusText = isCompleted ? "Completed" : "Registered";
    final statusColor = isCompleted ? Colors.greenAccent : subTextColor;
    final borderColor = isCompleted ? Colors.green.withOpacity(0.5) : subTextColor.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${student.identifier}",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.how_to_reg,
                  color: statusColor,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
