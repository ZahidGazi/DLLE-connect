import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'user_model.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Student> allStudents = [];
  List<Student> filteredStudents = [];

  String selectedSort = "None";

  @override
  void initState() {
    super.initState();
    allStudents = DataService.instance.getAllStudents();
    filteredStudents = List.from(allStudents);
  }

  // ---------- SEARCH ----------
  void applySearch(String query) {
    setState(() {
      filteredStudents = allStudents.where((student) {
        return student.name
            .toLowerCase()
            .contains(query.toLowerCase()) ||
            student.id.contains(query);
      }).toList();
    });
  }

  // ---------- SORT ----------
  void sortStudents(String type) {
    setState(() {
      selectedSort = type;

      if (type == "Low to High Hours") {
        filteredStudents.sort(
                (a, b) => a.totalHours.compareTo(b.totalHours));
      } else if (type == "High to Low Hours") {
        filteredStudents.sort(
                (a, b) => b.totalHours.compareTo(a.totalHours));
      } else {
        filteredStudents = List.from(allStudents);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Manage Students"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ---------- SEARCH BAR ----------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.white54),
                  hintText: "Search by name or ID",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: applySearch,
              ),
            ),

            const SizedBox(height: 14),

            // ---------- SORT ----------
            Row(
              children: [
                PopupMenuButton<String>(
                  color: const Color(0xFF1F2933),
                  onSelected: sortStudents,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: "None", child: Text("Default")),
                    PopupMenuItem(
                        value: "Low to High Hours",
                        child: Text("Low to High Hours")),
                    PopupMenuItem(
                        value: "High to Low Hours",
                        child: Text("High to Low Hours")),
                  ],
                  child: filterChip("Sort"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------- STUDENT LIST ----------
            Expanded(
              child: filteredStudents.isEmpty
                  ? const Center(
                child: Text(
                  "No students found",
                  style:
                  TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];

                  return studentCard(student);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- FILTER CHIP ----------
  Widget filterChip(String text) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down,
              color: Colors.white54),
        ],
      ),
    );
  }

  // ---------- STUDENT CARD ----------
  Widget studentCard(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [

          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey,
                child:
                Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "ID: ${student.id}",
                      style: const TextStyle(
                          color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                student.department,
                style:
                const TextStyle(color: Colors.white70),
              ),
              Text(
                "${student.totalHours} Hours",
                style:
                const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
