import 'dart:async';

import 'package:badges/badges.dart';
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
import 'package:neverlost_beta/Screens/chat_list.dart';
import 'package:neverlost_beta/Screens/friendrequests.dart';
import 'package:neverlost_beta/Screens/groupchat_list.dart';
import 'package:neverlost_beta/Screens/notifications.dart';
import 'package:neverlost_beta/Screens/profile.dart';
import 'package:neverlost_beta/Screens/search.dart';
import 'package:neverlost_beta/Screens/setting.dart';
import 'dart:io';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> currentUser = {};
  late Stream userStream;

  bool isLoading = true;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;
  Location location = Location();
  late double lat;
  late double long;

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    getCurrentUser();
    getlocation();
    super.initState();
  }

  void getCurrentUser() async {
    await AuthMethods().getCurrentUser().then((auth) {
      DatabaseMethods().getUserSnapshots(auth.uid).listen((user) {
        setState(() {
          currentUser = user.data()!;
          isLoading = false;
        });
      });
    });
  }

  Widget notificationBadge() {
    return currentUser['notifications'].where((notification) {
              return notification['seen'] == false;
            }).length >
            0
        ? Badge(
            position: BadgePosition.topEnd(top: 5, end: 5),
            badgeContent: Text(
              '${currentUser['notifications'].where((notification) {
                return notification['seen'] == false;
              }).length}',
              style: const TextStyle(color: Colors.white),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Notifications(
                              currentUser: currentUser,
                            )));
              },
            ),
          )
        : Badge(
            position: BadgePosition.topEnd(top: 5, end: 5),
            badgeContent: null,
            showBadge: false,
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Notifications(
                              currentUser: currentUser,
                            )));
              },
            ),
          );
  }

  Widget friendRequestBadge() {
    return currentUser['pendingRequestList'].length > 0
        ? Badge(
            position: BadgePosition.topEnd(top: 5, end: 5),
            badgeContent: Text(
              '${currentUser['pendingRequestList'].length}',
              style: const TextStyle(color: Colors.white),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_add_alt_rounded),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FriendRequests(
                              currentUser: currentUser,
                            )));
              },
            ),
          )
        : Badge(
            position: BadgePosition.topEnd(top: 5, end: 5),
            badgeContent: null,
            showBadge: false,
            child: IconButton(
              icon: const Icon(Icons.person_add_alt_rounded),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FriendRequests(
                              currentUser: currentUser,
                            )));
              },
            ),
          );
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
      await DatabaseMethods().updateUserLocation(currentUser['uid'], lat, long);
    });
    setState(() {
      lat = _locationData.latitude!;
      long = _locationData.longitude!;
    });

    await DatabaseMethods().updateUserLocation(currentUser['uid'], lat, long);
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
                friendRequestBadge(),
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  Profile(currentUser: currentUser)));
                    },
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(currentUser['photoURL']),
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
                ChatList(currentUser: currentUser),
                GroupChatList(currentUser: currentUser),
                Search(currentUser: currentUser),
                Loading(),
              ],
            ),
          );
  }
}
