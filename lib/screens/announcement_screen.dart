import 'package:flutter/material.dart';
import 'data_service.dart';
import 'announcement_model.dart';
import '../utils/responsive_helper.dart';

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
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;
    final subTextColor = theme.textTheme.bodyMedium?.color;
    final borderColor = theme.dividerColor;

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
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign_outlined,
                                  size: 64, color: subTextColor?.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                "No announcements yet",
                                style: TextStyle(
                                    fontSize: 16, color: subTextColor),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Pull down to refresh",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor?.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _buildAnnouncementList(
                      announcements, cardColor, textColor, subTextColor, borderColor),
            ),
    );
  }

  // ---------------- RESPONSIVE LIST / GRID ----------------
  Widget _buildAnnouncementList(
    List<Announcement> announcements,
    Color? cardColor,
    Color? textColor,
    Color? subTextColor,
    Color borderColor,
  ) {
    final cols = ResponsiveHelper.listGridColumns(context);
    final padding = ResponsiveHelper.padding(context);
    final imgHeight = ResponsiveHelper.imageHeight(context, 160);

    Widget buildCard(Announcement item) {
      return GestureDetector(
        onTap: () => _showAnnouncementDetail(context, item),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(
                    item.imageUrl!,
                    height: imgHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: imgHeight,
                        color: borderColor,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign,
                            size: 18, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.fontSize(context, 16),
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12,
                            color: subTextColor?.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedDate,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.fontSize(context, 12),
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.fontSize(context, 14),
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Tap to read more →",
                        style: TextStyle(
                          fontSize: ResponsiveHelper.fontSize(context, 12),
                          color: Colors.blueAccent.withOpacity(0.8),
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
    }

    if (cols == 1) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: announcements.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: buildCard(announcements[index]),
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: announcements.length,
      itemBuilder: (_, index) => buildCard(announcements[index]),
    );
  }

  // ---------------- ANNOUNCEMENT DETAIL BOTTOM SHEET ----------------
  void _showAnnouncementDetail(BuildContext context, Announcement item) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    final subTextColor = theme.textTheme.bodyMedium?.color;
    final borderColor = theme.dividerColor;

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
            color: cardColor,
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
                    color: borderColor,
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
                              color: textColor,
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
                            size: 14, color: subTextColor?.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          item.formattedDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: borderColor),
                    const SizedBox(height: 16),
                    // Full message
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
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
