import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Firebase/auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:neverlost_beta/Screens/home.dart';
import 'package:neverlost_beta/Screens/signin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var opacity = 0.0;
  @override
  void initState() {
    redirect();
    super.initState();
  }

  void redirect() async {
    await Future.delayed(const Duration(milliseconds: 500)).then((value) {
      setState(() {
        opacity = 1.0;
      });
    });

    await Future.delayed(const Duration(seconds: 3)).then((value) async {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return FutureBuilder(
            future: AuthMethods().getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return const Home();
              } else {
                return const Signin();
              }
            },
          );
        }));
      } else {
        Fluttertoast.showToast(msg: 'No Internet Connection');
        await Future.delayed(const Duration(seconds: 2)).then((value){
          exit(0);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(seconds: 1),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/never_lost_icon.png',
                width: width / 3,
              ),
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('NeverLost',
                    style: TextStyle(
                        fontSize: 40,
                        color: backgroundColor1,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
