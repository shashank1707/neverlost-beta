import 'package:hive_flutter/hive_flutter.dart';

class HiveDB {
  static String userBoxKey = "USERBOXKEY";
  static String userDataKey = "USERDATAKEY";
  static String imageBoxKey = "IMAGEBOXKEY";
  static String imageDataKey = "IMAGEDATAKEY";
  getUserData() async {
    var userBox = await Hive.openBox(userBoxKey);
    var userBoxData = userBox.get(userDataKey);
    Map<String, dynamic> userData = {
      'name': userBoxData['name'],
      'email': userBoxData['email'],
      'uid': userBoxData['uid'],
      'photoURL': userBoxData['photoURL'],
      'phone': userBoxData['phone'],
      'status': userBoxData['status']
    };
    return userData;
  }

  deleteData() async {
    var userBox = await Hive.openBox(userBoxKey);
    userBox.deleteFromDisk();
  }

  updateUserData(userBoxData) async {
    var userBox = await Hive.openBox(userBoxKey);
    Map<String, dynamic> userData = {
      'name': userBoxData['name'],
      'email': userBoxData['email'],
      'uid': userBoxData['uid'],
      'photoURL': userBoxData['photoURL'],
      'phone': userBoxData['phone'],
      'status': userBoxData['status']
    };
    userBox.put(userDataKey, userData);
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
