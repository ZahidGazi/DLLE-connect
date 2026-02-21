import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
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
  bool _isLoading = true;

  // Filter States
  String searchQuery = "";
  String selectedSort = "None";
  String selectedCourse = "All";
  String selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await DataService.instance.getAllStudents();
    if (mounted) {
      setState(() {
        allStudents = students;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  // ---------- MASTER FILTER LOGIC ----------
  void _applyFilters() {
    setState(() {
      filteredStudents = allStudents.where((student) {
        // 1. Search Filter
        final matchesSearch = student.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            student.identifier.toLowerCase().contains(searchQuery.toLowerCase());

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

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2933),
        title: const Text("Remove Student", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to remove ${student.fullName} from the system? This will also delete their event registrations.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DataService.instance.deleteStudent(student.identifier);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student removed successfully")),
          );
          _loadStudents();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  Widget padding({required Widget child, required EdgeInsets padding}) => Padding(padding: padding, child: child);

  @override
  Widget build(BuildContext context) {
    if (_isLoading && allStudents.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get unique departments for the dropdown
    final List<String> courses = ["All", ...allStudents.map((s) => s.department).toSet()];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Manage Students"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
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
                      PopupMenuItem<String>(value: "None", child: Text("Default Sort", style: TextStyle(color: Colors.white))),
                      PopupMenuItem<String>(value: "Low to High Hours", child: Text("Low to High Hours", style: TextStyle(color: Colors.white))),
                      PopupMenuItem<String>(value: "High to Low Hours", child: Text("High to Low Hours", style: TextStyle(color: Colors.white))),
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
                    itemBuilder: (_) => courses.map((course) => PopupMenuItem<String>(
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
                      PopupMenuItem<String>(value: "All", child: Text("All Status", style: TextStyle(color: Colors.white))),
                      PopupMenuItem<String>(value: "Completed", child: Text("Completed", style: TextStyle(color: Colors.white))),
                      PopupMenuItem<String>(value: "Ongoing", child: Text("Ongoing", style: TextStyle(color: Colors.white))),
                    ],
                    child: filterChip("Status: $selectedStatus", selectedStatus != "All"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---------- STUDENT LIST ----------
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
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
    bool isCompleted = student.totalHours >= 120;
    Color statusColor = isCompleted ? Colors.greenAccent : Colors.orangeAccent;
    String statusText = isCompleted ? "Completed" : "Ongoing";
    double progress = (student.totalHours / 120).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailsScreen(student: student),
          ),
        );
        if (result == true) {
          _loadStudents();
        }
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
                        student.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "ID: ${student.identifier} • ${student.department}",
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteStudent(student),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
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
