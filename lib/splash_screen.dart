// ignore_for_file: sized_box_for_whitespace, avoid_unnecessary_containers, prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:location_tracking/home_screen.dart';
import '../../constants.dart';
import '../size_config.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = "/splash";

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // You have to call it on your starting screen
    SizeConfig().init(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(),
                Container(
                  color: Colors.white,
                  // height: MediaQuery.of(context).size.height,
                  child: FadeTransition(
                    opacity: _animation,
                    child: Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: getProportionateScreenHeight(265),
                          width: getProportionateScreenWidth(235),
                        )),
                  ),
                ),
                const Spacer(),
              ],
            ),
            Positioned(
              top: 0.0,
              right: 0.0,
              child: Container(
                color: Colors.white,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TweenAnimationBuilder(
                      tween: Tween(begin: 5.0, end: 0.00),
                      duration: const Duration(seconds: 5),
                      builder: (_, value, child) {
                        return Text(
                          value.toInt() <= 9
                              ? "00:0${value.toInt()}"
                              : "00:${value.toInt()}",
                          style: const TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w400),
                        );
                      },
                      onEnd: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EmployeeHomeScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
