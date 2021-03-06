import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:neverlost_beta/Firebase/encryption.dart';
class CreateNewGroup extends StatefulWidget {
  final Map<String, dynamic> user;
  const CreateNewGroup({required this.user, Key? key}) : super(key: key);

  @override
  _CreateNewGroupState createState() => _CreateNewGroupState();
}

class _CreateNewGroupState extends State<CreateNewGroup> {
  List addedPeopleList = [];
  List friendList = [];
  List searchList = [];
  Map<String,bool> locSharePermission = {};
  Map<String,List<dynamic>> lastLocation = {};
  late File groupIcon ;
  String groupIconPath = '';
  Map<String, dynamic> user = {};

  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    await DatabaseMethods().findUserWithUID(widget.user['uid']).then((value) {
      setState(() {
        user = value;
        isLoading = false;
      });
    }).then((value) {
      createFriendList();
    });
  }

  void createFriendList() async {
    for (int i = 0; i < user['friendList'].length; i++) {
      await DatabaseMethods()
          .findUserWithUID(user['friendList'][i])
          .then((value) {
        friendList.add(value);
        searchList.add(value);
      });
    }
    setState(() {});
  }

  void saveGroup() async {
    if (!addedPeopleList.contains(widget.user['uid'])) {
      addedPeopleList.add(widget.user['uid']);
      locSharePermission.putIfAbsent(widget.user['uid'], () => false);
      lastLocation.putIfAbsent(widget.user['uid'], () => [0,0,DateTime.now()]);
    }

    String groupName = _nameController.text.trim();
    Map<String, dynamic> groupInfo = {
      'name': groupName,
      'photoURL': '',
      'lastMessage': Encryption().encrypt('Created a group'),
      'users': addedPeopleList,
      'locSharePermission' : locSharePermission,
      'lastLocation':lastLocation,
      'admin': widget.user['uid'],
      'timestamp': DateTime.now(),
      'sender': widget.user['uid'],
      'senderName': widget.user['name']
    };
    if (groupName != '' && groupIconPath != '' && addedPeopleList.length > 1) {
      DatabaseMethods().createGroup(groupInfo).then((value) {
        DatabaseMethods().updateGroupIcon(groupIconPath,value);
        Navigator.pop(context);
      });
    }
  }

  Widget friendListTiles() {
    return ListView.builder(
      itemCount: searchList.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        var friendUser = searchList[index];
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: ListTile(
            onTap: () {
              if (addedPeopleList.contains(friendUser['uid'])) {
                addedPeopleList.remove(friendUser['uid']);
                locSharePermission.remove(friendUser['uid']);
                lastLocation.remove(friendUser['uid']);
              } else {
                addedPeopleList.add(friendUser['uid']);
                locSharePermission.putIfAbsent(friendUser['uid'], () => false);
                lastLocation.putIfAbsent(friendUser['uid'], () => [0,0,DateTime.now()]);
              }
              setState(() {});
            },
            leading: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(friendUser['photoURL'])),
            title: Text(friendUser['name'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(friendUser['email'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: addedPeopleList.contains(friendUser['uid'])
                ? const Icon(Icons.radio_button_checked,
                    color: backgroundColor1)
                : const Icon(
                    Icons.radio_button_off,
                    color: Colors.grey,
                  ),
          ),
        );
      },
    );
  }

  void searchFriend(text) {
    setState(() {
      searchList = friendList
          .where((element) =>
              element['name'].toUpperCase().contains(text.toUpperCase()))
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 20);
    if(image!=null)
    { 
      String _imageFile = image.path;
      File? croppedFile = await ImageCropper.cropImage(
      cropStyle:CropStyle.circle
        sourcePath: _imageFile,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        androidUiSettings: const AndroidUiSettings(
            toolbarTitle: 'Set Group Icon',
            toolbarColor: backgroundColor1,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true),
        iosUiSettings: const IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
        if(croppedFile!=null){
          setState(() {
            groupIcon = croppedFile;
            groupIconPath = croppedFile.path;
          });
        }
    }
    
  }
  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return isLoading
        ? const Loading()
        : Scaffold(
            appBar: AppBar(
              backgroundColor: backgroundColor1,
              elevation: 0,
              title: const Text('Create Group'),
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15))),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: backgroundColor2),
                    )),
                TextButton(
                    onPressed:
                      (groupIconPath.isNotEmpty && _nameController.text.trim().isNotEmpty) ? ()=> saveGroup() : null
                    ,
                    child: Text(
                      'Done',
                      style: TextStyle(
                          color: _nameController.text.trim() != ''
                              ? backgroundColor2
                              : textColor1),
                    )),
              ],
            ),
            body: SizedBox(
              height: height,
              width: width,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(15, 8, 0, 0),
                      child: InkWell(
                        onTap: (){
                          _pickImage();
                        },
                        child: groupIconPath==''? CircleAvatar(
                          radius: 70,
                          backgroundColor: backgroundColor1.withOpacity(0.1),
                          child: Text("Choose pic",style: TextStyle(color: textColor1),),
                        ) :CircleAvatar(
                          radius: 70,
                          backgroundImage: FileImage(groupIcon),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 20),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Group Name',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: backgroundColor1,
                              fontSize: 24),
                        )),
                  ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        color: backgroundColor1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      onChanged: (_) {
                        setState(() {});
                      },
                      controller: _nameController,
                      style: const TextStyle(color: textColor1),
                      maxLength: 25,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Group Name',
                          hintStyle: TextStyle(color: textColor1)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add People',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: backgroundColor1,
                              fontSize: 24),
                        )),
                  ),
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
                              searchList = friendList;
                            });
                          },
                        )
                      ],
                    ),
                  ),
                  Expanded(child: friendListTiles())
                ],
              ),
            ),
          );
  }
}
