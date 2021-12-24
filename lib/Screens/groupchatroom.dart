import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Firebase/encryption.dart';

class GroupChatRoomBar extends StatefulWidget {
  final Map<String, dynamic> user, groupInfo;
  const GroupChatRoomBar(
      {Key? key, required this.user, required this.groupInfo})
      : super(key: key);
  @override
  _GroupChatRoomBarState createState() => _GroupChatRoomBarState();
}

class _GroupChatRoomBarState extends State<GroupChatRoomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor1,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
        leading: Icon(Icons.people_alt_outlined, size: 28),
        title: Text(widget.groupInfo['name']),
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
                        'Location',
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
          GroupChatRoom(user: widget.user, groupInfo: widget.groupInfo),
          Loading()
        ],
      ),
    );
  }
}

class GroupChatRoom extends StatefulWidget {
  final Map<String, dynamic> user, groupInfo;
  const GroupChatRoom({Key? key, required this.user, required this.groupInfo})
      : super(key: key);

  @override
  _GroupChatRoomState createState() => _GroupChatRoomState();
}

class _GroupChatRoomState extends State<GroupChatRoom> {
  final _messageController = TextEditingController();
  late Stream messageStream;
  bool isLoading = true;

  @override
  void initState() {
    getMessages();
    super.initState();
  }

  void getMessages() async {
    messageStream =
        await DatabaseMethods().getGroupMessages(widget.groupInfo['id']);
    setState(() {
      isLoading = false;
    });
  }

  void sendMessage() async {
    _messageController.text = _messageController.text.trim();

    Map<String, dynamic> lastMessageInfo = {
      'lastMessage': Encryption().encrypt(_messageController.text),
      'sender': widget.user['uid'],
      'senderName': widget.user['name'],
      'timestamp': DateTime.now(),
    };

    Map<String, dynamic> messageInfo = {
      'message': Encryption().encrypt(_messageController.text),
      'sender': widget.user['uid'],
      'senderName': widget.user['name'],
      'seenBy': [],
      'notSeenBy': widget.groupInfo['users'].where((element) => element != widget.user['uid']).toList(),
      'timestamp': DateTime.now()
    };
    if (_messageController.text != '') {
      DatabaseMethods().addGroupMessage(
          widget.groupInfo['id'], messageInfo, lastMessageInfo);
      _messageController.clear();
    }
  }

  Widget messageList() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(bottom: 70),
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                reverse: true,
                itemBuilder: (context, index) {
                  Map<String, dynamic> ds = snapshot.data.docs[index].data();
                  print(ds);
                  ds['id'] = snapshot.data.docs[index].id;
                  bool sendbyMe = ds['sender'] == widget.user['uid'];
                  if (!sendbyMe) {
                    List seenBy = ds['seenBy'];
                    List notSeenBy = ds['notSeenBy'];

                    if (!seenBy.contains(widget.user['uid'])) {
                      seenBy.add(widget.user['uid']);
                    }
                    if (!notSeenBy.contains(widget.user['uid'])) {
                      notSeenBy.remove(widget.user['uid']);
                    }
                    notSeenBy.remove(widget.user['uid']);

                    Map<String, dynamic> info = {
                      'seenBy': seenBy,
                      'notSeenBy': notSeenBy
                    };

                    DatabaseMethods().updateGroupSeenInfo(
                        widget.groupInfo['id'], ds['id'], info);
                  }
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    alignment:
                        sendbyMe ? WrapAlignment.end : WrapAlignment.start,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: EdgeInsets.only(
                            top: 8,
                            bottom: 8,
                            left: sendbyMe ? 50 : 8,
                            right: sendbyMe ? 8 : 50),
                        decoration: BoxDecoration(
                            color: sendbyMe
                                ? backgroundColor1
                                : backgroundColor1.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ds['senderName'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: sendbyMe
                                      ? backgroundColor2.withOpacity(0.7)
                                      : backgroundColor1.withOpacity(0.7)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SelectableText(
                                Encryption().decrypt(ds['message']),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: sendbyMe
                                        ? backgroundColor2
                                        : backgroundColor1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(bottom: 8, right: 8),
                      //   child: Visibility(
                      //     visible: sendbyMe,
                      //     child: Icon(
                      //       ds['seen']
                      //           ? Icons.check_circle
                      //           : Icons.check_circle_outline,
                      //       color: ds['seen'] ? backgroundColor1 : Colors.grey,
                      //       size: 15,
                      //     ),
                      //   ),
                      // )
                    ],
                  );
                },
              )
            : Loading();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return isLoading
        ? Loading()
        : Scaffold(
            body: Stack(
              children: [
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: height,
                      child: messageList())),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      color: backgroundColor2,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(8),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: backgroundColor1.withOpacity(0.1)),
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter your Message',
                                    hintStyle: TextStyle(color: textColor1)),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: backgroundColor1),
                            child: IconButton(
                                onPressed: () {
                                  sendMessage();
                                },
                                icon: Icon(
                                  Icons.send_rounded,
                                  color: backgroundColor2,
                                )),
                          )
                        ],
                      )),
                ),
              ],
            ),
          );
  }
}
