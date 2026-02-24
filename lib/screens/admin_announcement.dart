import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'data_service.dart';
import 'announcement_model.dart';

class AnnouncementScreens extends StatefulWidget {
  const AnnouncementScreens({super.key});

  @override
  State<AnnouncementScreens> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreens> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    await DataService.instance.fetchAnnouncements();
    if (mounted) setState(() => _isLoading = false);
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  // ---------------- POST ANNOUNCEMENT ----------------
  Future<void> _postAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill title and message")),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await DataService.instance
            .uploadAnnouncementImage(_selectedImage!);
      }

      await DataService.instance.addAnnouncement(
        titleController.text.trim(),
        messageController.text.trim(),
        imageUrl: imageUrl,
      );

      await DataService.instance.fetchAnnouncements();
      titleController.clear();
      messageController.clear();
      setState(() => _selectedImage = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Announcement posted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // ---------------- EDIT DIALOG ----------------
  Future<void> _showEditDialog(Announcement item) async {
    final editTitleController = TextEditingController(text: item.title);
    final editMessageController = TextEditingController(text: item.message);
    File? editImage;
    String? editImageUrl = item.imageUrl;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = Theme.of(context);
            final cardColor = theme.cardTheme.color;
            final fillColor = theme.inputDecorationTheme.fillColor;
            final textColor = theme.textTheme.bodyLarge?.color;
            final borderColor = theme.dividerColor;

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Edit Announcement",
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title field
                    TextField(
                      controller: editTitleController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration("Title"),
                    ),
                    const SizedBox(height: 12),
                    // Message field
                    TextField(
                      controller: editMessageController,
                      maxLines: 4,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration("Message"),
                    ),
                    const SizedBox(height: 12),
                    // Image picker
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            editImage = File(pickedFile.path);
                            editImageUrl = null;
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: editImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(editImage!,
                                    fit: BoxFit.cover),
                              )
                            : editImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(editImageUrl!,
                                        fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo,
                                          color: theme.inputDecorationTheme
                                              .hintStyle?.color,
                                          size: 32),
                                      const SizedBox(height: 6),
                                      Text("Tap to add image",
                                          style: TextStyle(
                                              color: theme
                                                  .inputDecorationTheme
                                                  .hintStyle
                                                  ?.color,
                                              fontSize: 12)),
                                    ],
                                  ),
                      ),
                    ),
                    if (editImage != null || editImageUrl != null)
                      TextButton.icon(
                        onPressed: () => setDialogState(() {
                          editImage = null;
                          editImageUrl = null;
                        }),
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent, size: 16),
                        label: const Text("Remove image",
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text("Cancel",
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color)),
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
                          if (editTitleController.text.trim().isEmpty ||
                              editMessageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please fill all fields")),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            String? finalImageUrl = editImageUrl;
                            if (editImage != null) {
                              finalImageUrl = await DataService.instance
                                  .uploadAnnouncementImage(editImage!);
                            }
                            await DataService.instance.updateAnnouncement(
                              item.id!,
                              editTitleController.text.trim(),
                              editMessageController.text.trim(),
                              imageUrl: finalImageUrl,
                            );
                            if (mounted) setState(() {});
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ Announcement updated"),
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
            );
          },
        );
      },
    );
  }

  // ---------------- DELETE CONFIRMATION ----------------
  Future<void> _confirmDelete(Announcement item) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Announcement",
          style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This cannot be undone.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel",
                style:
                    TextStyle(color: theme.textTheme.bodyMedium?.color)),
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

    if (confirmed == true && item.id != null) {
      try {
        await DataService.instance.deleteAnnouncement(item.id!);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🗑️ Announcement deleted"),
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
    final announcements = DataService.instance.announcements;
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final fillColor = theme.inputDecorationTheme.fillColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    final subTextColor = theme.textTheme.bodyMedium?.color;
    final hintColor = theme.inputDecorationTheme.hintStyle?.color;
    final borderColor = theme.dividerColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- NEW ANNOUNCEMENT FORM ----------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "New Announcement",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor),
                      decoration: inputDecoration("Title"),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      style: TextStyle(color: textColor),
                      decoration: inputDecoration("Message"),
                    ),
                    const SizedBox(height: 12),

                    // -------- IMAGE PICKER --------
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: Image.file(_selectedImage!,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: _removeImage,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close,
                                            color: Colors.white,
                                            size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 36, color: hintColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap to add image (optional)",
                                    style: TextStyle(
                                        color: hintColor, fontSize: 13),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isPosting ? null : _postAnnouncement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isPosting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Post Announcement",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ---------------- PAST ANNOUNCEMENTS ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Past Announcements",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${announcements.length} total",
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (announcements.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      "No announcements yet.\nPost one above!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subTextColor, fontSize: 15),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final item = announcements[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image (if any)
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
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + action buttons row
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _showEditDialog(item),
                                      icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blueAccent,
                                          size: 20),
                                      tooltip: "Edit",
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () =>
                                          _confirmDelete(item),
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20),
                                      tooltip: "Delete",
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Date
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: subTextColor?.withOpacity(0.6),
                                        size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.formattedDate,
                                      style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Message
                                Text(
                                  item.message,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- INPUT DECORATIONS ----------------
  InputDecoration inputDecoration(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.inputDecorationTheme.hintStyle,
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.inputDecorationTheme.hintStyle,
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
