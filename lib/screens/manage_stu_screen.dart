import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'student_details.dart';
import '../utils/responsive_helper.dart';

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

  void _applyFilters() {
    setState(() {
      filteredStudents = allStudents.where((student) {
        final matchesSearch =
            student.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                student.identifier
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase());
        final matchesCourse =
            (selectedCourse == "All") || (student.department == selectedCourse);
        bool isCompleted = student.totalHours >= 120;
        final matchesStatus = (selectedStatus == "All") ||
            (selectedStatus == "Completed" && isCompleted) ||
            (selectedStatus == "Ongoing" && !isCompleted);
        return matchesSearch && matchesCourse && matchesStatus;
      }).toList();

      if (selectedSort == "Low to High Hours") {
        filteredStudents.sort((a, b) => a.totalHours.compareTo(b.totalHours));
      } else if (selectedSort == "High to Low Hours") {
        filteredStudents.sort((a, b) => b.totalHours.compareTo(a.totalHours));
      }
    });
  }

  Future<void> _deleteStudent(Student student) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text("Remove Student",
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text(
          "Are you sure you want to remove ${student.fullName} from the system? "
          "This will also delete their event registrations.",
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove",
                style: TextStyle(color: Colors.redAccent)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;
    final subTextColor = theme.textTheme.bodyMedium?.color;
    final fillColor = theme.inputDecorationTheme.fillColor;
    final hintColor = theme.inputDecorationTheme.hintStyle?.color;

    if (_isLoading && allStudents.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final List<String> courses = [
      "All",
      ...allStudents.map((s) => s.department).toSet()
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                color: fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: hintColor),
                  hintText: "Search by name or ID",
                  hintStyle: TextStyle(color: hintColor),
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
                  PopupMenuButton<String>(
                    color: cardColor,
                    onSelected: (val) {
                      selectedSort = val;
                      _applyFilters();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                          value: "None",
                          child: Text("Default Sort",
                              style: TextStyle(color: textColor))),
                      PopupMenuItem<String>(
                          value: "Low to High Hours",
                          child: Text("Low to High Hours",
                              style: TextStyle(color: textColor))),
                      PopupMenuItem<String>(
                          value: "High to Low Hours",
                          child: Text("High to Low Hours",
                              style: TextStyle(color: textColor))),
                    ],
                    child: _filterChip(
                        "Sort", selectedSort != "None", cardColor, textColor),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    color: cardColor,
                    onSelected: (val) {
                      selectedCourse = val;
                      _applyFilters();
                    },
                    itemBuilder: (_) => courses
                        .map((course) => PopupMenuItem<String>(
                              value: course,
                              child: Text(course,
                                  style: TextStyle(color: textColor)),
                            ))
                        .toList(),
                    child: _filterChip("Course: $selectedCourse",
                        selectedCourse != "All", cardColor, textColor),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    color: cardColor,
                    onSelected: (val) {
                      selectedStatus = val;
                      _applyFilters();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                          value: "All",
                          child: Text("All Status",
                              style: TextStyle(color: textColor))),
                      PopupMenuItem<String>(
                          value: "Completed",
                          child: Text("Completed",
                              style: TextStyle(color: textColor))),
                      PopupMenuItem<String>(
                          value: "Ongoing",
                          child: Text("Ongoing",
                              style: TextStyle(color: textColor))),
                    ],
                    child: _filterChip("Status: $selectedStatus",
                        selectedStatus != "All", cardColor, textColor),
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
                      ? Center(
                          child: Text(
                            "No students found",
                            style: TextStyle(color: subTextColor),
                          ),
                        )
                      : _buildStudentList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(BuildContext context) {
    final cols = ResponsiveHelper.listGridColumns(context);
    if (cols == 1) {
      return ListView.builder(
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) => _studentCard(context, filteredStudents[index]),
      );
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) => _studentCard(context, filteredStudents[index]),
    );
  }

  Widget _filterChip(
      String text, bool isActive, Color? cardColor, Color? textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blueAccent.withOpacity(0.2)
            : cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: Colors.blueAccent) : null,
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
                color: isActive ? Colors.blueAccent : textColor),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down,
              color: isActive ? Colors.blueAccent : textColor?.withOpacity(0.6),
              size: 18),
        ],
      ),
    );
  }

  Widget _studentCard(BuildContext context, Student student) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;
    final subTextColor = theme.textTheme.bodyMedium?.color;
    final borderColor = theme.dividerColor;

    bool isCompleted = student.totalHours >= 120;
    Color statusColor =
        isCompleted ? Colors.greenAccent : Colors.orangeAccent;
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
        if (result == true) _loadStudents();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
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
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "ID: ${student.identifier} • ${student.department}",
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteStudent(student),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: subTextColor, size: 16),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    style: TextStyle(color: subTextColor, fontSize: 13),
                    children: [
                      TextSpan(
                        text: "${student.totalHours}",
                        style: TextStyle(
                          color: isCompleted ? Colors.green : textColor,
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
                backgroundColor: borderColor,
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
