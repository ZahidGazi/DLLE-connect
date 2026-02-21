import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'user_model.dart';

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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Filter students who have at least JOINED this event
    List<Student> participants = _allStudents.where((s) {
      return s.joinedEvents.contains(widget.event.title);
    }).toList();

    // 3. Apply Status Filter
    List<Student> filteredList = participants.where((s) {
      bool isCompleted = s.completedEvents.contains(widget.event.title);

      if (_selectedFilter == "Completed") return isCompleted;
      if (_selectedFilter == "Registered") return !isCompleted;
      return true; // "All"
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF1F2933),
                value: _selectedFilter,
                icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
                style: const TextStyle(color: Colors.white),
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
            color: const Color(0xFF020202),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "Total Participants: ${participants.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                Text(
                    "Showing: ${filteredList.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
              child: Text(
                "No students found",
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final student = filteredList[index];
                final isCompleted = student.completedEvents.contains(widget.event.title);
                return _buildParticipantCard(student, isCompleted);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Student student, bool isCompleted) {
    final statusText = isCompleted ? "Completed" : "Registered";
    final statusColor = isCompleted ? Colors.greenAccent : Colors.white70;
    final borderColor = isCompleted ? Colors.green.withOpacity(0.5) : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${student.identifier}",
                  style: const TextStyle(
                    color: Colors.white54,
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
