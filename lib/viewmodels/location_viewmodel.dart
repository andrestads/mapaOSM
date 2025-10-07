import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationViewModel extends ChangeNotifier {
  Position? _location;
  bool _isLoading = true;
  String _address = '';
  StreamSubscription<Position>? _positionStreamSubscription;

  Position? get location => _location;
  bool get isLoading => _isLoading;
  String get address => _address;

  LocationViewModel() {
    fetchLocation();
    _listenToLocationChanges();
  }

  Future<void> fetchLocation() async {
    _isLoading = true;
    notifyListeners();
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
    } catch (e) {

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _location = position;
      _getAddressFromLatLng();
      notifyListeners();
    });
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
          _address = '${place.street}, ${place.locality}';
        }
      }
    } catch (e) {
      _address = 'A obter endereço...';
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}