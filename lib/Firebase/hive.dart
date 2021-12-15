import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

class HiveDB {
  static String userBoxKey = "USERBOXKEY";
  static String userDataKey = "USERDATAKEY";
  static String imageBoxKey = "IMAGEBOXKEY";
  static String imageDataKey = "IMAGEDATAKEY";

  getUserData() async {
    var userBox = await Hive.openBox(userBoxKey);
    var userBoxData = userBox.get(userDataKey);
    Map<String, dynamic> userData = {'uid': userBoxData['uid']};
    return userData;
  }

  deleteData() async {
    var userBox = await Hive.openBox(userBoxKey);
    var imageBox = await Hive.openBox(imageBoxKey);
    userBox.deleteFromDisk();
    imageBox.deleteFromDisk();
  }

  updateUserData(userData) async {
    Map<String, dynamic> temp = {'uid': userData['uid']};
    var userBox = await Hive.openBox(userBoxKey);
    userBox.put(userDataKey, temp);
  }

  setProPicData(image) async {
    var imageBox = await Hive.openBox(imageBoxKey);
    imageBox.put(imageDataKey, image);
  }

  getProPic() async {
    var imageBox = await Hive.openBox(imageBoxKey);
    return imageBox.get(imageDataKey);
  }
}
