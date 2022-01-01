import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Firebase/encryption.dart';
import 'package:neverlost_beta/Screens/group_location.dart';
import 'package:neverlost_beta/Screens/group_profile.dart';
import 'package:neverlost_beta/Screens/uploader.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool shareLoading = true;
  bool isShare = false;
  bool masterShare = false;
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    getGroupinfo();
    super.initState();
  }

  getGroupinfo() {
    DatabaseMethods().getUserSnapshots(widget.user['uid']).listen((event) {
      if (mounted) {
        setState(() {
          masterShare = event.data()!['locShare'];
        });
      }
    });
    DatabaseMethods()
        .groupDetails(widget.groupInfo['id'])
        .listen((event) async {
      isShare = await event.data()!['locSharePermission'][widget.user['uid']];
      shareLoading = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  changeSharePermission() {
    if (masterShare) {
      DatabaseMethods().updateGroupLocSharePermission(
          widget.groupInfo['id'], widget.user['uid'], isShare);
      Fluttertoast.showToast(
          msg: isShare ? 'Location Sharing OFF' : 'Location Sharing ON');
      if (isShare) {
        DatabaseMethods().getUserData(widget.user['uid']).then((value){
          var lat = value.data()!['latitude'];
          var long = value.data()!['longitude'];
          DatabaseMethods().updateLastLocation(widget.groupInfo['id'],widget.user['uid'], lat, long);
        });
      }
      if (!isShare) {
        
      }
    } else {
      Fluttertoast.showToast(msg: 'Turn ON Location Sharing from Settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 80,
        backgroundColor: backgroundColor1,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=>GroupProfile(groupUID: widget.groupInfo['id'],userUID: widget.user['uid'])));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      widget.groupInfo['photoURL'],
                      height: 60,
                      width: 60,
                    )),
              ),
              Flexible(child: Text(widget.groupInfo['name'])),
            ],
          ),
        ),
        actions: [
          PopupMenuButton(
              itemBuilder: (context) => <PopupMenuEntry>[
                    PopupMenuItem(
                      onTap: () {},
                      child: const Text('Invite a friend'),
                    ),
                    PopupMenuItem(
                      onTap: () {},
                      child: const Text('Refresh'),
                    ),
                  ])
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Align(
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
                if (!shareLoading)
                  InkWell(
                    onTap: () {
                      changeSharePermission();
                    },
                    child: Row(
                      children: [
                        const Text(
                          'Share your Location',
                          style: TextStyle(
                              color: backgroundColor2,
                              fontWeight: FontWeight.w400),
                        ),
                        Switch(
                            value: isShare && masterShare,
                            onChanged: (newvalue) {
                              changeSharePermission();
                            }),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GroupChatRoom(user: widget.user, groupInfo: widget.groupInfo),
          GroupLocation(groupUID: widget.groupInfo['id'], userUID: widget.user['uid'])
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

  Future<void> _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image =
        await _picker.pickImage(source: source, imageQuality: 20);
    File? croppedFile = await ImageCropper.cropImage(
      cropStyle:CropStyle.rectangle
        sourcePath: image!.path,
        androidUiSettings: const AndroidUiSettings(
            toolbarTitle: 'Send Image',
            toolbarColor: backgroundColor1,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false),
        iosUiSettings: const IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));

    setState(() {
      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => Uploader(
      //             chatRoomID: widget.chatRoomID,
      //             currentUser: widget.currentUser,
      //             friendUser: widget.friendUser,
      //             image: croppedFile)));
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
      'notSeenBy': widget.groupInfo['users']
          .where((element) => element != widget.user['uid'])
          .toList(),
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
                            if(!sendbyMe) 
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
        : GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: Scaffold(
              body: Stack(
                children: [
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(height: height, child: messageList())),
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
                                  decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter your Message',
                                      hintStyle: TextStyle(color: textColor1)),
                                ),
                              ),
                            ),
                            InkWell(
                          onTap: () {
                            _pickImage(ImageSource.camera);
                          },
                          child: const Icon(Icons.camera_alt_outlined),
                        ),
                        PopupMenuButton(
                            icon: const Icon(Icons.filter),
                            itemBuilder: (context) => <PopupMenuEntry>[
                                  PopupMenuItem(
                                    onTap: () {
                                      _pickImage(ImageSource.gallery);
                                    },
                                    child: const Text('Gallery'),
                                  ),
                                  PopupMenuItem(
                                    onTap: () {
                                      _pickImage(ImageSource.camera);
                                    },
                                    child: const Text('Camera'),
                                  ),
                                ]),
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: backgroundColor1),
                              child: IconButton(
                                  onPressed: () {
                                    sendMessage();
                                  },
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    color: backgroundColor2,
                                  )),
                            )
                          ],
                        )),
                  ),
                ],
              ),
            ),
        );
  }
}
