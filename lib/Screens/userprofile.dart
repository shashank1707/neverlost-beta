import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfile extends StatefulWidget {
  final currentUser, searchedUser;
  const UserProfile(
      {Key? key, required this.currentUser, required this.searchedUser})
      : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool isfriend = false;
  bool isLoading = true;
  @override
  void initState() {
    getData();
    super.initState();
  }

  void getData() async {
    await DatabaseMethods()
        .findUserWithUID(widget.searchedUser['uid'])
        .then((value) {
      isLoading = false;
      print(value['friendList']);
      for (var i = 0; i < value['friendList'].length; i++) {
        if (value['friendList'][i] == widget.currentUser['uid']) {
          isfriend = true;
          break;
        }
      }
      setState(() {});
    });
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _makeSMS(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<bool> unFriend() async {
    await DatabaseMethods()
        .unFriend(widget.currentUser['uid'], widget.searchedUser['uid']);
    return true;
  }

  Future<bool> sendFriendRequest() async {
    await DatabaseMethods().sendFriendRequest(
        widget.currentUser['uid'],
        widget.currentUser['email'],
        widget.currentUser['photoURL'],
        widget.currentUser['name'],
        widget.searchedUser['uid']);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return isLoading
        ? const Loading()
        : Scaffold(
            backgroundColor: backgroundColor2,
            appBar: AppBar(
              backgroundColor: backgroundColor1,
              shadowColor: Colors.transparent,
            ),
            body: SizedBox(
              height: height,
              width: width,
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        color: backgroundColor1,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25))),
                    width: width,
                    height: 220,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return SimpleDialog(
                                      backgroundColor: Colors.transparent,
                                      children: [
                                        Container(
                                          width: width,
                                          height: width,
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: NetworkImage(
                                                      widget.searchedUser[
                                                          'photoURL']),
                                                  fit: BoxFit.fitWidth)),
                                        ),
                                      ]);
                                });
                          },
                          child: SizedBox(
                            height: 100,
                            width: 100,
                            child: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(widget.searchedUser['photoURL']),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 8),
                          child: Text(
                            widget.searchedUser['name'],
                            style: const TextStyle(
                                color: backgroundColor2, fontSize: 20),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                                onPressed: () async {
                                  if (isfriend) {
                                    await unFriend();
                                    isfriend = false;
                                    setState(() {});
                                    initState();
                                    return;
                                  } else {
                                    await sendFriendRequest();
                                    setState(() {});
                                    return;
                                  }
                                },
                                icon: Icon(
                                  isfriend
                                      ? Icons.person_remove_alt_1_outlined
                                      : Icons.person_add_alt_outlined,
                                  size: 35,
                                  color: backgroundColor1,
                                )),
                            if (isfriend)
                              IconButton(
                                  onPressed: () {
                                    _makeSMS(
                                        'sms:${widget.searchedUser['phone']}');
                                  },
                                  icon: const Icon(
                                    Icons.message,
                                    size: 35,
                                    color: backgroundColor1,
                                  )),
                            if (isfriend)
                              IconButton(
                                  onPressed: () {
                                    if (widget.searchedUser['phone'].length ==
                                        10)
                                      _makePhoneCall(
                                          'tel:${widget.searchedUser['phone']}');
                                  },
                                  icon: const Icon(
                                    Icons.call,
                                    size: 35,
                                    color: backgroundColor1,
                                  ))
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  ListTile(
                    leading: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.email_outlined,
                        color: backgroundColor1,
                      ),
                    ),
                    title: const Text(
                      'Email',
                      style: TextStyle(color: backgroundColor1),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        widget.searchedUser['email'],
                        style: const TextStyle(color: backgroundColor1),
                      ),
                    ),
                  ),
                  if (isfriend)
                    Column(
                      children: [
                        const Divider(
                          endIndent: 10,
                          indent: 70,
                          color: backgroundColor1,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.phone_android_sharp,
                            color: backgroundColor1,
                          ),
                          title: const Text(
                            'Phone',
                            style: TextStyle(color: backgroundColor1),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              widget.searchedUser['phone'],
                              style: const TextStyle(color: backgroundColor1),
                            ),
                          ),
                        ),
                        const Divider(
                          endIndent: 10,
                          indent: 70,
                          color: backgroundColor1,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.insert_emoticon,
                            color: backgroundColor1,
                          ),
                          title: const Text(
                            'Status',
                            style: TextStyle(color: backgroundColor1),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              widget.searchedUser['status'],
                              style: const TextStyle(color: backgroundColor1),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
  }
}
