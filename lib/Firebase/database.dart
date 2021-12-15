import 'package:cloud_firestore/cloud_firestore.dart';
import 'hive.dart';

class DatabaseMethods {
  final firestore = FirebaseFirestore.instance;

  createUserDatabase(name, email, uid, photoURL, phone) async {
    Map<String, dynamic> user = {
      "name": name.toUpperCase(),
      "email": email.toLowerCase(),
      "uid": uid,
      "photoURL": photoURL,
      "status": "Hey! Let's Chat!",
      "phone": phone ?? 'Enter your Mobile Number',
      "recentSearchList": [],
      "friendList": [],
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
        .where('name', isEqualTo: name.toUpperCase())
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

  getUserData(uid) async {
    return firestore.collection('users').doc(uid).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> findChatRoom(
      chatRoomID) async {
    return await firestore.collection('chatRooms').doc(chatRoomID).get();
  }

  Future<void> unFriend(currentUserUid, targetUid) async {
    await firestore
        .collection('users')
        .doc(currentUserUid)
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
          'friendList': FieldValue.arrayRemove([currentUserUid])
        })
        .then((value) => print("User's Property Deleted"))
        .catchError(
            (error) => print("Failed to delete user's property: $error"));
  }

  Future<void> sendFriendRequest(currenUserUid, currentUserEmail,
      currentUserPhotoUrl, currentUserName, targetUid) async {
    return await firestore
        .collection('users')
        .doc(targetUid)
        .update({
          'pendingRequestList': FieldValue.arrayUnion([
            {
              'email': currentUserEmail,
              'uid': currenUserUid,
              'name': currentUserName,
              'photoURL': currentUserPhotoUrl
            }
          ])
        })
        .then((value) => print("User's Property Added"))
        .catchError(
            (error) => print("Failed to delete user's property: $error"));
  }

  Future<Stream<DocumentSnapshot<Map<String, dynamic>>>> getFriendRequest(
      uid) async {
    return firestore.collection('users').doc(uid).snapshots();
  }

  Future<void> acceptFriendRequest(currentUserUid, Map targetUser) async {
    await firestore.collection('users').doc(currentUserUid).update({
      'pendingRequestList': FieldValue.arrayRemove([targetUser]),
      'friendList': FieldValue.arrayUnion([targetUser['uid']])
    });
    await firestore.collection('users').doc(targetUser['uid']).update({
      'friendList': FieldValue.arrayUnion([currentUserUid])
    });
  }

  Future<void> rejectFriendRequest(currentUserUid, Map target) async {
    await firestore.collection('users').doc(currentUserUid).update({
      'pendingRequestList': FieldValue.arrayRemove([target])
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
        .update({'isShare': !mastershare});
  }

  updatechatLocShare(chatRoomID, isShare) {
    return firestore
        .collection('chatRooms')
        .doc(chatRoomID)
        .update({'isSharing': isShare});
  }
}
