import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/auth.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Screens/signin.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';

class Profile extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const Profile({required this.currentUser, Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  Map<String, dynamic> currentUser = {};
  bool isLoading = true;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    DatabaseMethods().getUserSnapshots(widget.currentUser['uid']).listen((user) {
        setState(() {
          currentUser = user.data()!;
          phoneController.text = currentUser['phone'];
          statusController.text = currentUser['status'];
          nameController.text = currentUser['name'];
          isLoading = false;
        });
      });
    
  }

  void showPhoto(height, width) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return InteractiveViewer(
            child: SimpleDialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                children: [
                  Container(
                    height: width,
                    width: width,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage(widget.currentUser['photoURL']),
                            fit: BoxFit.fitWidth)),
                  ),
                ]),
          );
        });
  }

  void changePhoneNumber() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: backgroundColor2,
            title: const Text('Phone Number',
                style: TextStyle(color: backgroundColor1)),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: textColor1))),
              TextButton(
                  onPressed: () {
                    var userData = currentUser;
                    userData['phone'] = phoneController.text;
                    DatabaseMethods().updateUserDatabase(userData).then((v) {
                      Navigator.pop(context);
                    });
                  },
                  child: const Text('Save',
                      style: TextStyle(color: backgroundColor1))),
            ],
            content: Container(
              decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(width: 2, color: textColor1))),
              child: TextField(
                maxLength: 10,
                controller: phoneController,
                style: const TextStyle(color: backgroundColor1),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    helperStyle: TextStyle(color: textColor1)),
              ),
            ),
          );
        });
  }

  void changeStatus() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: backgroundColor2,
            title:
                const Text('Status', style: TextStyle(color: backgroundColor1)),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: textColor1))),
              TextButton(
                  onPressed: () {
                    var userData = currentUser;
                    userData['status'] = statusController.text;
                    DatabaseMethods().updateUserDatabase(userData).then((v) {
                      Navigator.pop(context);
                    });
                  },
                  child: const Text('Save',
                      style: TextStyle(color: backgroundColor1))),
            ],
            content: Container(
              decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(width: 2, color: textColor1))),
              child: TextField(
                minLines: 1,
                maxLines: 5,
                maxLength: 139,
                controller: statusController,
                style: const TextStyle(color: backgroundColor1),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    helperStyle: TextStyle(color: textColor1)),
              ),
            ),
          );
        });
  }

  void changeName() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: backgroundColor2,
            title:
                const Text('Name', style: TextStyle(color: backgroundColor1)),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: textColor1))),
              TextButton(
                  onPressed: () {
                    var userData = currentUser;
                    userData['name'] = nameController.text;
                    DatabaseMethods().updateUserDatabase(userData).then((v) {
                      Navigator.pop(context);
                    });
                  },
                  child: const Text('Save',
                      style: TextStyle(color: backgroundColor1))),
            ],
            content: Container(
              decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(width: 2, color: textColor1))),
              child: TextField(
                minLines: 1,
                maxLines: 5,
                maxLength: 25,
                controller: nameController,
                style: const TextStyle(color: backgroundColor1),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    helperStyle: TextStyle(color: textColor1)),
              ),
            ),
          );
        });
  }

  void showSignoutDialogue() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: backgroundColor2,
            title: const Text('Sign Out',
                style: TextStyle(color: backgroundColor1)),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: textColor1))),
              TextButton(
                  onPressed: () {
                    AuthMethods().signout().then((value) {
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const Signin()),
                          (route) => false);
                    });
                  },
                  child: const Text('Confirm',
                      style: TextStyle(color: backgroundColor1))),
            ],
            content: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Text('You will be redirected to the Sign In screen.', style: TextStyle(color: backgroundColor1),),
            ),
          );
        });
  }
  
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image =
        await _picker.pickImage(source: source, imageQuality: 20);
   if(image!=null)
   { String _imageFile = image.path;
    File? croppedFile = await ImageCropper.cropImage(
      cropStyle:CropStyle.circle
        sourcePath: _imageFile,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        androidUiSettings: const AndroidUiSettings(
            toolbarTitle: 'Set Profile Picture',
            toolbarColor: backgroundColor1,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true),
        iosUiSettings: const IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
        if(croppedFile!=null){
        Fluttertoast.showToast(msg: 'Profile Picture Updating');

          var val =
        await DatabaseMethods().changeProfilePhoto(croppedFile.path, currentUser['uid']);
        Fluttertoast.showToast(msg: 'Profile Picture Updated');
        return val;
    }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return isLoading ? const Loading() : Scaffold(
      backgroundColor: backgroundColor2,
      appBar: AppBar(
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: backgroundColor1,
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          TextButton.icon(
              onPressed: () {
                showSignoutDialogue();
              },
              icon: const Icon(
                Icons.logout,
                color: backgroundColor2,
              ),
              label: const Text(
                'Signout',
                style: TextStyle(color: backgroundColor2),
              ))
        ],
      ),
      body: SizedBox(
        height: height,
        width: width,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: const BoxDecoration(
                  color: backgroundColor1,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(15))),
              width: width,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: backgroundColor1,
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return Container(
                                        height: height,
                                        width: width,
                                        color: Colors.black,
                                        child: SimpleDialog(
                                            backgroundColor: Colors.black,
                                            children: [
                                              Container(
                                                width: width,
                                                height: width,
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: NetworkImage(currentUser['photoURL']),
                                                        fit: BoxFit.fitWidth)),
                                              )
                                              
                                            ]),
                                      );
                                    });
                              },
                              icon: const Icon(
                                Icons.photo,
                              ),
                              label: const Text(
                                'View',
                                style: TextStyle(color: backgroundColor2),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _pickImage(ImageSource.gallery)
                                    .then((value) {});
                              },
                              icon: const Icon(
                                Icons.photo_library,
                              ),
                              label: const Text(
                                'Gallery',
                                style: TextStyle(color: backgroundColor2),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _pickImage(ImageSource.camera);
                              },
                              icon: const Icon(
                                Icons.camera,
                              ),
                              label: const Text(
                                'Camera',
                                style: TextStyle(color: backgroundColor2),
                              ),
                            ),
                          ],
                        ),
                      ));
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                        width: width/3,
                        height: width/3,
                        decoration:BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image: NetworkImage(currentUser['photoURL']),fit: BoxFit.fitWidth)
                        )
                    ),
                      ),
                  ),                 
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: width / 1.85,
                          child: Text(
                            currentUser['name'],
                            style: const TextStyle(
                                color: backgroundColor2,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                softWrap: true,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 50,
                        // alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: backgroundColor2,
                          ),
                          onPressed: () {
                            changeName();
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            ListTile(
              leading: const Icon(
                Icons.email_outlined,
                color: textColor1,
              ),
              title: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Email',
                  style: TextStyle(
                      color: textColor1,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                ),
              ),
              subtitle: Text(
                currentUser['email'],
                style: const TextStyle(
                    color: textColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.w400),
              ),
            ),
            ListTile(
              onTap: () {
                changePhoneNumber();
              },
              leading: const Icon(
                Icons.call,
                color: textColor1,
              ),
              title: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Phone',
                  style: TextStyle(
                      color: textColor1,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                ),
              ),
              subtitle: Text(
                currentUser['phone'],
                style: const TextStyle(
                    color: textColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.w400),
              ),
              trailing: const Icon(
                Icons.edit,
                color: textColor1,
              ),
            ),
            ListTile(
              onTap: () {
                changeStatus();
              },
              leading: const Icon(
                Icons.insert_emoticon,
                color: textColor1,
              ),
              title: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Status',
                  style: TextStyle(
                      color: textColor1,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                ),
              ),
              subtitle: Text(
                currentUser['status'],
                style: const TextStyle(
                    color: textColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.w400),
              ),
              trailing: const Icon(
                Icons.edit,
                color: textColor1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
