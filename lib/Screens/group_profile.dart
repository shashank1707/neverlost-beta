import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';
import 'package:neverlost_beta/Screens/chatroom.dart';
import 'package:neverlost_beta/Screens/profile.dart';
import 'package:neverlost_beta/Screens/userprofile.dart';

class GroupProfile extends StatefulWidget {
  final String groupUID, userUID;
  const GroupProfile({Key? key, required this.groupUID, required this.userUID})
      : super(key: key);

  @override
  _GroupProfileState createState() => _GroupProfileState();
}

class _GroupProfileState extends State<GroupProfile> {
  String adminId = '';
  String groupName = '';
  Map adminInfo = {};
  List membersInfo = [];
  String photoURL = '';
  late int membersLength;
  bool isAdmin = false;
  bool isloading = true;
  TextEditingController nameController = TextEditingController();
  @override
  void initState() {
    getGroupInfo();
    super.initState();
  }


  getGroupInfo() {
    DatabaseMethods().groupDetails(widget.groupUID).listen((event) async {
      if (mounted) {
        List memberList = await event.data()!['users'];
        setState(() {
          adminId = event.data()!['admin'];
          photoURL = event.data()!['photoURL'];
          groupName = event.data()!['name'];
        });
        if (adminId == widget.userUID) {
          setState(() {
            isAdmin = true;
          });
        }
        for (var i = 0; i < memberList.length; i++) {
          await DatabaseMethods().getUserData(memberList[i]).then((value) {
            if (value.data()!['uid'] == widget.userUID) {
              Map<String, dynamic>? temp = value.data();
              temp!['name'] = 'You';
              membersInfo.add(temp);
            } else {
              setState(() {
                membersInfo.add(value.data());
              });
            }
          });
        }
        setState(() {
          membersLength = membersInfo.length;
          isloading = false;
        });
      }
    });
  }

  Widget membersList() {
    var currrentUser = membersInfo
        .where((element) => element['uid'] == widget.userUID)
        .toList()[0];
    var admin =
        membersInfo.where((element) => element['uid'] == adminId).toList()[0];
    return ListView(
      shrinkWrap: true,
      children: [
        Visibility(
          visible: widget.userUID != adminId,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile(currentUser: currrentUser)));
              },
              leading: InkWell(
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(currrentUser['photoURL']),
                ),
              ),
              title: Text(currrentUser['name'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(currrentUser['status'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing:
                  adminId == currrentUser['uid'] ? Text('Admin') : Text(''),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: ListTile(
              onTap: () {
                if(widget.userUID == adminId){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile(currentUser: currrentUser)));
                }else{
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserProfile(currentUser: currrentUser, friendUserUID: adminId)));
                }
                
              },
              leading: InkWell(
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(admin['photoURL']),
                ),
              ),
              title: Text(admin['name'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(admin['status'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('Admin')),
        ),
        ...(membersInfo).where((element) => element['uid'] != widget.userUID && element['uid'] != adminId).map((member){
          return Padding(
                padding: const EdgeInsets.all(4.0),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserProfile(currentUser: currrentUser, friendUserUID: member['uid'])));
                  },
                  leading: InkWell(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(member['photoURL']),
                    ),
                  ),
                  title: Text(member['name'],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(member['status'],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: adminId == member['uid']
                      ? Text('admin')
                      : Text(''),
                ),
              );
        })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return isloading
        ? Loading()
        : Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: backgroundColor1,
              actions: [
                TextButton.icon(
                    onPressed: () {
                      //showSignoutDialogue();
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: backgroundColor2,
                    ),
                    label: const Text(
                      'Leave',
                      style: TextStyle(color: backgroundColor2),
                    ))
              ],
            ),
            body: SizedBox(
              width: width,
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: width,
                    decoration: const BoxDecoration(
                        color: backgroundColor1,
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(15))),
                    child: Column(
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.network(
                              photoURL,
                              height: 150,
                              width: 150,
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: width / 1.85,
                                  child: Text(
                                    groupName,
                                    softWrap: true,
                                    style: TextStyle(
                                        color: backgroundColor2,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              if (isAdmin)
                                Positioned(
                                  right: 50,
                                  // alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: backgroundColor2,
                                    ),
                                    onPressed: () {
                                      //changeName();
                                    },
                                  ),
                                )
                            ],
                          ),
                        ),
                        Text(
                          '$membersLength Members',
                          style: TextStyle(
                              color: backgroundColor2,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '',
                          style: TextStyle(
                              color: backgroundColor2,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Members',
                          style: TextStyle(fontSize: 20),
                        ),
                      )),
                  Expanded(child: membersList())
                ],
              ),
            ),
          );
  }
}
