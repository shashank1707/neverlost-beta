import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';

import 'chatroom.dart';

class FriendsList extends StatefulWidget {
  final currentUser;
  const FriendsList({Key? key, required this.currentUser}) : super(key: key);

  @override
  _FriendsListState createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  late Stream userStream;
  bool isLoading = true;
  List friendsList = [];
  List listUID = [];
  @override
  void initState() {
    super.initState();
    getUSerData();
  }

  void refresh() {
    setState(() {
      isLoading = true;
      friendsList = [];
      listUID = [];
    });
    getUSerData();
  }

  getUSerData() async {
    await DatabaseMethods()
        .findUserWithUID(widget.currentUser['uid'])
        .then((value) {
      setState(() {
        listUID = value['friendList'];
      });
    }).then((v) {
      getfriendDetails(listUID);
    });
  }

  getfriendDetails(listUID) async {
    for (int i = 0; i < listUID.length; i++) {
      await DatabaseMethods().findUserWithUID(listUID[i]).then((value) {
        friendsList.add(value);
      });
    }
    friendsList.sort((a, b) => a['name'].compareTo(b['name']));
    setState(() {
      isLoading = false;
    });
  }

  Widget friendList(friendsList) {
    return ListView.builder(
        itemCount: friendsList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatRoom(
                            currentUser: widget.currentUser,
                            friendUser: friendsList[index])));
              },
              leading: InkWell(
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(friendsList[index]['photoURL']),
                ),
              ),
              title: Text(friendsList[index]['name'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(friendsList[index]['status'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Friends'),
          backgroundColor: backgroundColor1,
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.search)),
            PopupMenuButton(
                itemBuilder: (context) => <PopupMenuEntry>[
                      PopupMenuItem(
                        onTap: () {},
                        child: Text('Invite a friend'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          refresh();
                        },
                        child: Text('Refresh'),
                      ),
                    ])
          ],
        ),
        body: isLoading ? Loading() : friendList(friendsList));
  }
}
