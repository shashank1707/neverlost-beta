import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:neverlost_beta/Components/loading.dart';
import 'package:neverlost_beta/Components/marker.dart';
import 'package:neverlost_beta/Firebase/database.dart';

class GroupLocation extends StatefulWidget {
  final String groupUID, userUID;
  const GroupLocation({Key? key, required this.groupUID, required this.userUID})
      : super(key: key);

  @override
  _GroupLocationState createState() => _GroupLocationState();
}

class _GroupLocationState extends State<GroupLocation> {
  bool isLoading = true;
  Map lastLocation = {};
  Map locSharPermission = {};
  Map currentStatus = {};
  @override
  void initState() {
    getGroupInfo().then((value) => getLocation());
    super.initState();
  }

  Future<void> getGroupInfo() async {
    DatabaseMethods().groupDetails(widget.groupUID).listen((event) {
      if (mounted) {
        setState(() {
          lastLocation = event.data()!['lastLocation'];
          locSharPermission = event.data()!['locSharePermission'];
          currentStatus = locSharPermission;
        });
      }
    });
  }

  getLocation() {
    if (mounted) {
      Timer.periodic(Duration(seconds: 5), (timer) {
        for (var uid in locSharPermission.keys) {
          if (locSharPermission[uid] == true) {
            DatabaseMethods().getUserData(uid).then((value) {
              if (mounted) {
                setState(() {
                  currentStatus.update(
                      uid,
                      (v) => [
                            value.data()!['latitude'],
                            value.data()!['longitude']
                          ]);
                });
              }
            });
          } else {
            if (mounted) {
              setState(() {
                currentStatus.update(uid,
                    (value) => [lastLocation[uid][0], lastLocation[uid][1]]);
              });
            }
          }
        }
        print(currentStatus);
      });
    }
  }
  // locationMap() {
  //   if (mounted) {
  //     return Scaffold(
  //       body: FlutterMap(
  //         options: MapOptions(
  //           interactiveFlags: InteractiveFlag.all,
  //           center: LatLng(friendlat, friendlong),
  //           zoom: zoom,
  //         ),
  //         layers: [
  //           MarkerLayerOptions(
  //             markers: [
  //               Marker(
  //                 height: 40,
  //                 width: 40,
  //                 point: LatLng(userlat, userlong),
  //                 builder: (ctx) => LocationMarker(
  //                   user: widget.currentUser,
  //                   address: adddress,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //         children: <Widget>[
  //           TileLayerWidget(
  //               options: TileLayerOptions(
  //                   urlTemplate:
  //                       "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
  //                   subdomains: ['a', 'b', 'c'])),
  //           MarkerLayerWidget(
  //               options: MarkerLayerOptions(
  //             markers: [
  //               Marker(
  //                 height: 40,
  //                 width: 40,
  //                 point: LatLng(friendlat, friendlong),
  //                 builder: (ctx) => LocationMarker(
  //                     user: widget.friendUser, address: friendAdddress),
  //               ),
  //             ],
  //           )),
  //         ],
  //       ),
  //       floatingActionButton: FloatingActionButton(
  //         onPressed: () {
  //           _getAddress(userlat, userlong);
  //         },
  //         child: const Icon(CupertinoIcons.restart),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
