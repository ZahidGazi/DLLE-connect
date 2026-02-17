import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Add this to pubspec if missing
import 'data_service.dart';
import 'event_model.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  EventItem? _selectedEvent;
  bool _isLocating = false;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
  }

  /// ✅ FIXED PERMISSION LOGIC FOR ANDROID 13+
  Future<void> _requestAllPermissions() async {
    // 1. Request Location & Camera (Standard)
    await [
      Permission.location,
      Permission.camera,
      Permission.accessMediaLocation, // Critical for Jiotag
    ].request();

    // 2. Handle Storage Logic based on Android Version
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ uses 'Photos' permission
        await Permission.photos.request();
      } else {
        // Android 12 and below uses 'Storage' permission
        await Permission.storage.request();
      }
    }
  }

  Future<void> _pickAndValidateImage() async {
    if (_selectedEvent == null) {
      _showError("Please select an event first.");
      return;
    }

    try {
      final picker = ImagePicker();
      // ✅ Fix: Request lower quality to prevent memory crashes
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 50
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _statusMessage = "Analyzing Location Data...";
          _isLocating = true;
        });

        await _validateLocationLogic(File(pickedFile.path));
      }
    } catch (e) {
      _showError("Error picking image: $e");
    }
  }

  Future<void> _validateLocationLogic(File imageFile) async {
    try {
      // 1. Get Student Current Location
      Position studentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Get Photo GeoTag
      final exif = await Exif.fromPath(imageFile.path);
      final latLong = await exif.getLatLong();
      await exif.close();

      // ✅ DETAILED ERROR MSG IF MISSING
      if (latLong == null) {
        throw """
        No GeoTag found in photo! 
        1. Open Camera App > Settings
        2. Turn ON 'Location tags' or 'Save location'
        3. Take a NEW photo and try again.
        """;
      }

      // 3. Get Event Location
      double eventLat = _selectedEvent!.latitude;
      double eventLng = _selectedEvent!.longitude;

      // 4. Calculate Distances
      double distStudentToEvent = Geolocator.distanceBetween(
          studentPos.latitude, studentPos.longitude,
          eventLat, eventLng
      );

      double distPhotoToEvent = Geolocator.distanceBetween(
          latLong.latitude, latLong.longitude,
          eventLat, eventLng
      );

      // Threshold: 500m (Increased to prevent false negatives during testing)
      double limit = 500.0;

      if (distStudentToEvent > limit) {
        throw "You are too far from the event! (${distStudentToEvent.toStringAsFixed(0)}m away)";
      }

      if (distPhotoToEvent > limit) {
        throw "Photo taken too far from event! (${distPhotoToEvent.toStringAsFixed(0)}m away)";
      }

      // SUCCESS
      setState(() {
        _isLocating = false;
        _statusMessage = "✅ Verified! Upload Successful.";
      });
      _showSuccess("Event Verified Successfully!");

      if (!DataService.instance.completedEvents.contains(_selectedEvent)) {
        DataService.instance.completedEvents.add(_selectedEvent!);
      }

    } catch (e) {
      setState(() {
        _isLocating = false;
        _selectedImage = null;
        _statusMessage = "Validation Failed ❌";
      });
      // Show the full error on screen so you can debug it
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Validation Error"),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
          ],
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = DataService.instance.events;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Upload Proof"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<EventItem>(
              decoration: const InputDecoration(labelText: "Select Event"),
              items: events.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.title),
              )).toList(),
              onChanged: (val) => setState(() {
                _selectedEvent = val;
                _selectedImage = null;
                _statusMessage = "";
              }),
              dropdownColor: Theme.of(context).cardTheme.color,
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickAndValidateImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40),
                    SizedBox(height: 8),
                    Text("Tap to pick GeoTagged Photo"),
                  ],
                )
                    : Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),

            if (_isLocating)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains("✅") ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}