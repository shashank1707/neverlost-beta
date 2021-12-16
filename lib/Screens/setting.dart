import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Firebase/database.dart';

class Setting extends StatefulWidget {
  final String userUID;
  const Setting({Key? key, required this.userUID}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late bool masterShare;
  bool isloading = true;
  @override
  void initState() {
    super.initState();
    getUserStream();
  }

  getUserStream() {
    DatabaseMethods().getUserSnapshots(widget.userUID).listen((event) {
      if (mounted) {
        setState(() {
          masterShare = event.data()!['locShare'];
          isloading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? Loading()
        : SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                minLeadingWidth: 0,
                title: Text('Location Sharing'),
                subtitle:
                    Text('This will turn OFF location sharing from all chats'),
                trailing: Switch(
                    value: masterShare,
                    onChanged: (newvalue) {
                      DatabaseMethods().updateMasterLocationSharing(
                          masterShare, widget.userUID);
                    }),
              ),
            ),
          );
  }
}
