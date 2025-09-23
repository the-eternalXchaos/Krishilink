import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:krishi_link/core/lottie/popup_service.dart'; // Import PopupService
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String initialAddress;
  final Function(double latitude, double longitude, String address)
  onLocationSelected;

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

class _LocationPickerState extends State<LocationPicker>
    with TickerProviderStateMixin {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final RxBool isLoadingLocation = false.obs;
  final RxBool showMap = false.obs;
  final RxBool hasValidLocation = false.obs;

  GoogleMapController? mapController;
  LatLng? currentLocation;
  late AnimationController _mapAnimationController;
  late Animation<double> _mapAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocation();
  }

  void _initializeAnimations() {
    _mapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _mapAnimation = CurvedAnimation(
      parent: _mapAnimationController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeLocation() {
    locationController.text = widget.initialAddress;
    latitudeController.text =
        widget.initialLatitude != 0
            ? widget.initialLatitude.toStringAsFixed(6)
            : '';
    longitudeController.text =
        widget.initialLongitude != 0
            ? widget.initialLongitude.toStringAsFixed(6)
            : '';

    if (widget.initialLatitude != 0 && widget.initialLongitude != 0) {
      currentLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
      showMap.value = true;
      hasValidLocation.value = true;
      _mapAnimationController.forward();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      _pulseController.repeat(reverse: true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        PopupService.showSnackbar(
          type: PopupType.error,
          message: 'location_services_disabled'.tr,
          title: 'Error',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          PopupService.showSnackbar(
            type: PopupType.error,
            message: 'location_permission_denied'.tr,
            title: 'Error',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        PopupService.showSnackbar(
          type: PopupType.error,
          message: 'location_permission_denied_forever'.tr,
          title: 'Error',
        );
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final address =
          placemark != null
              ? '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}'
              : 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      _updateLocation(position.latitude, position.longitude, address);
      PopupService.showSnackbar(
        title: 'location_fetched'.tr,
        type: PopupType.success,
        message: 'current_location_fetched'.tr,
      );
    } catch (e) {
      PopupService.showSnackbar(
        type: PopupType.error,
        message: 'failed_to_get_location'.trParams({'error': e.toString()}),
        title: 'Error',
      );
    } finally {
      isLoadingLocation.value = false;
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      PopupService.showSnackbar(
        type: PopupType.error,
        message: 'enter_location_to_search'.tr,
        title: 'Error',
      );
      return;
    }

    try {
      isLoadingLocation.value = true;
      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;
        _updateLocation(location.latitude, location.longitude, query);
        PopupService.success('location_found'.tr);
      } else {
        PopupService.error('no_location_found'.tr, title: 'Error');
      }
    } catch (e) {
      PopupService.error(
        'failed_to_search_location'.trParams({'error': e.toString()}),
        title: 'Error',
      );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> _searchOnGoogleMaps() async {
    if (currentLocation == null ||
        currentLocation!.latitude == 0 ||
        currentLocation!.longitude == 0) {
      PopupService.error(
        'Please select a valid location before searching.',
        title: 'Error',
      );
      return;
    }

    final latitude = currentLocation!.latitude;
    final longitude = currentLocation!.longitude;
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      PopupService.error('Invalid coordinates selected.', title: 'Error');
      return;
    }

    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final uri = Uri.parse(mapsUrl);
    debugPrint('🔄 [LocationPicker] Launching Google Maps with URL: $mapsUrl');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        PopupService.success('Opened Google Maps successfully.');
      } else {
        PopupService.error('Could not open Google Maps.', title: 'Error');
      }
    } catch (e) {
      PopupService.error('Failed to open Google Maps: $e', title: 'Error');
    }
  }

  void _updateLocation(double latitude, double longitude, String address) {
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      PopupService.error(
        'Invalid coordinates: Latitude must be between -90 and 90, Longitude between -180 and 180.',
        title: 'Error',
      );
      return;
    }

    setState(() {
      currentLocation = LatLng(latitude, longitude);
      locationController.text = address;
      latitudeController.text = latitude.toStringAsFixed(6);
      longitudeController.text = longitude.toStringAsFixed(6);
      hasValidLocation.value = true;
      if (!showMap.value) {
        showMap.value = true;
        _mapAnimationController.forward();
      }
    });

    widget.onLocationSelected(latitude, longitude, address);
    debugPrint(
      '🔄 [LocationPicker] Updated location: $latitude, $longitude, $address',
    );

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation!, 15),
      );
    }
  }

  void _onMapTap(LatLng position) async {
    try {
      isLoadingLocation.value = true;
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final address =
          placemark != null
              ? '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}'
              : 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      _updateLocation(position.latitude, position.longitude, address);
    } catch (e) {
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationSearchField(colorScheme),
          const SizedBox(height: 20),
          _buildCoordinatesSection(colorScheme),
          const SizedBox(height: 20),
          _buildMapControls(colorScheme),
          const SizedBox(height: 16),
          _buildMapSection(colorScheme),
          _buildInstructions(context),
        ],
      ),
    );
  }

  Widget _buildLocationSearchField(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: locationController,
        decoration: InputDecoration(
          labelText: 'location_address'.tr,
          hintText: 'Enter address or place name',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.blue,
              size: 20,
            ),
          ),
          suffixIcon: _buildLocationActions(),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          errorStyle: const TextStyle(height: 0, color: Colors.transparent),
        ),
        maxLength: 100,
        onFieldSubmitted: (value) => _searchLocation(value),
      ),
    );
  }

  Widget _buildLocationActions() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Address Search Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _searchLocation(locationController.text),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Google Maps Search Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _searchOnGoogleMaps,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Current Location Button
          Obx(
            () => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: isLoadingLocation.value ? null : _getCurrentLocation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale:
                            isLoadingLocation.value
                                ? _pulseAnimation.value
                                : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child:
                              isLoadingLocation.value
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.my_location,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.explore_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'coordinates'.tr,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCoordinateField(
                  controller: latitudeController,
                  label: 'latitude'.tr,
                  icon: Icons.place_outlined,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCoordinateField(
                  controller: longitudeController,
                  label: 'longitude'.tr,
                  icon: Icons.place_outlined,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: const TextStyle(fontSize: 12),
        errorStyle: const TextStyle(height: 0, color: Colors.transparent),
      ),
      readOnly: true,
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildMapControls(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton.icon(
                icon: Icon(
                  showMap.value ? Icons.map_outlined : Icons.map,
                  size: 20,
                ),
                label: Text(
                  showMap.value ? 'hide_map'.tr : 'show_map'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed:
                    hasValidLocation.value
                        ? () {
                          showMap.value = !showMap.value;
                          if (showMap.value) {
                            _mapAnimationController.forward();
                          } else {
                            _mapAnimationController.reverse();
                          }
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      showMap.value
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.primaryContainer,
                  foregroundColor:
                      showMap.value
                          ? colorScheme.primary
                          : colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child:
                hasValidLocation.value
                    ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                    )
                    : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_disabled,
                        color: colorScheme.outline,
                        size: 24,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(ColorScheme colorScheme) {
    return Obx(
      () => AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child:
            showMap.value && currentLocation != null
                ? FadeTransition(
                  opacity: _mapAnimation,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          GoogleMap(
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
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange,
                                ),
                                infoWindow: InfoWindow(
                                  title: 'selected_location'.tr,
                                  snippet: locationController.text,
                                ),
                              ),
                            },
                            mapType: MapType.normal,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            compassEnabled: true,
                            mapToolbarEnabled: false,
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Column(
                              children: [
                                _buildMapButton(
                                  icon: Icons.add,
                                  onTap:
                                      () => mapController?.animateCamera(
                                        CameraUpdate.zoomIn(),
                                      ),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(height: 8),
                                _buildMapButton(
                                  icon: Icons.remove,
                                  onTap:
                                      () => mapController?.animateCamera(
                                        CameraUpdate.zoomOut(),
                                      ),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                          ),
                          Obx(
                            () =>
                                isLoadingLocation.value
                                    ? Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Obx(
      () => AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child:
            hasValidLocation.value
                ? Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'tap_map_to_select_location'.tr,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }

  @override
  void dispose() {
    _mapAnimationController.dispose();
    _pulseController.dispose();
    locationController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
