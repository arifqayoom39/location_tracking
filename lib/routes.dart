// ignore_for_file: prefer_const_constructors

import 'package:flutter/widgets.dart';
import 'package:location_tracking/home_screen.dart';
import 'package:location_tracking/splash_screen.dart';

final Map<String, WidgetBuilder> routes = {
  SplashScreen.routeName: (context) => SplashScreen(),
  EmployeeHomeScreen.routeName: (context) => EmployeeHomeScreen(),
};
