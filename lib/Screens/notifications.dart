import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';

class Notifications extends StatefulWidget {
  final Map<String, dynamic> user;

  const Notifications({required this.user, Key? key}) : super(key: key);

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 1, vsync: this, initialIndex: 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor2,
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
        backgroundColor: backgroundColor1,
        elevation: 0,
        title: const Text('Notifications'),
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
                        'Friend Requests',
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
          FriendRequests(
            user: widget.user,
          ),
        ],
      ),
    );
  }
}

class FriendRequests extends StatefulWidget {
  final Map<String, dynamic> user;

  const FriendRequests({required this.user, Key? key}) : super(key: key);

  @override
  _FriendRequestsState createState() => _FriendRequestsState();
}

class _FriendRequestsState extends State<FriendRequests> {
  late Stream userStream;
  bool isLoading = true;

  @override
  void initState() {
    getCurrentUserSnapshots();
    super.initState();
  }

  void getCurrentUserSnapshots() async {
    userStream = await DatabaseMethods().getUserSnapshots(widget.user['uid']);
    setState(() {
      isLoading = false;
    });
    print(widget.user);
  }

  void acceptFriendRequest(currentUserUID, friendUserUID, index) async {
    await DatabaseMethods().findUserWithUID(friendUserUID).then((value) {
      var friendUser = value;
      friendUser['friendList'].add(currentUserUID);
      DatabaseMethods().updateUserDatabase(friendUser);
      Fluttertoast.showToast(msg: '${friendUser['name']} is now your friend.');
    });
    await DatabaseMethods().findUserWithUID(currentUserUID).then((value) {
      var currentUser = value;
      currentUser['friendList'].add(friendUserUID);
      currentUser['pendingRequestList'].removeAt(index);
      DatabaseMethods().updateUserDatabase(currentUser);
    });
  }

  void rejectFriedRequest(currentUserUID, index) async {
    await DatabaseMethods().findUserWithUID(currentUserUID).then((value) {
      var currentUser = value;
      currentUser['pendingRequestList'].removeAt(index);
      DatabaseMethods().updateUserDatabase(currentUser);
    });
  }

  Widget friendRequestTiles(height, width) {
    return StreamBuilder(
      stream: userStream,
      builder: (context, AsyncSnapshot snapshot) {
        print(snapshot.hasData);
        return snapshot.hasData && snapshot.data['pendingRequestList'].length > 0
            ? ListView.builder(
                reverse: true,
                itemCount: snapshot.data['pendingRequestList'].length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return StreamBuilder(
                    stream: DatabaseMethods().getUserSnapshots(
                        snapshot.data['pendingRequestList'][index]),
                    builder: (context, AsyncSnapshot snap) {
                      Map<String, dynamic> friendUser =
                          snap.hasData ? snap.data.data() : {};
                      return snap.hasData
                          ? ListTile(
                              leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.network(friendUser['photoURL'])),
                              title: Text(friendUser['name'],
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,),
                              subtitle: Text(friendUser['email'],
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,),
                              trailing: Wrap(children: [
                                IconButton(
                                    onPressed: () {
                                      acceptFriendRequest(widget.user['uid'],
                                          friendUser['uid'], index);
                                    },
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.green,
                                    )),
                                IconButton(
                                    onPressed: () {
                                      rejectFriedRequest(
                                          widget.user['uid'], index);
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ))
                              ]),
                            )
                          : Container();
                    },
                  );
                },
              )
            : SizedBox(
              height: height,
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.notes_rounded, color: Colors.grey, size: 200,),
                  Text('No friend Requests', style: TextStyle(color: backgroundColor1, fontSize: 20),)
                ],
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: isLoading ? const Loading() : friendRequestTiles(height, width),
    );
  }
}
