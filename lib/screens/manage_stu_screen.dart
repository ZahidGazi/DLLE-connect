import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'user_model.dart';
import 'student_details.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Student> allStudents = [];
  List<Student> filteredStudents = [];

  // Filter States
  String searchQuery = "";
  String selectedSort = "None";
  String selectedCourse = "All";
  String selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    allStudents = DataService.instance.getAllStudents();
    _applyFilters(); // Initial load
  }

  // ---------- MASTER FILTER LOGIC ----------
  void _applyFilters() {
    setState(() {
      filteredStudents = allStudents.where((student) {
        // 1. Search Filter
        final matchesSearch = student.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            student.id.contains(searchQuery);

        // 2. Course Filter
        final matchesCourse = (selectedCourse == "All") ||
            (student.department == selectedCourse);

        // 3. Status Filter (120 Hours Rule)
        bool isCompleted = student.totalHours >= 120;
        final matchesStatus = (selectedStatus == "All") ||
            (selectedStatus == "Completed" && isCompleted) ||
            (selectedStatus == "Ongoing" && !isCompleted);

        return matchesSearch && matchesCourse && matchesStatus;
      }).toList();

      // 4. Sort Logic
      if (selectedSort == "Low to High Hours") {
        filteredStudents.sort((a, b) => a.totalHours.compareTo(b.totalHours));
      } else if (selectedSort == "High to Low Hours") {
        filteredStudents.sort((a, b) => b.totalHours.compareTo(a.totalHours));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get unique departments for the dropdown
    final courses = ["All", ...allStudents.map((s) => s.department).toSet()];

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
                onChanged: (val) {
                  searchQuery = val;
                  _applyFilters();
                },
              ),
            ),

            const SizedBox(height: 14),

            // ---------- FILTERS ROW ----------
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 1. SORT
                  PopupMenuButton<String>(
                    color: const Color(0xFF1F2933),
                    onSelected: (val) {
                      selectedSort = val;
                      _applyFilters();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: "None", child: Text("Default Sort", style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: "Low to High Hours", child: Text("Low to High Hours", style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: "High to Low Hours", child: Text("High to Low Hours", style: TextStyle(color: Colors.white))),
                    ],
                    child: filterChip("Sort", selectedSort != "None"),
                  ),

                  const SizedBox(width: 8),

                  // 2. COURSE FILTER
                  PopupMenuButton<String>(
                    color: const Color(0xFF1F2933),
                    onSelected: (val) {
                      selectedCourse = val;
                      _applyFilters();
                    },
                    itemBuilder: (_) => courses.map((course) => PopupMenuItem(
                      value: course,
                      child: Text(course, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    child: filterChip("Course: $selectedCourse", selectedCourse != "All"),
                  ),

                  const SizedBox(width: 8),

                  // 3. STATUS FILTER
                  PopupMenuButton<String>(
                    color: const Color(0xFF1F2933),
                    onSelected: (val) {
                      selectedStatus = val;
                      _applyFilters();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: "All", child: Text("All Status", style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: "Completed", child: Text("Completed", style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: "Ongoing", child: Text("Ongoing", style: TextStyle(color: Colors.white))),
                    ],
                    child: filterChip("Status: $selectedStatus", selectedStatus != "All"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---------- STUDENT LIST ----------
            Expanded(
              child: filteredStudents.isEmpty
                  ? const Center(
                child: Text(
                  "No students found",
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return studentCard(context, student);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI HELPER: FILTER CHIP ----------
  Widget filterChip(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blueAccent.withOpacity(0.2) : const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: Colors.blueAccent) : null,
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(color: isActive ? Colors.blueAccent : Colors.white70),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: isActive ? Colors.blueAccent : Colors.white54, size: 18),
        ],
      ),
    );
  }

  // ---------- STUDENT CARD WITH STATUS BAR ----------
  Widget studentCard(BuildContext context, Student student) {
    // ✅ Logic: 120 Hours = Completed
    bool isCompleted = student.totalHours >= 120;
    Color statusColor = isCompleted ? Colors.greenAccent : Colors.orangeAccent;
    String statusText = isCompleted ? "Completed" : "Ongoing";
    double progress = (student.totalHours / 120).clamp(0.0, 1.0); // 0.0 to 1.0

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailsScreen(student: student),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2933),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            // Row 1: Avatar + Name + ID + Arrow
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "ID: ${student.id} • ${student.department}",
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            // Row 2: Status Bar & Hours
            Row(
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const Spacer(),

                // Hours Text
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    children: [
                      TextSpan(
                        text: "${student.totalHours}",
                        style: TextStyle(
                          color: isCompleted ? Colors.green : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: " / 120 Hrs"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 3: Visual Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}