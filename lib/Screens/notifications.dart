import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';

class Notifications extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const Notifications({required this.currentUser, Key? key}) : super(key: key);

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  late Stream userStream;
  bool isLoading = true;
  Map<String, dynamic> currentUser = {};

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    await DatabaseMethods().findUserWithUID(widget.currentUser['uid']).then((user) {
        setState(() {
          currentUser = user;
        });
      });
    getCurrentUserSnapshots();
  }

  void getCurrentUserSnapshots() async {
    userStream =
        await DatabaseMethods().getUserSnapshots(widget.currentUser['uid']);
    setState(() {
      isLoading = false;
    });
    print(widget.currentUser);
  }

  void deleteNotifications() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Clear Notifications',style: TextStyle(color: backgroundColor1)),
            content:
                const Text('All the notifications will be deleted permanently.'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: textColor1))),
              TextButton(
                  onPressed: () async {
                    currentUser['notifications'] = [];
                    await DatabaseMethods().updateUserDatabase(currentUser);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm',
                      style: TextStyle(color: backgroundColor1))),
            ],
          );
        });
  }

  Icon getNotificationIcon(type) {
    if (type == 'accept') {
      return const Icon(
        Icons.person_add,
        color: themeColor1,
      );
    } else if (type == 'reject') {
      return const Icon(
        Icons.person_add_disabled_rounded,
        color: textColor1,
      );
    } else if (type == 'unfriend') {
      return const Icon(
        Icons.person_off,
        color: Colors.redAccent,
      );
    }

    return const Icon(Icons.notifications_active_outlined);
  }

  Widget notificationTiles(height, width) {
    return StreamBuilder(
      stream: userStream,
      builder: (context, AsyncSnapshot snapshot) {
        print(snapshot.hasData);
        return snapshot.hasData && snapshot.data['notifications'].length > 0
            ? ListView.builder(
                reverse: true,
                itemCount: snapshot.data['notifications'].length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  currentUser['notifications'][index]['seen'] = true;
                  DatabaseMethods().updateUserDatabase(currentUser);
                  return ListTile(
                    leading: getNotificationIcon(
                        currentUser['notifications'][index]['type']),
                    title: RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(children: [
                        TextSpan(
                            text:
                                "${snapshot.data['notifications'][index]['name']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        TextSpan(
                            text:
                                " ${snapshot.data['notifications'][index]['message']}",
                            style: const TextStyle(color: Colors.black)),
                      ]),
                    ),
                  );
                },
              )
            : SizedBox(
                height: height,
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.notes_rounded,
                      color: Colors.grey,
                      size: 200,
                    ),
                    Text(
                      'No New Notifications',
                      style: TextStyle(color: backgroundColor1, fontSize: 20),
                    )
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
      appBar: AppBar(
        backgroundColor: backgroundColor1,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              deleteNotifications();
            },
          )
        ],
      ),
      body: isLoading ? const Loading() : notificationTiles(height, width),
    );
  }
}
