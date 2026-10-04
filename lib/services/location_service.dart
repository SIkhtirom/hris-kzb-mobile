import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/geo_location.dart';

class LocationService {
  Geocoding? _geocoding;

  Geocoding get _geo => _geocoding ??= Geocoding();

  Future<bool> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<GeoLocation> getCurrentLocation() async {
    final granted = await requestLocationPermission();
    if (!granted) {
      throw const LocationServiceException('Izin akses lokasi belum diberikan');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );

    return GeoLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: await _reverseGeocode(position.latitude, position.longitude),
    );
  }

  Future<String> _reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await _geo.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) {
        return '';
      }
      final placemark = placemarks.first;
      final parts = <String>[
        placemark.street ?? '',
        placemark.subLocality ?? '',
        placemark.locality ?? '',
        placemark.administrativeArea ?? '',
        placemark.country ?? '',
      ].where((part) => part.trim().isNotEmpty).toList();
      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }
}

class LocationServiceException implements Exception {
  final String message;

  const LocationServiceException(this.message);

  @override
  String toString() => message;
}
