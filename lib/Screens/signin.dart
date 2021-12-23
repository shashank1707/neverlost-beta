import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Firebase/auth.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Firebase/hive.dart';
import 'package:neverlost_beta/Screens/home.dart';

class Signin extends StatefulWidget {
  const Signin({Key? key}) : super(key: key);

  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  void signInUser() async {
    await AuthMethods().signInWithGoogle();

    await AuthMethods().getCurrentUser().then((user) async {
      await DatabaseMethods()
          .createUserDatabase(user.displayName, user.email, user.uid,
              user.photoURL, user.phoneNumber)
          .then((value) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: backgroundColor1,
        body: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: const [
                  SizedBox(
                    height: 64,
                  ),
                  Text('NeverLost',
                      style: TextStyle(
                          fontSize: 40,
                          color: themeColor2,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  Image.asset(
                    'assets/images/background1.png',
                    width: width / 1.5,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Chat and share live location with your friends',
                      style: TextStyle(
                          color: themeColor2,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  MaterialButton(
                      onPressed: () {
                        signInUser();
                      },
                      child: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                            color: themeColor1,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(
                    height: 64,
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
