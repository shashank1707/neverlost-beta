import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
class Chats extends StatefulWidget {
  final currentUser, friendUser,chatRoomID;
  const Chats({Key? key, required this.currentUser, required this.friendUser,required this.chatRoomID})
      : super(key: key);

  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  final _messageController = TextEditingController();
  late Stream messageStream;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
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

  void sendMessage() async {
    Map<String, dynamic> messageInfo = {
      'message': _messageController.text.trim(),
      'sender': widget.currentUser['email'],
      'receiver': widget.friendUser['email'],
      'seen': false,
      'isImage': false,
      'timestamp': DateTime.now()
    };
    Map<String, dynamic> lastMessageInfo = {
      'lastMessage': _messageController.text,
      'sender': widget.currentUser['email'],
      'receiver': widget.friendUser['email'],
      'seen': false,
      'isImage': false,
      'timestamp': DateTime.now(),
    };
    DatabaseMethods().addMessage(widget.chatRoomID, messageInfo, lastMessageInfo);
    _messageController.clear();
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

  Widget messageList() {
    return StreamBuilder(
      stream: DatabaseMethods().getMessages(widget.chatRoomID),
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: const EdgeInsets.only(bottom: 70),
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                reverse: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  bool sendbyMe = ds['sender'] == widget.currentUser['email'];
                  bool isUrl = Uri.parse(ds['message']).isAbsolute;
                  if (!sendbyMe) {
                    DatabaseMethods().updateSeenInfo(widget.chatRoomID, ds.id);
                  }
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    alignment:
                        sendbyMe ? WrapAlignment.end : WrapAlignment.start,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        child: InkWell(
                          onLongPress: () {
                            Clipboard.setData(
                                ClipboardData(text: ds['message']));
                            Fluttertoast.showToast(msg: 'Copied to Clipboard');
                          },
                          onTap: () {
                            if (isUrl) {
                              _launchInBrowser(ds['message']);
                            }
                          },
                          child: ds['isImage'] == true
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(ds['message']))
                              : Text(
                                  ds['message'],
                                  style: TextStyle(
                                      decoration: isUrl
                                          ? TextDecoration.underline
                                          : TextDecoration.none,
                                      fontSize: 16,
                                      color: sendbyMe
                                          ? backgroundColor2
                                          : backgroundColor1),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 8),
                        child: Visibility(
                          visible: sendbyMe,
                          child: Icon(
                            ds['seen']
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: ds['seen'] ? backgroundColor1 : Colors.grey,
                            size: 15,
                          ),
                        ),
                      )
                    ],
                  );
                },
              )
            : const Loading();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Align(alignment: Alignment.bottomCenter, child: messageList()),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  color: backgroundColor2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            shape: BoxShape.circle, color: backgroundColor1),
                        child: IconButton(
                            onPressed: () {
                              if (_messageController.text.trim().isNotEmpty) {
                                sendMessage();
                              } else {
                                _messageController.clear();
                              }
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
