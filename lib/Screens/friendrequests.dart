import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';

class FriendRequests extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const FriendRequests({required this.currentUser, Key? key}) : super(key: key);

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
    userStream =
        await DatabaseMethods().getUserSnapshots(widget.currentUser['uid']);
    setState(() {
      isLoading = false;
    });
    print(widget.currentUser);
  }

  Widget friendRequestTiles(height, width) {
    return StreamBuilder(
      stream: userStream,
      builder: (context, AsyncSnapshot snapshot) {
        print(snapshot.hasData);
        return snapshot.hasData &&
                snapshot.data['pendingRequestList'].length > 0
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
                              title: Text(
                                friendUser['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Text(
                                friendUser['email'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              trailing: Wrap(children: [
                                IconButton(
                                    onPressed: () async {
                                      await DatabaseMethods()
                                          .acceptFriendRequest(
                                              widget.currentUser['uid'],
                                              widget.currentUser['name'],
                                              friendUser['uid'])
                                          .then((v) {
                                        Fluttertoast.showToast(
                                            msg:
                                                '${friendUser['name']} is now your friend');
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.green,
                                    )),
                                IconButton(
                                    onPressed: () async {
                                      await DatabaseMethods()
                                          .rejectFriendRequest(
                                              widget.currentUser['uid'], widget.currentUser['name'], 
                                              friendUser['uid']);
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
                    Icon(
                      Icons.notes_rounded,
                      color: Colors.grey,
                      size: 200,
                    ),
                    Text(
                      'No friend Requests',
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
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15))),
        title: Text('Friend Requests'),
      ),
      body: isLoading ? const Loading() : friendRequestTiles(height, width),
    );
  }
}
