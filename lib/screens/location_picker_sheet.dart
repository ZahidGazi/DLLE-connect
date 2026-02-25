import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result returned when the user taps "Save" in the location picker.
class LocationResult {
  final String displayAddress;
  final double latitude;
  final double longitude;

  const LocationResult({
    required this.displayAddress,
    required this.latitude,
    required this.longitude,
  });
}

/// Shows the location picker as a full-height modal bottom sheet.
/// Returns a [LocationResult] or null if the user dismissed without saving.
Future<LocationResult?> showLocationPicker(
  BuildContext context, {
  double? initialLat,
  double? initialLng,
  String? initialAddress,
}) {
  return showModalBottomSheet<LocationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LocationPickerSheet(
      initialLat: initialLat,
      initialLng: initialLng,
      initialAddress: initialAddress,
    ),
  );
}

class LocationPickerSheet extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const LocationPickerSheet({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  // ── Map ──────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  static final LatLng _defaultCenter = LatLng(19.0760, 72.8777); // Mumbai

  late LatLng _centerPosition;
  bool _isReverseGeocoding = false;

  // ── Search ───────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  List<String> _searchLabels = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  // ── Reverse geocode debounce ─────────────────────────────────────────────
  Timer? _geocodeDebounce;

  // ── Display address ──────────────────────────────────────────────────────
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _centerPosition = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultCenter;

    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _addressController.text = widget.initialAddress!;
    } else {
      _reverseGeocode(_centerPosition);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Reverse geocode ──────────────────────────────────────────────────────
  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.name != null && p.name!.isNotEmpty && p.name != p.street)
            p.name!,
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
          if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        _addressController.text = parts.join(', ');
      }
    } catch (_) {
      // Silently fail — user can type address manually
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  // ── Address search via geocoding package ─────────────────────────────────
  Future<void> _fetchSuggestions(String input) async {
    if (input.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _searchLabels = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(input);
      if (!mounted) return;

      // For each location, reverse-geocode to get a human-readable label
      final labels = <String>[];
      for (final loc in locations.take(5)) {
        try {
          final placemarks = await placemarkFromCoordinates(
              loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = <String>[
              if (p.name != null && p.name!.isNotEmpty) p.name!,
              if (p.street != null && p.street!.isNotEmpty &&
                  p.street != p.name)
                p.street!,
              if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
              if (p.administrativeArea != null &&
                  p.administrativeArea!.isNotEmpty)
                p.administrativeArea!,
              if (p.country != null && p.country!.isNotEmpty) p.country!,
            ];
            labels.add(parts.join(', '));
          } else {
            labels.add(
                '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}');
          }
        } catch (_) {
          labels.add(
              '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}');
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = locations.take(5).toList();
          _searchLabels = labels;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searchLabels = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectResult(int index) async {
    FocusScope.of(context).unfocus();
    final loc = _searchResults[index];
    final label = _searchLabels[index];

    _searchController.text = label;
    setState(() {
      _searchResults = [];
      _searchLabels = [];
    });

    final newPos = LatLng(loc.latitude, loc.longitude);
    _centerPosition = newPos;
    _addressController.text = label;

    _mapController.move(newPos, 16);
  }

  // ── Current location ─────────────────────────────────────────────────────
  Future<void> _goToCurrentLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final newPos = LatLng(position.latitude, position.longitude);
      _centerPosition = newPos;

      _mapController.move(newPos, 16);
      await _reverseGeocode(newPos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  // ── Map position changed → reverse geocode (debounced) ───────────────────
  void _onPositionChanged(MapPosition position, bool hasGesture) {
    if (position.center != null) {
      _centerPosition = position.center!;
    }
    // Cancel any pending geocode while user is still dragging
    _geocodeDebounce?.cancel();
    if (hasGesture) {
      _geocodeDebounce = Timer(const Duration(milliseconds: 600), () {
        _reverseGeocode(_centerPosition);
      });
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  void _save() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a location')),
      );
      return;
    }
    Navigator.of(context).pop(
      LocationResult(
        displayAddress: address,
        latitude: _centerPosition.latitude,
        longitude: _centerPosition.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        theme.cardTheme.color ?? const Color(0xFF1F2933);
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor =
        theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final inputFillColor =
        theme.inputDecorationTheme.fillColor ?? const Color(0xFF1F2933);

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Title ────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Choose Location',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: subTextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ── Search bar ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search address...',
                    hintStyle:
                        TextStyle(color: subTextColor.withOpacity(0.6)),
                    filled: true,
                    fillColor: inputFillColor,
                    prefixIcon:
                        Icon(Icons.search, color: subTextColor),
                    suffixIcon: _isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: subTextColor,
                              ),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: subTextColor, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _searchLabels = [];
                                  });
                                },
                              )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 600),
                      () => _fetchSuggestions(value),
                    );
                    setState(() {});
                  },
                ),
              ),

              // ── Search results ───────────────────────────────────────
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: subTextColor.withOpacity(0.15),
                    ),
                    itemBuilder: (_, i) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined,
                            color: Colors.blueAccent, size: 18),
                        title: Text(
                          _searchLabels[i],
                          style: TextStyle(color: textColor, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectResult(i),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 10),

              // ── Map ──────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _centerPosition,
                            initialZoom: 15,
                            onPositionChanged: _onPositionChanged,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.dlle.connect',
                            ),
                          ],
                        ),

                        // Fixed center pin
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_pin,
                                color: Colors.redAccent,
                                size: 44,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black38,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              // Offset the pin so its tip is at center
                              const SizedBox(height: 44),
                            ],
                          ),
                        ),

                        // Current location FAB
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: FloatingActionButton.small(
                            heroTag: 'location_fab',
                            backgroundColor: Colors.white,
                            onPressed: _goToCurrentLocation,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),

                        // Geocoding indicator
                        if (_isReverseGeocoding)
                          Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Getting address...',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Display address ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display address:',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _addressController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Address will appear here...',
                        hintStyle: TextStyle(
                            color: subTextColor.withOpacity(0.5),
                            fontSize: 13),
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        suffixIcon: Icon(Icons.edit,
                            size: 16, color: subTextColor.withOpacity(0.5)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Save button ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
