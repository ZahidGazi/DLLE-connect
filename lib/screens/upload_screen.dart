import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'data_service.dart';
import 'event_model.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  EventItem? selectedEvent;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  // ---------------- IMAGE PICKER ----------------
  Future<void> pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // ---------------- GPS LOCATION ----------------
  Future<Position> getLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw "Location services disabled";
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // ---------------- SUBMIT ----------------
  Future<void> submit() async {
    if (selectedEvent == null ||
        selectedImage == null ||
        nameController.text.isEmpty ||
        idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    try {
      // ✅ Use your existing GPS logic
      Position position = await getLocation();

      String locationText =
          "Lat: ${position.latitude}, Lng: ${position.longitude}";

      // Optional: log location (for validation/debug)
      debugPrint("Upload Location: $locationText");

      // ✅ Mark event as completed
      DataService.instance.completeEvent(selectedEvent!, locationText);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event uploaded successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final joinedEvents = DataService.instance.joinedEvents;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          "Upload Event Proof",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -------- EVENT DROPDOWN --------
            DropdownButtonFormField<EventItem>(
              dropdownColor: const Color(0xFF1F2933),
              decoration: inputDecoration("Select Event"),
              items: joinedEvents.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.title,
                      style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEvent = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // -------- NAME --------
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: inputDecoration("Student Name"),
            ),

            const SizedBox(height: 14),

            // -------- ID --------
            TextField(
              controller: idController,
              style: const TextStyle(color: Colors.white),
              decoration: inputDecoration("Student ID"),
            ),

            const SizedBox(height: 20),

            const Text(
              "Participation Proof",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // -------- IMAGE PICKER --------
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: selectedImage == null
                    ? const Center(
                  child: Icon(Icons.camera_alt,
                      size: 40, color: Colors.black54),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "Upload Image\nTap to select image",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),

            const SizedBox(height: 30),

            // -------- UPLOAD BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "Upload",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1F2933),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
