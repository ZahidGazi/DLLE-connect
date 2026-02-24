import 'package:flutter/material.dart';
import 'data_service.dart';
import 'announcement_model.dart';

class StudentAnnouncementScreen extends StatefulWidget {
  const StudentAnnouncementScreen({super.key});

  @override
  State<StudentAnnouncementScreen> createState() =>
      _StudentAnnouncementScreenState();
}

class _StudentAnnouncementScreenState
    extends State<StudentAnnouncementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (mounted) setState(() => _isLoading = true);
    await DataService.instance.fetchAnnouncements();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final announcements = DataService.instance.announcements;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnnouncements,
              child: announcements.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign_outlined,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No announcements yet",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Pull down to refresh",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final item = announcements[index];

                        return GestureDetector(
                          onTap: () => _showAnnouncementDetail(
                              context, item, isDark),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0C2237)
                                  : const Color(0xFFD6DDE6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.black12,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // -------- IMAGE (if any) --------
                                if (item.imageUrl != null &&
                                    item.imageUrl!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(14)),
                                    child: Image.network(
                                      item.imageUrl!,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                      loadingBuilder:
                                          (_, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          height: 160,
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black12,
                                          child: const Center(
                                            child:
                                                CircularProgressIndicator(
                                                    strokeWidth: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // -------- TITLE --------
                                      Row(
                                        children: [
                                          const Icon(Icons.campaign,
                                              size: 18,
                                              color: Colors.blueAccent),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // -------- DATE --------
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 12,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // -------- MESSAGE PREVIEW --------
                                      Text(
                                        item.message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // -------- TAP TO READ MORE --------
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          "Tap to read more →",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueAccent
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

  // ---------------- ANNOUNCEMENT DETAIL BOTTOM SHEET ----------------
  void _showAnnouncementDetail(
      BuildContext context, Announcement item, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2933) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // -------- IMAGE --------
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        const Icon(Icons.campaign,
                            color: Colors.blueAccent, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14,
                            color: isDark
                                ? Colors.white38
                                : Colors.black38),
                        const SizedBox(width: 6),
                        Text(
                          item.formattedDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(
                        color: isDark ? Colors.white12 : Colors.black12),
                    const SizedBox(height: 16),
                    // Full message
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isDark ? Colors.white70 : Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
