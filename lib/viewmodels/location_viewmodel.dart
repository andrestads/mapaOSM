import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationViewModel extends ChangeNotifier {
  Position? _location;
  bool _isLoading = true;
  String _address = '';

  Position? get location => _location;
  bool get isLoading => _isLoading;
  String get address => _address;

  Future<void> fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviços de localização desativados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização permanentemente negada');
      }

      _location = await Geolocator.getCurrentPosition();
      await _getAddressFromLatLng();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      if (_location != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _location!.latitude,
          _location!.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _address =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
        }
      }
    } catch (e) {
      _address = 'Não foi possível obter o endereço';
    }
    notifyListeners();
  }
}