import 'package:flutter/material.dart';
import 'data_service.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    await DataService.instance.fetchCourses();
    if (mounted) setState(() => _isLoading = false);
  }

  // -------- ADD COURSE DIALOG --------
  Future<void> _showAddCourseDialog() async {
    final nameController = TextEditingController();
    final maxYearController = TextEditingController(text: '4');
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Add New Course",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogInput(
                nameController,
                "Course Name (e.g. B.Sc. Computer Science)",
              ),
              const SizedBox(height: 12),
              _dialogInput(
                maxYearController,
                "Max Academic Year (e.g. 3 or 4)",
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final maxYearText = maxYearController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Course name cannot be empty")),
                        );
                        return;
                      }

                      final maxYear = int.tryParse(maxYearText);
                      if (maxYear == null || maxYear < 1 || maxYear > 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Max year must be a number between 1 and 10")),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await DataService.instance
                            .addCourse(name, maxYear);
                        if (mounted) setState(() {});
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Course added successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Add",
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // -------- EDIT COURSE DIALOG --------
  Future<void> _showEditCourseDialog(Map<String, dynamic> course) async {
    final nameController =
        TextEditingController(text: course['name'] as String);
    final maxYearController =
        TextEditingController(text: (course['max_year'] as int).toString());
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Edit Course",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogInput(nameController, "Course Name"),
              const SizedBox(height: 12),
              _dialogInput(
                maxYearController,
                "Max Academic Year",
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final maxYearText = maxYearController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Course name cannot be empty")),
                        );
                        return;
                      }

                      final maxYear = int.tryParse(maxYearText);
                      if (maxYear == null || maxYear < 1 || maxYear > 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Max year must be a number between 1 and 10")),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await DataService.instance.updateCourse(
                          course['id'] as String,
                          name,
                          maxYear,
                        );
                        if (mounted) setState(() {});
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Course updated"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Save",
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // -------- DELETE COURSE --------
  Future<void> _confirmDelete(Map<String, dynamic> course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Course",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${course['name']}"?\n\nThis will affect students enrolled in this course.',
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DataService.instance.deleteCourse(course['id'] as String);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🗑️ Course deleted"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error: $e"),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = DataService.instance.courses;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Manage Courses"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCourseDialog,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Course",
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourses,
              child: courses.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school_outlined,
                                    size: 72,
                                    color: subTextColor.withOpacity(0.4)),
                                const SizedBox(height: 16),
                                Text(
                                  "No courses yet",
                                  style: TextStyle(
                                      color: subTextColor, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap the + button to add a course",
                                  style: TextStyle(
                                      color: subTextColor.withOpacity(0.6),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        final maxYear = course['max_year'] as int? ?? 4;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color:
                                    Colors.blueAccent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school,
                                  color: Colors.blueAccent, size: 24),
                            ),
                            title: Text(
                              course['name'] as String,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_view_week,
                                      size: 14,
                                      color: subTextColor.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Max $maxYear ${maxYear == 1 ? 'year' : 'years'}",
                                    style: TextStyle(
                                        color: subTextColor, fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  // Year badges
                                  ...List.generate(maxYear, (i) => i + 1)
                                      .map(
                                        (y) => Container(
                                          margin: const EdgeInsets.only(
                                              right: 4),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            "Y$y",
                                            style: const TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueAccent, size: 20),
                                  onPressed: () =>
                                      _showEditCourseDialog(course),
                                  tooltip: "Edit",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => _confirmDelete(course),
                                  tooltip: "Delete",
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _dialogInput(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
          color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0D1117)
            : const Color(0xFFF1F1F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
