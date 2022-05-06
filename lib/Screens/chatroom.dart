import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Screens/chatlocation.dart';
import 'package:neverlost_beta/Screens/chats.dart';
import 'package:neverlost_beta/Screens/userprofile.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatRoom extends StatefulWidget {
  final Map<String, dynamic> currentUser, friendUser;
  const ChatRoom(
      {Key? key, required this.currentUser, required this.friendUser})
      : super(key: key);

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final messageController = TextEditingController();
  late Stream messageStream;
  late String chatRoomID;
  bool isLoading = true;
  bool shareLoading = true;
  late bool isShare = false;
  late dynamic isBlock = {
    widget.currentUser['uid']: false,
    widget.friendUser['uid']: false
  };
  late bool isFriend = false;
  int index = 0;
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    super.initState();
    createChatRoomID().then((value) {
      createChatRoom().then((value) {
        getUserStream();
      });
    });
  }

  // @override
  // void dispose(){
  //   super.dispose();
  // }

  Future createChatRoomID() async {
    List tempList = [
      widget.currentUser['email'].split('@')[0],
      widget.friendUser['email'].split('@')[0]
    ];
    tempList.sort((a, b) => a.compareTo(b));
    setState(() {
      chatRoomID = tempList.join('_');
    });
    return chatRoomID;
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> createChatRoom() async {
    Map lastLocation = {
      widget.currentUser['uid']: [0, 0, DateTime.now()],
      widget.friendUser['uid']: [0, 0, DateTime.now()]
    };
    Map locSharePermission = {
      widget.currentUser['uid']: false,
      widget.friendUser['uid']: false
    };
    Map<String, dynamic> chatRoomInfo = {
      'lastMessage': "Started a ChatRoom",
      'sender': widget.currentUser['email'],
      'receiver': widget.friendUser['email'],
      'lastLocation': lastLocation,
      'locSharePermission': locSharePermission,
      'seen': false,
      'timestamp': DateTime.now(),
      'users': [widget.currentUser['uid'], widget.friendUser['uid']],
      'isImage': false,
      'isFriend': true,
      'block': {
        widget.currentUser['uid']: false,
        widget.friendUser['uid']: false
      }
    };
    await DatabaseMethods().createChatRoom(chatRoomID, chatRoomInfo);
    setState(() {
      isLoading = false;
    });
  }

  changeSharePermission() {
    DatabaseMethods()
        .updatechatLocShare(chatRoomID, widget.currentUser['uid'], isShare);
    Fluttertoast.showToast(
        msg: isShare ? 'Location Sharing OFF' : 'Location Sharing ON');
    if (isShare) {
      DatabaseMethods().getUserData(widget.currentUser['uid']).then((value) {
        var lat = value.data()!['latitude'];
        var long = value.data()!['longitude'];
        DatabaseMethods().updateChatlastLocation(
            chatRoomID, widget.currentUser['uid'], lat, long);
      });
    }
  }

  blockUnblock() {
    DatabaseMethods().blockUnblock(chatRoomID, widget.currentUser['uid'],
        isBlock[widget.currentUser['uid']]);
    Fluttertoast.showToast(
        msg: isBlock[widget.currentUser['uid']]
            ? 'You unblocked this contact'
            : 'You blocked this contact');
  }

  getUserStream() {
    DatabaseMethods().chatRoomDetail(chatRoomID).listen((event) async {
      if (mounted) {
        setState(() {
          isShare =
              event.data()!['locSharePermission'][widget.currentUser['uid']];
          isBlock = event.data()!['block'];
          isFriend = event.data()!['isFriend'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return isLoading
        ? const Loading()
        : Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              toolbarHeight: 80,
              backgroundColor: backgroundColor1,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15))),
              automaticallyImplyLeading: false,
              title: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserProfile(
                              currentUser: widget.currentUser,
                              friendUserUID: widget.friendUser['uid'])));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(
                            widget.friendUser['photoURL'],
                            height: 60,
                            width: 60,
                          )),
                    ),
                    Flexible(child: Text(widget.friendUser['name'])),
                  ],
                ),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      if (widget.friendUser['phone'].length == 10) {
                        _makePhoneCall('tel:${widget.friendUser['phone']}');
                      }
                    },
                    icon: const Icon(Icons.call)),
                PopupMenuButton(
                    itemBuilder: (context) => <PopupMenuEntry>[
                          PopupMenuItem(
                            onTap: () {},
                            child: const Text('Invite a friend'),
                          ),
                          isBlock[widget.currentUser['uid']]!
                              ? PopupMenuItem(
                                  onTap: () {
                                    blockUnblock();
                                  },
                                  child: const Text('Unblock'),
                                )
                              : PopupMenuItem(
                                  onTap: () {
                                    blockUnblock();
                                  },
                                  child: const Text('Block'),
                                ),
                        ])
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 6),
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
                          indicatorPadding:
                              const EdgeInsets.symmetric(horizontal: 5),
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
                                  'Chat',
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
                      if (isFriend &&
                          !isBlock[widget.currentUser['uid']]! &&
                          !isBlock[widget.friendUser['uid']]!)
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
                                  value: isShare,
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
                Chats(
                  currentUser: widget.currentUser,
                  friendUser: widget.friendUser,
                  chatRoomID: chatRoomID,
                ),
                (isFriend &&
                        !isBlock[widget.currentUser['uid']]! &&
                        !isBlock[widget.friendUser['uid']]!)
                    ? LocationPage(
                        currentUID: widget.currentUser['uid'],
                        friendUID: widget.friendUser['uid'],
                        chatRoomID: chatRoomID,
                      )
                    : Loading()
              ],
            ),
          );
  }
}
