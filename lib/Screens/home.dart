import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:icon_badge/icon_badge.dart';
import 'package:location/location.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/auth.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Firebase/hive.dart';
import 'package:neverlost_beta/Screens/chat_list.dart';
import 'package:neverlost_beta/Screens/groupchats.dart';
import 'package:neverlost_beta/Screens/notifications.dart';
import 'package:neverlost_beta/Screens/profile.dart';
import 'package:neverlost_beta/Screens/search.dart';
import 'package:neverlost_beta/Screens/setting.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> user = {};
  late Stream userStream;

  bool isLoading = true;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;
  Location location = Location();
  late double lat;
  late double long;
  void getUserFromHive() async {
    await HiveDB().getUserData().then((value) {
      setState(() {
        user = value;
        isLoading = false;
      });
      Timer.periodic(const Duration(seconds: 1), (timer) {
        DatabaseMethods().updatelastseen(DateTime.now(), user['uid']);
      });
    });
  }

  Widget notificationBadge() {
    return StreamBuilder(
      stream: DatabaseMethods().getUserSnapshots(user['uid']),
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? IconBadge(
                icon: const Icon(Icons.notifications_none),
                badgeColor: Colors.red,
                itemCount: snapshot.data['pendingRequestList'].length,
                top: 8,
                right: 8,
                hideZero: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Notifications(
                                user: user,
                              )));
                },
              )
            : IconBadge(
                icon: const Icon(Icons.notifications_none),
                badgeColor: Colors.redAccent,
                itemCount: 0,
                top: 10,
                right: 10,
                hideZero: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Notifications(
                                user: user,
                              )));
                });
      },
    );
  }

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    getUserFromHive();
    getlocation();
    super.initState();
  }

  void getlocation() async {
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    location.onLocationChanged.listen((event) async {
      setState(() {
        lat = event.latitude!;
        long = event.longitude!;
      });
      await DatabaseMethods().updateUserLocation(user['uid'], lat, long);
    });
    setState(() {
      lat = _locationData.latitude!;
      long = _locationData.longitude!;
    });

    await DatabaseMethods().updateUserLocation(user['uid'], lat, long);
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Loading()
        : Scaffold(
            appBar: AppBar(
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15))),
              backgroundColor: backgroundColor1,
              elevation: 0,
              title: const Text('NeverLost'),
              actions: [
                notificationBadge(),
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Profile(user: user)));
                    },
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: ValueListenableBuilder(
                          valueListenable: Hive.box('IMAGEBOXKEY').listenable(),
                          builder: (context, Box box, widget) {
                            return box.get('IMAGEDATAKEY') != null
                                ? Image.file(File(box.get('IMAGEDATAKEY')))
                                : Image.network(user['photoURL']);
                          }),
                    )),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      labelColor: backgroundColor1,
                      unselectedLabelColor: backgroundColor2,
                      padding: const EdgeInsets.all(8),
                      isScrollable: true,
                      indicatorSize: TabBarIndicatorSize.tab,
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: backgroundColor2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tabs: [
                        Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: const Text(
                              'Chats',
                            )),
                        Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: const Text(
                              'Groups',
                            )),
                        Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: const Text(
                              'Add',
                            )),
                        Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: const Text(
                              'Settings',
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // Chats(user: user),
                // GroupChats(user: user),
                // Search(uid: user['uid']),
                ChatList(currentUser: user),
                GroupChats(
                  user: user,
                ),
                Search(uid: user['uid']),
                Setting(userUID: user['uid'])
              ],
            ),
          );
  }
}
