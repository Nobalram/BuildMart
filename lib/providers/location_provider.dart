import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Fetches the device's current city once per app session (fast,
/// cheap, and avoids re-geocoding on every rebuild). Falls back to
/// "Set location" if permission/service isn't available, rather
/// than showing a wrong or stale city name.
final currentCityProvider = FutureProvider<String>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'Set location';
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Set location';
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );

    final geocoding = Geocoding();
    final placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) return 'Set location';
    final place = placemarks.first;
    return place.locality?.isNotEmpty == true
        ? place.locality!
        : (place.subAdministrativeArea ?? 'Set location');
  } catch (_) {
    return 'Set location';
  }
});
