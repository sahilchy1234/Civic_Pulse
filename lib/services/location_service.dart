import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      print('🔍 Starting location request...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('🔐 Requesting permission...');
        permission = await Geolocator.requestPermission();
        print('🔐 Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        return null;
      }
      
      print('✅ Permissions OK, proceeding with location request...');

      // Try to get last known position first (faster)
      try {
        print('🔄 Trying to get last known position...');
        Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          // Check if the last known position is recent (within 5 minutes)
          final now = DateTime.now();
          final positionTime = lastKnownPosition.timestamp;
          final ageMinutes = now.difference(positionTime).inMinutes;
          print('📍 Last known position age: $ageMinutes minutes');
          
          if (ageMinutes < 5) {
            print('✅ Using last known position (${ageMinutes} minutes old)');
            return lastKnownPosition;
          } else {
            print('⏰ Last known position too old ($ageMinutes minutes), getting fresh location...');
          }
        } else {
          print('📍 No last known position available');
        }
      } catch (e) {
        print('❌ Could not get last known position: $e');
      }

      // Get current position with more flexible settings
      print('🔄 Getting current position with medium accuracy (15s timeout)...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      
      print('✅ Successfully got current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      
      // Try with lower accuracy as fallback
      try {
        print('Trying with lower accuracy...');
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 20),
        );
        return position;
      } catch (fallbackError) {
        print('Fallback location attempt also failed: $fallbackError');
        
        // Last resort: try with minimal accuracy and longer timeout
        try {
          print('Trying with minimal accuracy...');
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: const Duration(seconds: 30),
          );
          return position;
        } catch (finalError) {
          print('All location attempts failed: $finalError');
          return null;
        }
      }
    }
  }

  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  static Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  static Future<bool> openLocationSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('Error opening location settings: $e');
      return false;
    }
  }

  static double calculateDistance(
    double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  static Future<List<Position>> getNearbyLocations(
    double latitude, double longitude, double radiusInMeters) async {
    try {
      // This is a simplified implementation
      // In a real app, you might want to use a geospatial database
      // or implement a more sophisticated nearby search
      return [];
    } catch (e) {
      print('Error getting nearby locations: $e');
      return [];
    }
  }

  // Alternative method for getting location with custom timeout
  static Future<Position?> getCurrentLocationWithTimeout(Duration timeout) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position with custom timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: timeout,
      );

      return position;
    } catch (e) {
      print('Error getting location with custom timeout: $e');
      return null;
    }
  }

  // Debug method to check location service status
  static Future<Map<String, dynamic>> getLocationStatus() async {
    Map<String, dynamic> status = {};
    
    try {
      // Check location services
      status['serviceEnabled'] = await Geolocator.isLocationServiceEnabled();
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      status['permission'] = permission.toString();
      
      // Check last known position
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        status['lastKnownPosition'] = lastKnown != null ? {
          'lat': lastKnown.latitude,
          'lng': lastKnown.longitude,
          'timestamp': lastKnown.timestamp.toString(),
        } : null;
      } catch (e) {
        status['lastKnownError'] = e.toString();
      }
      
      // Check current position (with short timeout for testing)
      try {
        Position current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.lowest,
          timeLimit: const Duration(seconds: 5),
        );
        status['currentPosition'] = {
          'lat': current.latitude,
          'lng': current.longitude,
          'accuracy': current.accuracy,
        };
      } catch (e) {
        status['currentPositionError'] = e.toString();
      }
      
    } catch (e) {
      status['generalError'] = e.toString();
    }
    
    return status;
  }

  // Method to get location with detailed error reporting
  static Future<Map<String, dynamic>> getLocationWithDetails() async {
    Map<String, dynamic> result = {
      'success': false,
      'position': null,
      'error': null,
      'steps': [],
    };
    
    try {
      result['steps'].add('Starting location request...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      result['steps'].add('Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        result['error'] = 'Location services are disabled';
        return result;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      result['steps'].add('Initial permission: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        result['steps'].add('Requested permission: $permission');
        
        if (permission == LocationPermission.denied) {
          result['error'] = 'Location permissions are denied';
          return result;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        result['error'] = 'Location permissions are permanently denied';
        return result;
      }

      result['steps'].add('Permissions OK, trying last known position...');
      
      // Try to get last known position first
      try {
        Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          final now = DateTime.now();
          final positionTime = lastKnownPosition.timestamp;
          if (now.difference(positionTime).inMinutes < 5) {
            result['steps'].add('Using last known position (${now.difference(positionTime).inMinutes} minutes old)');
            result['position'] = lastKnownPosition;
            result['success'] = true;
            return result;
          } else {
            result['steps'].add('Last known position too old (${now.difference(positionTime).inMinutes} minutes)');
          }
        }
      } catch (e) {
        result['steps'].add('Could not get last known position: $e');
      }

      result['steps'].add('Getting current position...');
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      
      result['position'] = position;
      result['success'] = true;
      result['steps'].add('Successfully obtained current position');
      
    } catch (e) {
      result['error'] = e.toString();
      result['steps'].add('Error: $e');
    }
    
    return result;
  }
}
