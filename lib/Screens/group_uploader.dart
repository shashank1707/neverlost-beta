import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Firebase/encryption.dart';

class GroupUploader extends StatefulWidget {
  final image, userUID, userName;
  final Map<String, dynamic> groupInfo;
  const GroupUploader(
      {Key? key,
      required this.image,
      required this.userUID,
      required this.userName,
      required this.groupInfo})
      : super(key: key);

  @override
  _GroupUploaderState createState() => _GroupUploaderState();
}

class _GroupUploaderState extends State<GroupUploader> {
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instanceFor(
          bucket: 'gs://never-lost-643e9.appspot.com');
  _startUpload() async {
    File file = File(widget.image.path);
    try {
      String filepath =
          'Groups/chats/${widget.groupInfo['id']}/${widget.userUID + DateTime.now().toString()}.png';
      await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .putFile(file);
      dynamic image = await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .getDownloadURL();

      sendMessage(image.toString());
    } on firebase_core.FirebaseException catch (e) {
      print('chat gaya');
      return false;
    }
  }

  void sendMessage(String link) async {
    Map<String, dynamic> messageInfo = {
      'message': Encryption().encrypt(link),
      'sender': widget.userUID,
      'senderName': widget.userName,
      'seenBy': [],
      'notSeenBy': widget.groupInfo['users']
          .where((user) => user != widget.userUID)
          .toList(),
      'isImage': true,
      'timestamp': DateTime.now()
    };
    Map<String, dynamic> lastMessageInfo = {
      'lastMessage': Encryption().encrypt(link),
      'sender': widget.userUID,
      'senderName': widget.userName,
      'isImage': true,
      'timestamp': DateTime.now(),
    };
    DatabaseMethods()
        .addGroupMessage(widget.groupInfo['id'], messageInfo, lastMessageInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              child: Image.file(widget.image),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: backgroundColor1,
        onPressed: () {
          _startUpload();
          Navigator.pop(context);
        },
        child: const Icon(
          Icons.send,
          color: backgroundColor2,
        ),
      ),
    );
    //}
  }
}
