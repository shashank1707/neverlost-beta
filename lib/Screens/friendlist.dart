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
  List searchList = [];
  List listUID = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void refresh() {
    setState(() {
      isLoading = true;
      friendsList = [];
      listUID = [];
    });
    getUserData();
  }

  getUserData() async {
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
        searchList.add(value);
      });
    }
    searchList.sort((a, b) => a['name'].compareTo(b['name']));
    setState(() {
      isLoading = false;
    });
  }

  void searchFriend(text) {
    setState(() {
      searchList = friendsList
          .where((element) =>
              element['name'].toUpperCase().contains(text.toUpperCase()))
          .toList();
    });
  }

  Widget friendList(height, width) {
    return searchList.isNotEmpty
        ? ListView.builder(
            itemCount: searchList.length,
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
                                friendUser: searchList[index])));
                  },
                  leading: InkWell(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          NetworkImage(searchList[index]['photoURL']),
                    ),
                  ),
                  title: Text(searchList[index]['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(searchList[index]['status'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            })
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
                  'No Friend Found',
                  style: TextStyle(color: backgroundColor1, fontSize: 20),
                )
              ],
            ),
          );
    ;
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          backgroundColor: backgroundColor1,
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
          actions: [
            PopupMenuButton(
                itemBuilder: (context) => <PopupMenuEntry>[
                      PopupMenuItem(
                        onTap: () {},
                        child: const Text('Invite a friend'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          refresh();
                        },
                        child: const Text('Refresh'),
                      ),
                    ])
          ],
        ),
        body: isLoading
            ? const Loading()
            : SizedBox(
                height: height,
                width: width,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                          color: backgroundColor1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                searchFriend(value);
                              },
                              controller: _searchController,
                              style: const TextStyle(color: textColor1),
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Search in Friend List',
                                  hintStyle: TextStyle(color: textColor1)),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                                _searchController.text == ''
                                    ? Icons.search
                                    : Icons.close_rounded,
                                color: textColor1),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchList = friendsList;
                                searchList.sort(
                                    (a, b) => a['name'].compareTo(b['name']));
                              });
                            },
                          )
                        ],
                      ),
                    ),
                    Expanded(child: friendList(height, width))
                  ],
                ),
              ));
  }
}
