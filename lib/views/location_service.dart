import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }


    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;

  
    LocationAccuracy accuracy;
    switch (batteryLevel) {
      case > 50:
        accuracy = LocationAccuracy.best;
        break;
      case > 30:
        accuracy = LocationAccuracy.high;
        break;
      case > 20:
        accuracy = LocationAccuracy.medium;
        break;
      default:
        accuracy = LocationAccuracy.low;
    }


    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: 10,
        timeLimit: const Duration(seconds: 10),
      ),
    );
  }
}
