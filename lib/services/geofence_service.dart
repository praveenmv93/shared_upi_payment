import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  StreamSubscription<Position>? _positionStream;
  Group? _currentGroup;
  
  bool _isInside = false;
  Timer? _notifyTimer;
  int _notifyCount = 0;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings: initSettings);

    // Request permissions for notifications on modern Android
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
  }

  void startTracking(Group group) {
    if (group.homeLatitude == 0.0 || group.homeLongitude == 0.0) return;
    
    // If we are already tracking this exact same group location, do nothing
    if (_currentGroup?.id == group.id && _currentGroup?.homeLatitude == group.homeLatitude) return;

    _currentGroup = group;
    _isInside = false;
    _notifyTimer?.cancel();
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      )
    ).listen((Position position) {
      _checkGeofence(position);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _notifyTimer?.cancel();
    _isInside = false;
    _currentGroup = null;
  }

  void _checkGeofence(Position position) {
    if (_currentGroup == null) return;
    
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _currentGroup!.homeLatitude,
      _currentGroup!.homeLongitude,
    );

    // Assuming a radius of 150 meters for the circle location
    bool currentlyInside = distance <= 150.0;

    if (currentlyInside && !_isInside) {
      // User just entered the circle
      _isInside = true;
      
      // 1st Notification (immediately on entry)
      sendNotification(
        title: 'Circle Reached: ${_currentGroup!.name}!',
        body: 'You are inside your circle ${_currentGroup!.name}.',
      );
      
      // 2nd Notification (after exactly 1 minute). This satisfies maximum 2 times in 2 minutes.
      _notifyTimer = Timer(const Duration(minutes: 1), () {
        if (_isInside) {
          sendNotification(
            title: 'Still in ${_currentGroup!.name}!',
            body: 'Don\'t forget to settle any pending expenses while you are here.',
          );
        }
      });
    } else if (!currentlyInside && _isInside) {
      // User just exited the circle
      _isInside = false;
      _notifyTimer?.cancel();
    }
  }

  Future<void> sendNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Alerts & Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
