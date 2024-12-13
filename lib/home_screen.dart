// import 'dart:html';
// ignore_for_file: prefer_const_constructors, unnecessary_new, use_build_context_synchronously, prefer_typing_uninitialized_variables, unused_field, unnecessary_null_comparison, unrelated_type_equality_checks, avoid_print, unused_element, deprecated_member_use, unused_local_variable

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location_tracking/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../constants.dart';
import '../database_helper.dart';

class EmployeeHomeScreen extends StatefulWidget {
  static String routeName = "/employee_home";

  const EmployeeHomeScreen({super.key});
  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with WidgetsBindingObserver {
  final bool _isInForeground = true;
  final serviceBackground = FlutterBackgroundService();
  String? errorTypeMsg, errorStartMsg, errorEndMsg, transportType, workType;
  String? companyName, companyImageUrl;

  var attendanceId, attendanceStatus, attendanceStatusID, todayAttendanceStatus;
  var _attendanceImg,
      _message,
      getStartAddress,
      getStartAttendanceImageUrl,
      starttransportType,
      _startTransportType,
      startWorkType,
      _startWorkType;
  var previousLocLat, previousLocLong;
  MapType _defaultMapType = MapType.normal;
  bool? _permissionGranted;

  bool btnState = false,
      closeButton = false,
      liveLocationStatus = false,
      waitLocationRequst = false;
  var datetime;
  StreamSubscription<Position>? subscription;
  bool locationSwitch = false;
  String? _startDateTime, _endDateTime, startDate, endDate, startAt;
  var startAddress, endAddress, startAttendanceImageUrl, endAttendanceImageUrl;
  final Completer<GoogleMapController> _controller = Completer();
  Position? currentLocation;
  Position? newLocation;
  Position? currentLocationSet;
  String address = "";
  List<LatLng> realTimeCoordinates = [];
  List<LatLng> polylineCoordinates = [];
  List<Map<String, dynamic>> myData = [];
  List<Map<String, dynamic>> allMyData = [];

  bool _isLoading = true;

  String location = "Unknown";
  bool isServiceRunning = false;
//Old Code
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     super.didChangeAppLifecycleState(state);
     if (state == AppLifecycleState.resumed && liveLocationStatus == true) {
       print('_isInForeground');
      stopService();
       flutterLocalNotificationsPlugin.cancelAll();
     } else if (state == AppLifecycleState.paused &&
         liveLocationStatus == true) {
       print('_isInBackground');
       startService();
     } else if (state == AppLifecycleState.detached &&
         liveLocationStatus == true) {
       print('_isInKilled');
       startService();
     }
   }
//Old Code
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addObserver(this);
    locationPermissionGeolocator();

    drawPolylineLocalDB();
    currentDateTime();
    setCustomMarkerIcon();
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> startService() async {
    if (!await Permission.locationAlways.isGranted) {
      // Request "always" permission for location
      await Permission.locationAlways.request();
      await Permission.locationWhenInUse.request();
//  await Permission.foregroundService.request();
    } else {
      // Request location permission
      if (await Permission.location.request().isGranted) {
        print(Permission.location.request().isGranted);
        // Check if service is already running
        final isRunning = await FlutterBackgroundService().isRunning();
        if (!isRunning) {
          final service = FlutterBackgroundService();
          service.configure(
            androidConfiguration: AndroidConfiguration(
              onStart: onStart,
              isForegroundMode: false,
              autoStart: true, // Do not auto-start
            ),
            iosConfiguration: IosConfiguration(
              onForeground: onStart,
              autoStart: true, // Do not auto-start
            ),
          );

          await service.startService();
        } else {
          print("Service already running!");
        }
      } else {
        print("Location permission denied");
      }
    }
  }

  void stopService() {
    FlutterBackgroundService().invoke('stopService');
  }

