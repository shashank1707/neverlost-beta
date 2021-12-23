import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Screens/chatroom.dart';

class UserProfile extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final String friendUserUID;

  const UserProfile(
      {required this.currentUser, required this.friendUserUID, Key? key})
      : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool isLoading = true;
  Map<String, dynamic> currentUser = {};

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    await DatabaseMethods()
        .findUserWithUID(widget.currentUser['uid'])
        .then((user) {
      setState(() {
        currentUser = user;
      });
    });
    updateRecentSearchList();
  }

  void updateRecentSearchList() async {
    if (!currentUser['recentSearchList']
        .contains(widget.friendUserUID)) {
      currentUser['recentSearchList'].add(widget.friendUserUID);
    }

    await DatabaseMethods().updateUserDatabase(currentUser);
    setState(() {
      isLoading = false;
    });
  }

  String getFriendStatus(userProfile) {
    if (userProfile['friendList'].contains(currentUser['uid'])) {
      return 'Unfriend';
    } else if (userProfile['pendingRequestList']
        .contains(currentUser['uid'])) {
      return 'Request Sent';
    } else if (currentUser['pendingRequestList']
        .contains(userProfile['uid'])) {
      return 'Accept Request';
    } else {
      return 'Add Friend';
    }
  }

  void friendButton(userProfile) async {
    if (getFriendStatus(userProfile) == 'Add Friend') {
      await DatabaseMethods()
          .sendFriendRequest(currentUser['uid'], widget.friendUserUID);
    } else if (getFriendStatus(userProfile) == 'Unfriend') {
      await DatabaseMethods().unFriend(currentUser['uid'],
          currentUser['name'], widget.friendUserUID);
    } else if (getFriendStatus(userProfile) == 'Accept Request') {
      await DatabaseMethods().acceptFriendRequest(currentUser['uid'],
          currentUser['name'], widget.friendUserUID);
    }
    getCurrentUser();
  }

  void showPhoto(height, width, userProfile) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return InteractiveViewer(
            child: SimpleDialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                children: [
                  Container(
                    height: width,
                    width: width,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage(userProfile['photoURL']),
                            fit: BoxFit.fitWidth)),
                  ),
                ]),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return isLoading
        ? Loading()
        : Scaffold(
            backgroundColor: backgroundColor2,
            appBar: AppBar(
              backgroundColor: backgroundColor1,
              elevation: 0,
              title: Text('Profile'),
            ),
            body: StreamBuilder(
              stream: DatabaseMethods().getUserSnapshots(widget.friendUserUID),
              builder: (context, AsyncSnapshot snapshot) {
                var userProfile = snapshot.hasData ? snapshot.data.data() : {};
                return !snapshot.hasData
                    ? Loading()
                    : SizedBox(
                        height: height,
                        width: width,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                  color: backgroundColor1,
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(15))),
                              width: width,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        showPhoto(height, width, userProfile);
                                      },
                                      child: Container(
                                        height: width / 3,
                                        width: width / 3,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image: NetworkImage(
                                                    userProfile['photoURL']),
                                                fit: BoxFit.fitWidth)),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    userProfile['name'],
                                    style: const TextStyle(
                                        color: backgroundColor2,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        MaterialButton(
                                          onPressed: () {
                                            friendButton(userProfile);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                color: backgroundColor2,
                                                border: Border.all(
                                                    width: 2,
                                                    color: backgroundColor2),
                                                borderRadius:
                                                    BorderRadius.circular(100)),
                                            child: Text(
                                              getFriendStatus(userProfile),
                                              style: TextStyle(
                                                  color: backgroundColor1),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible: userProfile['friendList']
                                              .contains(
                                                  currentUser['uid']),
                                          child: MaterialButton(
                                            onPressed: userProfile['friendList']
                                                    .contains(widget
                                                        .currentUser['uid'])
                                                ? () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                ChatRoom(
                                                                    currentUser:
                                                                        widget
                                                                            .currentUser,
                                                                    friendUser:
                                                                        userProfile)));
                                                  }
                                                : null,
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: backgroundColor2,
                                                      width: 2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100)),
                                              child: Text(
                                                'Message',
                                                style: TextStyle(
                                                    color: backgroundColor2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.email_outlined,
                                color: textColor1,
                              ),
                              title: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Email',
                                  style: TextStyle(
                                      color: textColor1,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                              subtitle: Text(
                                userProfile['email'],
                                style: const TextStyle(
                                    color: textColor2,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                            Visibility(
                              visible: userProfile['friendList']
                                  .contains(currentUser['uid']),
                              child: Column(
                                children: [
                                  ListTile(
                                      leading: const Icon(
                                        Icons.insert_emoticon,
                                        color: textColor1,
                                      ),
                                      title: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                              color: textColor1,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400),
                                        ),
                                      ),
                                      subtitle: Text(
                                        userProfile['status'],
                                        style: const TextStyle(
                                            color: textColor2,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      )),
                                  ListTile(
                                      leading: const Icon(
                                        Icons.call,
                                        color: textColor1,
                                      ),
                                      title: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text(
                                          'Phone',
                                          style: TextStyle(
                                              color: textColor1,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400),
                                        ),
                                      ),
                                      subtitle: Text(
                                        userProfile['phone'],
                                        style: const TextStyle(
                                            color: textColor2,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
              },
            ),
          );
  }
}
