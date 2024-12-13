/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_tracking/constants.dart';
import 'package:location_tracking/database_helper.dart';
import 'package:location_tracking/local_notification.dart';
import 'package:location_tracking/routes.dart';
import 'package:location_tracking/splash_screen.dart';

var i = 0;

final navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp((MaterialApp(
    home: const MyApp(),
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
  )));
}

StreamSubscription<Position>? subscription;

// Background service function
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  await setupNotifications();

  // Show notification that the service has started
  await showNotification(
      'Employee Suite', 'Tracking location in the background');

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
      stopLocation();
    });
  }
  startUpdateLocation();
}

Future<void> addItem(latitude, longitude) async {
  await DatabaseHelper.createItem(latitude!.toString(), longitude!.toString(),
      DateTime.now().toUtc().millisecondsSinceEpoch, '1');
  // _refreshData();
}

startCurrentLocation() async {
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );
  final position =
      await Geolocator.getCurrentPosition(locationSettings: locationSettings);

  addItem(position.latitude, position.longitude);
  i += 1;
  print(i);
  print('After set state');
  print('${position.latitude}, ${position.longitude}');
  await showNotification(
    'Service Running',
    'Tracking location: ${position.latitude}, ${position.longitude}',
  );
}

startUpdateLocation() async {
  // ignore: prefer_const_constructors
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );
  subscription =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position? newLoc) async {
    print('Start Location');
    print('${newLoc!.latitude}, ${newLoc.longitude}');
    await showNotification(
      'Service Running',
      'Tracking location: ${newLoc.latitude}, ${newLoc.longitude}',
    );
    addItem(newLoc.latitude, newLoc.longitude);
    i += 1;
    print(i);
  });
}

stopLocation() {
  subscription?.cancel();
  print('Stop Location');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Employee Suite',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: kPrimaryColorDark,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: "Nexa",
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: SplashScreen.routeName,
      routes: routes,
    );
  }
}*/



/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_tracking/constants.dart';
import 'package:location_tracking/database_helper.dart';
import 'package:location_tracking/local_notification.dart';
import 'package:location_tracking/routes.dart';
import 'package:location_tracking/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

var i = 0;
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp((MaterialApp(
    home: const MyApp(),
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
  )));
}

StreamSubscription<Position>? subscription;

// Background service function
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  await setupNotifications();

  // Show notification that the service has started
  await flutterLocalNotificationsPlugin.show(
    0,
    'Employee Suite',
    'Tracking location in the background',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'background_service',
        'Background Service',
        channelDescription: 'Location tracking', // Using named argument
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
      ),
    ),
  );

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
      stopLocation();
    });
  }
  startUpdateLocation();
}

Future<void> addItem(latitude, longitude) async {
  await DatabaseHelper.createItem(latitude!.toString(), longitude!.toString(),
      DateTime.now().toUtc().millisecondsSinceEpoch, '1');
  // _refreshData();
}

startCurrentLocation() async {
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );
  final position =
      await Geolocator.getCurrentPosition(locationSettings: locationSettings);

  addItem(position.latitude, position.longitude);
  i += 1;
  print(i);
  print('After set state');
  print('${position.latitude}, ${position.longitude}');
  await flutterLocalNotificationsPlugin.show(
    1,
    'Service Running',
    'Tracking location: ${position.latitude}, ${position.longitude}',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'background_service',
        'Background Service',
        channelDescription: 'Location tracking', // Using named argument
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
      ),
    ),
  );
}

startUpdateLocation() async {
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );
  subscription =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position? newLoc) async {
    print('Start Location');
    print('${newLoc!.latitude}, ${newLoc.longitude}');
    await flutterLocalNotificationsPlugin.show(
      1,
      'Service Running',
      'Tracking location: ${newLoc.latitude}, ${newLoc.longitude}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'background_service',
          'Background Service',
          channelDescription: 'Location tracking', // Using named argument
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
        ),
      ),
    );
    addItem(newLoc.latitude, newLoc.longitude);
    i += 1;
    print(i);
  });
}

stopLocation() {
  subscription?.cancel();
  print('Stop Location');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Employee Suite',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: kPrimaryColorDark,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: "Nexa",
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: SplashScreen.routeName,
      routes: routes,
    );
  }
}*/


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location_tracking/constants.dart';
import 'package:location_tracking/database_helper.dart';
import 'package:location_tracking/local_notification.dart';
import 'package:location_tracking/routes.dart';
import 'package:location_tracking/splash_screen.dart';

// Initialize notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Global variable for navigator key
final navigatorKey = GlobalKey<NavigatorState>();

// Main function
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );

  // Run the app
  runApp(MyApp());
}

// StreamSubscription for location tracking
StreamSubscription<Position>? subscription;

// Background service function
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Setup notifications when background service starts
  await setupNotifications();

  // Show notification that service has started
  await flutterLocalNotificationsPlugin.show(
    0,
    'Employee Suite',
    'Tracking location in the background',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'background_service',
        'Background Service',
        channelDescription: 'Location tracking',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
      ),
    ),
  );

  // Handle stop service event
  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
      stopLocation();
    });
  }

  // Start location updates
  startUpdateLocation();
}

// Add location item to the database
Future<void> addItem(double latitude, double longitude) async {
  await DatabaseHelper.createItem(
    latitude.toString(),
    longitude.toString(),
    DateTime.now().toUtc().millisecondsSinceEpoch,
    '1',
  );
}

// Start updating location and show notifications
startUpdateLocation() async {
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );

  // Start listening for location updates
  subscription = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position? newLoc) async {
    if (newLoc != null) {
      // Show location update in notification
      await flutterLocalNotificationsPlugin.show(
        1,
        'Service Running',
        'Tracking location: ${newLoc.latitude}, ${newLoc.longitude}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'background_service',
            'Background Service',
            channelDescription: 'Location tracking',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
          ),
        ),
      );
      // Save the new location to the database
      addItem(newLoc.latitude, newLoc.longitude);
    }
  });
}

// Stop location updates when the service is stopped
stopLocation() {
  subscription?.cancel();
}

// MyApp widget (root of the application)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Employee Suite',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: kPrimaryColorDark,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: "Nexa",
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: SplashScreen.routeName,
      routes: routes,
      navigatorKey: navigatorKey,
    );
  }
}

// Notification setup
Future<void> setupNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Function to handle app permissions and request location
Future<bool> checkAndRequestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
}

