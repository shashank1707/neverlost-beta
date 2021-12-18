import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:icon_badge/icon_badge.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Firebase/hive.dart';
import 'package:neverlost_beta/Screens/profile.dart';
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

  void getUserFromHive() async {
    await HiveDB().getUserData().then((value) {
      setState(() {
        user = value;
      });
      Timer.periodic(const Duration(seconds: 1), (timer) {
        DatabaseMethods().updatelastseen(DateTime.now(), user['uid']);
      });
    });
    getCurrentUserSnapshots();
  }

  void getCurrentUserSnapshots() async {
    userStream = await DatabaseMethods().getUserSnapshots(user['uid']);
    setState(() {
      isLoading = false;
    });
  }

  Widget notificationBadge() {
    return StreamBuilder(
      stream: DatabaseMethods().getUserSnapshots(user['uid']),
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? IconBadge(
                icon: Icon(Icons.notifications_none),
                badgeColor: Colors.red,
                itemCount: snapshot.data['pendingRequestList'].length,
                top: 8,
                right: 8,
                hideZero: true,
                onTap: () {
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => Notifications(
                  //               user: user,
                  //             )));
                },
              )
            : IconBadge(
                icon: Icon(Icons.notifications_none),
                badgeColor: Colors.redAccent,
                itemCount: 0,
                top: 10,
                right: 10,
                hideZero: true,
                onTap: () {
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => Notifications(
                  //               user: user,
                  //             )));
                });
      },
    );
  }

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    getUserFromHive();

    super.initState();
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
                              // style: TextStyle(
                              //     color: _currentIndex == 0
                              //         ? backgroundColor1
                              //         : textColor1),
                            )),
                        Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: const Text(
                              'Groups',
                              // style: TextStyle(
                              // color: _currentIndex == 1
                              //     ? backgroundColor1
                              //     : textColor1),
                            )),
                        Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: const Text(
                              'Add',
                              // style: TextStyle(
                              //     color: _currentIndex == 2
                              //         ? backgroundColor1
                              //         : textColor1),
                            )),
                        Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: const Text(
                              'Settings',
                              // style: TextStyle(
                              //     color: _currentIndex == 3
                              //         ? backgroundColor1
                              //         : textColor1),
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
                Loading(),
                Loading(),
                Loading(),
                Setting(userUID: user['uid'])
              ],
            ),
          );
  }
}