  Future<Position> locationPermissionGeolocator() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showEnableLocationDialog();
      return Future.error('Location services are disabled.');
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      await Geolocator.openAppSettings(); // Open app settings
      return Future.error(
        'Location permissions are permanently denied. Please enable permissions in settings.',
      );
    }

    // If permissions are granted, get the current position
    Position position = await Geolocator.getCurrentPosition();
    if (position != null) {
      setState(() {
        _permissionGranted = true;
        currentLocation = position;
        currentLocationSet = position;
      });
    }
    print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    return position;
  }

  void showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enable Location"),
        content: Text(
            "Location services are disabled. Please enable them to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Dismiss dialog
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Geolocator.openLocationSettings(); // Open location settings
            },
            child: Text("Enable"),
          ),
        ],
      ),
    );
  }

  showMyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Location Permission'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Open App permission'),
                Text('2. On Location'),
                Text('3. Allow all the time'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  _permissionGranted =
                      await Permission.locationAlways.isGranted;
                  print('permissionnnnnnnnnnnnnnnnn6112233');
                  print(_permissionGranted);
                  if (_permissionGranted == true) {
                    Navigator.pop(context);
                    locationPermissionGeolocator();
                  } else {
                    Navigator.pop(context);
                    await openAppSettings();
                  }
                },
                child: const Text('Check Status'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeMapType() {
    setState(() {
      _defaultMapType =
          _defaultMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  currentDateTime() {
    setState(() {
      datetime = DateFormat('dd MMM, yyyy').format(DateTime.now());
    });
  }

  startLocationAPICall() {
    startService();
    deleteItem();
  }

  stopLocation() {
    subscription?.cancel();
  }

  endLocationAPICall() async {
    stopService();
    deleteItem();
  }

  startLocation() async {
    GoogleMapController googleMapController = await _controller.future;
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
    subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? newLoc) {
      setState(() {
        currentLocation = newLoc;
      });

      newLocation = newLoc;
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            zoom: 18.0,
            target: LatLng(
              newLoc!.latitude,
              newLoc.longitude,
            ),
          ),
        ),
      );
      realTimeCoordinates.add(
        LatLng(newLoc.latitude, newLoc.longitude),
      );
      setState(() {});
      drawPolyline();
      _refreshData();
      print('${newLoc.latitude}, ${newLoc.longitude}');
    });
  }

  drawPolylineLocalDB() async {
    await _refreshData();
    for (var i = 0; i < allMyData.length; i++) {
      polylineCoordinates
          .add(LatLng(allMyData[i]['latitude']!, allMyData[i]['longitude']!));
    }
  }

  void drawPolyline() async {
    addItem();

    polylineCoordinates.add(
      LatLng(newLocation!.latitude, newLocation!.longitude),
    );

    setState(() {});
  }

  // This function is used to fetch all data from the database
  _refreshData() async {
    final data = await DatabaseHelper.getItems();
    setState(() {
      myData = data;
      _isLoading = false;
    });
    print(myData);
    print('myData.length rgfehjk rweftgydhuwji erftdghj');
    print(myData.length);
    final dataAll = await DatabaseHelper.getAllItems();
    setState(() {
      allMyData = dataAll;
    });
  }

  // Insert a new data to the database
  Future<void> addItem() async {
    await DatabaseHelper.createItem(
        newLocation!.latitude.toString(),
        newLocation!.longitude.toString(),
        DateTime.now().toUtc().millisecondsSinceEpoch,
        '0');
  }

  void deleteItem() async {
    await DatabaseHelper.deleteItem();
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //     content: Text('Successfully deleted!'), backgroundColor: Colors.green));
    _refreshData();
  }

  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration.empty, "assets/images/pin1.png")
        .then(
      (icon) {
        currentLocationIcon = icon;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        onBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          // toolbarHeight: MediaQuery.of(context).size.height * 0.05,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness:
                Brightness.dark, // For Android (dark icons)
            statusBarBrightness: Brightness.dark, // For iOS (dark icons)
          ),
          elevation: 3,
          title: Text(
            'Location Tracking',
            style: TextStyle(
              color: Colors.black,
              // fontSize: 17,
              // fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          // leading: Icon(
          //   Icons.home,
          //   color: Colors.white,
          // ),
          // automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                return SizedBox(
                  height: constraints.maxHeight / 2,
                  child: Stack(
                    children: [
                      currentLocation == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: kPrimaryColor,
                              ),
                            )
                          : GoogleMap(
                              // padding: EdgeInsets.only(
                              //     top: MediaQuery.of(context).size.height / 5,
                              //     right: 4.0),
                              initialCameraPosition: CameraPosition(
                                target: LatLng(currentLocation!.latitude,
                                    currentLocation!.longitude),
                                zoom: 16.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId("currentLocation"),
                                  position: LatLng(currentLocation!.latitude,
                                      currentLocation!.longitude),
                                  icon: currentLocationIcon,
                                ),
                              },
                              onMapCreated: (mapController) {
                                _controller.complete(mapController);
                              },
                              polylines: {
                                Polyline(
                                  polylineId: const PolylineId("route"),
                                  points: polylineCoordinates,
                                  color: const Color(0xFF7B61FF),
                                  width: 4,
                                ),
                              },

                              mapType: _defaultMapType,

                              myLocationEnabled: true,
                            ),
                      _permissionGranted == true
                          ? Container()
                          : Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          constraints: BoxConstraints.expand(
                                              height: 120),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                            ),
                                            color: Colors.white,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.warning_rounded,
                                                color: Colors.amber.shade600,
                                                size: 50,
                                              ),
                                              SizedBox(
                                                height: 4.0,
                                              ),
                                              Text(
                                                'Required!',
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          26,
                                                  // color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 1.0,
                                              ),
                                              Text(
                                                'Allow all the time',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          24,
                                                  // color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          constraints: BoxConstraints.expand(
                                              height: 120),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                            ),
                                            color: Colors.red.shade900,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(20),
                                                bottomRight:
                                                    Radius.circular(20),
                                              ),
                                              onTap: () async {
                                                locationPermissionGeolocator();
                                              },
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.info,
                                                    color: Colors.white,
                                                    size: 50,
                                                  ),
                                                  SizedBox(
                                                    height: 4.0,
                                                  ),
                                                  Text(
                                                    'Check',
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              26,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 1.0,
                                                  ),
                                                  Text(
                                                    'Permission Status',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.white,
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              24,
                                                      // color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              }),
              DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.5,
                snapSizes: const [0.5, 1],
                snap: true,
                maxChildSize: 1,
                expand: true,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        // height: MediaQuery.of(context).size.height / 1.25,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _refreshData();
                                      },
                                      child: Text("Get Data"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        drawPolylineLocalDB();
                                      },
                                      child: Text("Local Line"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _allMyDataDialog(context, allMyData);
                                      },
                                      child: Text("Show Co-ordinates"),
                                    ),
                                  ],
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        startService();
                                      },
                                      child: Text("Start Service"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        stopService();
                                      },
                                      child: Text("End Service"),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Icon(Icons.keyboard_arrow_up_rounded),
                                ),
                              ),
                              liveLocationStatus == false
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.location_off_rounded,
                                          color: Colors.red,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: 8.0, top: 2.0),
                                          child: Text('Live Tracking OFF'),
                                        )
                                      ],
                                    )
                                  : GestureDetector(
                                      onDoubleTap: () {
                                        _allMyDataDialog(context, allMyData);
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            "assets/images/liveBlink.gif",
                                            width: 30,
                                            height: 30,
                                            fit: BoxFit.contain,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0, top: 2.0),
                                            child: Text('Live Tracking ON'),
                                          )
                                        ],
                                      ),
                                    ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                ),
                                child: Divider(),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(2, 2),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              "Change Map Type: ",
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            SizedBox(
                                              height: 4,
                                            ),
                                            Text(
                                              "Current Location: ",
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            SizedBox(
                                              height: 4,
                                            ),
                                            Text(
                                              "Permission Status: ",
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                _changeMapType();
                                                setState(() {
                                                  btnState = !btnState;
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.only(
                                                  top: 2.0,
                                                  right: 6.0,
                                                  left: 6.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.blue,
                                                      width: 2.0),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  btnState == false
                                                      ? 'Default'
                                                      : 'Satellite',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 4,
                                            ),
                                            currentLocation == null
                                                ? Text(
                                                    '00.000000, 00.000000',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : Text(
                                                    '${currentLocation!.latitude.toStringAsFixed(6)}, ${currentLocation!.longitude.toStringAsFixed(6)}',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                            SizedBox(
                                              height: 4,
                                            ),
                                            _permissionGranted == true
                                                ? Text(
                                                    "Active",
                                                    style: TextStyle(
                                                      color: Colors.green[600],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : GestureDetector(
                                                    onTap: () {
                                                      locationPermissionGeolocator();
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .blue.shade900,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 8.0,
                                                                right: 8.0,
                                                                top: 3.0,
                                                                bottom: 2.0),
                                                        child: Row(
                                                          children: const [
                                                            Icon(
                                                              Icons.pin_drop,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Check Status',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                ),
                                child: Divider(),
                              ),
                              SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Total Count : ',
                                        ),
                                        Text(
                                          '${allMyData.length}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: const [
                                        Text(
                                          'ID',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Date/Time',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lat/Long',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Sync',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14),
                                        ),
                                        Text(
                                          'BS',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Divider(),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          40,
                                      height:
                                          MediaQuery.of(context).size.height -
                                              270,
                                      child: allMyData.isNotEmpty
                                          ? ListView.builder(
                                              itemCount: allMyData.length,
                                              itemBuilder: (context, index) {
                                                var i = index + 1;
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.black12,
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4.0,
                                                            bottom: 4.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        Text(
                                                            allMyData[index]
                                                                    ["id"]
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                DateFormat(
                                                                        'dd MMM, yyyy')
                                                                    .format(DateTime.fromMillisecondsSinceEpoch(
                                                                        allMyData[index]
                                                                            [
                                                                            "createdAt"])),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12)),
                                                            Text(
                                                                DateFormat(
                                                                        'hh:mm:ss a')
                                                                    .format(DateTime.fromMillisecondsSinceEpoch(
                                                                        allMyData[index]
                                                                            [
                                                                            "createdAt"])),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12)),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                allMyData[index]
                                                                        [
                                                                        "latitude"]
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12)),
                                                            Text(
                                                                allMyData[index]
                                                                        [
                                                                        "longitude"]
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12)),
                                                          ],
                                                        ),
                                                        Text(
                                                            allMyData[index]
                                                                    ["sync"]
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                        Text(
                                                            allMyData[index][
                                                                    "isBackground"]
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> onBackPressed() async {
    return (await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: new Text('No'),
              ),
              TextButton(
                onPressed: () => exit(0),
                child: new Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  _alertInputDialog(context, title, msg) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const SizedBox(height: 2),
                    Center(
                      child: Text(
                        "$title",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Divider(),
                    const SizedBox(height: 10),
                    Center(child: Text("$msg")),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.red),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ))),
                              onPressed: () {
                                // setState(() {
                                //   changeBotton = false;
                                // });
                                Navigator.pop(context);
                              },
                              child: const Text('Ok'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  _allMyDataDialog(context, allMyDataM) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding:
              EdgeInsets.only(bottom: 0.0, top: 0.0, left: 0.0, right: 0.0),
          insetPadding: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coordinates'),
              OutlinedButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Count : ',
                    ),
                    Text(
                      '${allMyDataM.length}',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text(
                      'ID',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date/Time',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lat/Long',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      'Sync',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      'BS',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                Divider(),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: MediaQuery.of(context).size.height - 270,
                  child: allMyDataM.isNotEmpty
                      ? ListView.builder(
                          itemCount: allMyDataM.length,
                          itemBuilder: (context, index) {
                            var i = index + 1;
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black12,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 4.0, bottom: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(allMyDataM[index]["id"].toString(),
                                        style: TextStyle(fontSize: 12)),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            DateFormat('dd MMM, yyyy').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        allMyDataM[index]
                                                            ["createdAt"])),
                                            style: TextStyle(fontSize: 12)),
                                        Text(
                                            DateFormat('hh:mm:ss a').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        allMyDataM[index]
                                                            ["createdAt"])),
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            allMyDataM[index]["latitude"]
                                                .toString(),
                                            style: TextStyle(fontSize: 12)),
                                        Text(
                                            allMyDataM[index]["longitude"]
                                                .toString(),
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    Text(allMyDataM[index]["sync"].toString(),
                                        style: TextStyle(fontSize: 12)),
                                    Text(
                                        allMyDataM[index]["isBackground"]
                                            .toString(),
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
