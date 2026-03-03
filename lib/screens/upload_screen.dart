import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'data_service.dart';
import 'event_model.dart';
import '../services/Certificate_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  EventItem? _selectedEvent;
  EventItem? _completedEvent; // holds the event after successful submission
  bool _isSubmitting = false;
  bool _isGeneratingCert = false;
  String _statusMessage = "";
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
    _refreshEvents();
  }

  /// Refresh events from DB so joined/completed flags are up-to-date
  Future<void> _refreshEvents() async {
    await DataService.instance.fetchEvents();
    if (mounted) setState(() {});
  }

  /// Request all required permissions on startup (Android 13+ aware)
  Future<void> _requestAllPermissions() async {
    await [
      Permission.location,
      Permission.camera,
      Permission.accessMediaLocation,
    ].request();

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        await Permission.photos.request();
      } else {
        await Permission.storage.request();
      }
    }
  }

  /// Step 1 — Pick a proof photo from gallery (no validation yet)
  Future<void> _pickImage() async {
    if (_selectedEvent == null) {
      _showSnack("Please select an event first.", isError: true);
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _statusMessage =
              "Photo selected. Tap Submit to verify your location.";
          _isSuccess = false;
        });
      }
    } catch (e) {
      _showSnack("Error picking image: $e", isError: true);
    }
  }

  /// Step 2 — Submit: get precise GPS, check 500m radius, mark completed
  Future<void> _submitProof() async {
    if (_selectedEvent == null) {
      _showSnack("Please select an event.", isError: true);
      return;
    }
    if (_selectedImage == null) {
      _showSnack("Please select a proof photo first.", isError: true);
      return;
    }
    if (_selectedEvent!.completed) {
      _showSnack("You have already completed this event.", isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = "Getting your precise location...";
      _isSuccess = false;
    });

    try {
      // 1. Ensure location permission is granted
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          throw "Location permission denied. Please enable it in Settings.";
        }
      }

      // 2. Get student's current GPS position
      final Position studentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Calculate distance to event location
      final double eventLat = _selectedEvent!.latitude;
      final double eventLng = _selectedEvent!.longitude;

      final double distance = Geolocator.distanceBetween(
        studentPos.latitude,
        studentPos.longitude,
        eventLat,
        eventLng,
      );

      const double radiusLimit = 500.0; // metres

      if (distance > radiusLimit) {
        throw "You are ${distance.toStringAsFixed(0)}m away from the event.\n"
            "You must be within ${radiusLimit.toStringAsFixed(0)}m to submit proof.";
      }

      // 4. Mark event as completed in DB + reward hours
      setState(() => _statusMessage = "Saving your completion...");

      final int rewardedHours = _selectedEvent!.hours;

      await DataService.instance.completeEvent(
        _selectedEvent!,
        DataService.instance.studentId,
      );

      // 5. Refresh events list so UI reflects completed state
      await DataService.instance.fetchEvents();

      if (!mounted) return;

      // Save reference before resetting so certificate can be generated
      final justCompleted = _selectedEvent!;

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
        _completedEvent = justCompleted;
        _statusMessage =
            "✅ Verified! You were ${distance.toStringAsFixed(0)}m from the event.\n"
            "Event marked as completed — $rewardedHours hour(s) rewarded!";
        // Reset selection so the completed event disappears from dropdown
        _selectedEvent = null;
        _selectedImage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSuccess = false;
        _statusMessage = e.toString();
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Only show: joined + not yet completed + not expired
    final events = DataService.instance.events
        .where((e) =>
            e.joined &&
            !e.completed &&
            (e.eventExpiryDate == null || e.eventExpiryDate!.isAfter(now)))
        .toList();

    // Ensure _selectedEvent still exists in the filtered list (by ID)
    if (_selectedEvent != null) {
      final match = events.cast<EventItem?>().firstWhere(
        (e) => e?.id == _selectedEvent?.id,
        orElse: () => null,
      );
      if (match == null) {
        // Selected event no longer in list (completed / expired / removed)
        _selectedEvent = null;
        _selectedImage = null;
      } else {
        _selectedEvent = match;
      }
    }

    final bool canSubmit =
        _selectedEvent != null && _selectedImage != null && !_isSubmitting;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Upload Proof"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event selector
                  DropdownButtonFormField<EventItem>(
                    decoration:
                        const InputDecoration(labelText: "Select Event"),
                    initialValue: _selectedEvent,
                    items: events
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.title),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() {
                      _selectedEvent = val;
                      _selectedImage = null;
                      _statusMessage = "";
                      _isSuccess = false;
                    }),
                    dropdownColor: Theme.of(context).cardTheme.color,
                  ),

                  const SizedBox(height: 20),

                  // Image picker area
                  GestureDetector(
                    onTap: _isSubmitting ? null : _pickImage,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 48,
                                    color: Theme.of(context)
                                        .iconTheme
                                        .color
                                        ?.withOpacity(0.5)),
                                const SizedBox(height: 10),
                                Text(
                                  "Tap to select proof photo",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 220,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status message box
                  if (_statusMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? Colors.green.withOpacity(0.1)
                            : _isSubmitting
                                ? Colors.blue.withOpacity(0.1)
                                : _statusMessage.startsWith("Photo selected")
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isSuccess
                              ? Colors.green.withOpacity(0.4)
                              : _isSubmitting
                                  ? Colors.blue.withOpacity(0.4)
                                  : _statusMessage
                                          .startsWith("Photo selected")
                                      ? Colors.orange.withOpacity(0.4)
                                      : Colors.red.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSubmitting)
                            const Padding(
                              padding: EdgeInsets.only(right: 10, top: 2),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _isSuccess
                                    ? Colors.green
                                    : _isSubmitting
                                        ? Colors.blue
                                        : _statusMessage
                                                .startsWith("Photo selected")
                                            ? Colors.orange.shade700
                                            : Colors.redAccent,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Certificate download button (shown after success) ──
                  if (_isSuccess && _completedEvent != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your certificate is ready!",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Download your Certificate of Participation",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _isGeneratingCert
                                  ? null
                                  : () async {
                                      setState(
                                          () => _isGeneratingCert = true);
                                      try {
                                        await CertificateService
                                            .generateAndDownload(
                                                _completedEvent!);
                                      } catch (e) {
                                        if (mounted) {
                                          _showSnack(
                                              "Error generating certificate: $e",
                                              isError: true);
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() =>
                                              _isGeneratingCert = false);
                                        }
                                      }
                                    },
                              icon: _isGeneratingCert
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.download_rounded),
                              label: Text(
                                _isGeneratingCert
                                    ? "Generating..."
                                    : "Download Certificate",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Empty state
                  if (events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          "No active joined events to upload proof for.",
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Fixed Submit button at bottom ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? _submitProof : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting ? "Verifying..." : "Submit Proof",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
