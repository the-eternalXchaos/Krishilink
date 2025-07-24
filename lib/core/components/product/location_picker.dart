import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String initialAddress;
  final Function(double latitude, double longitude, String address) onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialLatitude = 0,
    this.initialLongitude = 0,
    this.initialAddress = '',
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final RxBool isLoadingLocation = false.obs;
  final RxBool showMap = false.obs;
  
  GoogleMapController? mapController;
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    locationController.text = widget.initialAddress;
    latitudeController.text = widget.initialLatitude != 0 ? widget.initialLatitude.toString() : '';
    longitudeController.text = widget.initialLongitude != 0 ? widget.initialLongitude.toString() : '';
    
    if (widget.initialLatitude != 0 && widget.initialLongitude != 0) {
      currentLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
      showMap.value = true;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('error'.tr, 'location_services_disabled'.tr);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('error'.tr, 'location_permission_denied'.tr);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('error'.tr, 'location_permission_denied_forever'.tr);
        await Geolocator.openAppSettings();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final address = placemark != null
          ? '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}'
          : 'Unknown location';

      _updateLocation(position.latitude, position.longitude, address);
      
      Get.snackbar(
        'success'.tr,
        'current_location_fetched'.tr,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_get_location'.trParams({'error': e.toString()}),
      );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_location_to_search'.tr);
      return;
    }

    try {
      isLoadingLocation.value = true;
      final locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        _updateLocation(location.latitude, location.longitude, query);
        
        Get.snackbar(
          'success'.tr,
          'location_found'.tr,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('error'.tr, 'no_location_found'.tr);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_search_location'.trParams({'error': e.toString()}),
      );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void _updateLocation(double latitude, double longitude, String address) {
    setState(() {
      currentLocation = LatLng(latitude, longitude);
      locationController.text = address;
      latitudeController.text = latitude.toString();
      longitudeController.text = longitude.toString();
      showMap.value = true;
    });

    widget.onLocationSelected(latitude, longitude, address);

    // Update map camera if controller is available
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(currentLocation!),
      );
    }
  }

  void _onMapTap(LatLng position) async {
    try {
      isLoadingLocation.value = true;
      
      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final address = placemark != null
          ? '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}'
          : 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      _updateLocation(position.latitude, position.longitude, address);
    } catch (e) {
      // Fallback to coordinates if geocoding fails
      _updateLocation(
        position.latitude,
        position.longitude,
        'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
      );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Search Field
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: 'location_address'.tr,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchLocation(locationController.text),
                  tooltip: 'search_location'.tr,
                ),
                Obx(() => IconButton(
                  icon: isLoadingLocation.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  onPressed: isLoadingLocation.value ? null : _getCurrentLocation,
                  tooltip: 'use_current_location'.tr,
                )),
              ],
            ),
          ),
          maxLength: 100,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
        ),
        const SizedBox(height: 16),

        // Coordinates Display
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: latitudeController,
                decoration: InputDecoration(
                  labelText: 'latitude'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.place),
                ),
                readOnly: true,
                validator: (v) => (v == null || v.isEmpty) ? 'location_required'.tr : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: longitudeController,
                decoration: InputDecoration(
                  labelText: 'longitude'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.place),
                ),
                readOnly: true,
                validator: (v) => (v == null || v.isEmpty) ? 'location_required'.tr : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Map Toggle Button
        Obx(() => ElevatedButton.icon(
          icon: Icon(showMap.value ? Icons.map_outlined : Icons.map),
          label: Text(showMap.value ? 'hide_map'.tr : 'show_map'.tr),
          onPressed: currentLocation != null
              ? () => showMap.value = !showMap.value
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.blue.shade800,
          ),
        )),
        const SizedBox(height: 16),

        // Map Widget
        Obx(() => showMap.value && currentLocation != null
            ? Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    onTap: _onMapTap,
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: currentLocation!,
                        infoWindow: InfoWindow(
                          title: 'selected_location'.tr,
                          snippet: locationController.text,
                        ),
                      ),
                    },
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                  ),
                ),
              )
            : const SizedBox.shrink()),

        // Instructions
        if (currentLocation != null) ...[
          const SizedBox(height: 8),
          Text(
            'tap_map_to_select_location'.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    locationController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}