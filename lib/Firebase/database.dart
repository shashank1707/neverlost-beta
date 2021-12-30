import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;

class DatabaseMethods {
  final firestore = FirebaseFirestore.instance;

  createUserDatabase(name, email, uid, photoURL, phone) async {
    Map<String, dynamic> user = {
      "name": name,
      "email": email.toLowerCase(),
      "uid": uid,
      "photoURL": photoURL,
      "status": "Hey! Let's Chat!",
      "phone": phone ?? 'Enter your Mobile Number',
      "recentSearchList": [],
      "friendList": [],
      "notifications": [],
      "pendingRequestList": [],
      'latitude': 0.0,
      'longitude': 0.0,
      'locShare': true,
      'lastSeen': DateTime.now()
    };
    await findUserWithEmail(email).then((value) async {
      if (value.isEmpty) {
        await firestore.collection('users').doc(uid).set(user);
      } else {
        user = value;
      }
    });

    return user;
  }

  findUserWithEmail(email) async {
    var user = {};
    await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        user = value.docs[0].data();
      }
    });
    return user;
  }

  findUserWithUID(uid) async {
    dynamic user = {};
    await firestore
        .collection('users')
        .doc(uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        user = documentSnapshot.data();
      } else {
        print('Document does not exist on the database');
      }
    });
    return user;
  }

  updateUserDatabase(userData) async {
    await firestore.collection('users').doc(userData['uid']).update(userData);
  }

  Future<Stream<QuerySnapshot>> searchByName(name) async {
    return firestore
        .collection('users')
        .where('name', isEqualTo: name)
        .snapshots();
  }

  Stream<QuerySnapshot> searchByEmail(email) {
    return firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserSnapshots(uid) {
    return firestore.collection('users').doc(uid).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(uid) async {
    return firestore.collection('users').doc(uid).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> findChatRoom(
      chatRoomID) async {
    return await firestore.collection('chatRooms').doc(chatRoomID).get();
  }

  Future<void> unFriend(currentgroupUID, currentUserName, targetUid) async {
    await firestore
        .collection('users')
        .doc(currentgroupUID)
        .update({
          'friendList': FieldValue.arrayRemove([targetUid])
        })
        .then((value) => print("User's Property Deleted"))
        .catchError(
            (error) => print("Failed to delete user's property: $error"));
    await firestore
        .collection('users')
        .doc(targetUid)
        .update({
          'friendList': FieldValue.arrayRemove([currentgroupUID]),
          'notifications': FieldValue.arrayUnion([
            {
              'type': 'unfriend',
              'name': currentUserName,
              'message': 'removed you as a friend.',
              'seen': false
            }
          ])
        })
        .then((value) => print("User's Property Deleted"))
        .catchError(
            (error) => print("Failed to delete user's property: $error"));
  }

  Future<void> sendFriendRequest(currentgroupUID, targetUID) async {
    return await firestore
        .collection('users')
        .doc(targetUID)
        .update({
          'pendingRequestList': FieldValue.arrayUnion([currentgroupUID])
        })
        .then((value) => print("User's Property Added"))
        .catchError(
            (error) => print("Failed to delete user's property: $error"));
  }

  Future<Stream<DocumentSnapshot<Map<String, dynamic>>>> getFriendRequest(
      uid) async {
    return firestore.collection('users').doc(uid).snapshots();
  }

  Future<void> acceptFriendRequest(
      currentgroupUID, currentUserName, targetgroupUID) async {
    await firestore.collection('users').doc(currentgroupUID).update({
      'pendingRequestList': FieldValue.arrayRemove([targetgroupUID]),
      'friendList': FieldValue.arrayUnion([targetgroupUID])
    });
    await firestore.collection('users').doc(targetgroupUID).update({
      'friendList': FieldValue.arrayUnion([currentgroupUID]),
      'notifications': FieldValue.arrayUnion([
        {
          'type': 'accept',
          'name': currentUserName,
          'message': 'accepted your friend request.',
          'seen': false
        }
      ])
    });
  }

  Future<void> rejectFriendRequest(
      currentgroupUID, currentUserName, targetgroupUID) async {
    await firestore.collection('users').doc(currentgroupUID).update({
      'pendingRequestList': FieldValue.arrayRemove([targetgroupUID])
    });

    await firestore.collection('users').doc(targetgroupUID).update({
      'notifications': FieldValue.arrayUnion([
        {
          'type': 'reject',
          'name': currentUserName,
          'message': 'rejected your friend request.',
          'seen': false
        }
      ])
    });
  }

  createChatRoom(chatRoomID, user1, user2) async {
    Map<String, dynamic> chatRoomInfo = {
      'lastMessage': "Started a ChatRoom",
      'sender': user1,
      'receiver': user2,
      'seen': false,
      'timestamp': DateTime.now(),
      'users': [user1, user2],
      'isImage': false,
      'isSharing': [false, false]
    };

    await findChatRoom(chatRoomID).then((value) async {
      if (!value.exists) {
        await firestore
            .collection('chatRooms')
            .doc(chatRoomID)
            .set(chatRoomInfo);
      }
    });
  }

  addMessage(chatRoomID, messageInfo, lastMessageInfo) async {
    await firestore
        .collection('chatRooms')
        .doc(chatRoomID)
        .collection('chats')
        .doc()
        .set(messageInfo);

    await firestore
        .collection('chatRooms')
        .doc(chatRoomID)
        .update(lastMessageInfo);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(chatRoomID) {
    return firestore
        .collection('chatRooms')
        .doc(chatRoomID)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> chatRoomDetail(chatRoomID) {
    return firestore.collection('chatRooms').doc(chatRoomID).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUnseenMessages(
      chatRoomID, email) {
    return firestore
        .collection('chatRooms')
        .doc(chatRoomID)
        .collection('chats')
        .where('seen', isEqualTo: false)
        .where('receiver', isEqualTo: email)
        .snapshots();
  }

  updateSeenInfo(chatRoomID, messageID) async {
    await firestore
        .collection('chatRooms')
        .doc(chatRoomID)
        .collection('chats')
        .doc(messageID)
        .update({'seen': true});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChats(email) {
    return firestore
        .collection('chatRooms')
        .where('users', arrayContains: email)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  updateUserLocation(uid, lat, long) {
    return firestore
        .collection('users')
        .doc(uid)
        .update({'latitude': lat, 'longitude': long});
  }

  updateMasterLocationSharing(bool mastershare, uid) async {
    return firestore
        .collection('users')
        .doc(uid)
        .update({'locShare': !mastershare});
  }

  updatechatLocShare(chatRoomID, isShare) {
    return firestore
        .collection('chatRooms')
        .doc(chatRoomID)
        .update({'isSharing': isShare});
  }

  updatelastseen(DateTime dt, String uid) {
    return firestore.collection('users').doc(uid).update({'lastSeen': dt});
  }

  changeProfilePhoto(filep, groupUID) async {
    final firebase_storage.FirebaseStorage _storage =
        firebase_storage.FirebaseStorage.instanceFor(
            bucket: 'gs://never-lost-643e9.appspot.com');

    File file = File(filep);
    try {
      String filepath = 'profilePhoto/$groupUID/$groupUID.png';
      await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .delete()
          .catchError((onerror) {
        print('kya hi kr skte hai');
      });
      await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .putFile(file);
      await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .getDownloadURL()
          .then((value) async {
        await firestore
            .collection('users')
            .doc(groupUID)
            .update({'photoURL': value});
      });
    } on firebase_core.FirebaseException catch (e) {
      print(e);
      return false;
    }
  }

  createGroup(groupInfo) async {
    var group = firestore.collection('groupChats').doc();

    await group.set(groupInfo);
    return group.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> findGroupChat(uid) {
    return firestore
        .collection('groupChats')
        .where('users', arrayContains: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot<Map<String, dynamic>>>> getGroupMessages(
      groupChatID) async {
    return firestore
        .collection('groupChats')
        .doc(groupChatID)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUnseenGroupMessages(
      groupChatID, uid) {
    return firestore
        .collection('groupChats')
        .doc(groupChatID)
        .collection('chats')
        .where('notSeenBy', arrayContains: uid)
        .snapshots();
  }

  addGroupMessage(groupChatID, messageInfo, lastMessageInfo) async {
    await firestore
        .collection('groupChats')
        .doc(groupChatID)
        .collection('chats')
        .doc()
        .set(messageInfo);

    await firestore
        .collection('groupChats')
        .doc(groupChatID)
        .update(lastMessageInfo);
  }

  updateGroupSeenInfo(groupChatID, messageID, info) async {
    await firestore
        .collection('groupChats')
        .doc(groupChatID)
        .collection('chats')
        .doc(messageID)
        .update(info);
  }

  Future<void> updateGroupIcon(groupIconPath, groupUID) async {
    File file = File(groupIconPath);
    try {
      String filepath = 'groupIcon/$groupUID/$groupUID.png';
      await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .delete()
          .catchError((onerror) {
        print('kya hi kr skte hai');
      });
      await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .putFile(file);
      await firebase_storage.FirebaseStorage.instance
          .ref(filepath)
          .getDownloadURL()
          .then((value) async {
        await firestore
            .collection('groupChats')
            .doc(groupUID)
            .update({'photoURL': value});
      });
    } on firebase_core.FirebaseException catch (e) {
      print(e);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> groupDetails(groupUID) {
    return firestore.collection('groupChats').doc(groupUID).snapshots();
  }

  updateGroupLocSharePermission(groupUID, userUID, shareStatus) {
    return firestore
        .collection('groupChats')
        .doc(groupUID)
        .update({'locSharePermission.$userUID': !shareStatus});
  }

  updateLastLocation(groupUID, userUID, lat, long) {
    return firestore.collection('groupChats').doc(groupUID).update({
      'lastLocation.$userUID': [lat, long, DateTime.now()]
    });
  }
}
