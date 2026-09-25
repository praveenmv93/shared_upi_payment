import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class _GroupGeofenceState {
  bool isInside = false;
  Timer? notifyTimer;
}

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  StreamSubscription<Position>? _positionStream;
  List<Group> _trackedGroups = [];
  final Map<String, _GroupGeofenceState> _groupStates = {};
  void Function(String)? _onNotification;

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

  void startTracking(List<Group> groups, {void Function(String)? onNotification}) {
    _trackedGroups = groups;
    if (onNotification != null) _onNotification = onNotification;

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
    for (var state in _groupStates.values) {
      state.notifyTimer?.cancel();
      state.isInside = false;
    }
    _trackedGroups = [];
  }

  void _checkGeofence(Position position) {
    for (var group in _trackedGroups) {
      if (group.homeLatitude == 0.0 || group.homeLongitude == 0.0) continue;
      
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        group.homeLatitude,
        group.homeLongitude,
      );

      // Assuming a radius of 150 meters for the circle location
      bool currentlyInside = distance <= 150.0;
      var state = _groupStates.putIfAbsent(group.id, () => _GroupGeofenceState());

      if (currentlyInside && !state.isInside) {
        // User just entered the circle
        state.isInside = true;
        
        // 1st Notification (immediately on entry)
        sendNotification(
          title: 'Circle Reached: ${group.name}!',
          body: 'You are inside your circle ${group.name}.',
        );
        
        // 2nd Notification (after exactly 1 minute). This satisfies maximum 2 times in 2 minutes.
        state.notifyTimer = Timer(const Duration(minutes: 1), () {
          if (state.isInside) {
            sendNotification(
              title: 'Still in ${group.name}!',
              body: 'Don\'t forget to settle any pending expenses while you are here.',
            );
          }
        });
      } else if (!currentlyInside && state.isInside) {
        // User just exited the circle
        state.isInside = false;
        state.notifyTimer?.cancel();
      }
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
    
    // Also push to in-app alerts screen
    _onNotification?.call('$title - $body');
  }
}
