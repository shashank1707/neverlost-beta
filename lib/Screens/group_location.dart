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
  List<Marker> membersmarker = [];
  late Timer timer;
  @override
  void initState() {
    getGroupInfo().then((value) => getLocation());
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> getGroupInfo() async {
    DatabaseMethods().groupDetails(widget.groupUID).listen((event) {
      if (mounted) {
        setState(() {
          lastLocation = event.data()!['lastLocation'];
          locSharPermission = event.data()!['locSharePermission'];
          currentStatus = lastLocation;
        });
      }
    });
  }

  getLocation() {
    if (mounted) {
      timer = Timer.periodic(Duration(seconds: 5), (_) {
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
        setMarker();
      });
    }
  }

  setMarker() {
    List<Marker> temp = [];
    currentStatus.forEach((key, value) {
      temp.add(Marker(
        height: 40,
        width: 40,
        point: LatLng(24.73, 85.03),
        builder: (ctx) => LocationMarker(
          user: widget.key,
          address: 'adddress',
        ),
      ));
    });
    setState(() {
      membersmarker = temp;
      isLoading = false;
    });
  }

  locationMap() {
    if (mounted) {
      return Scaffold(
        body: FlutterMap(
          options: MapOptions(
            interactiveFlags: InteractiveFlag.all,
            center: LatLng(currentStatus.values.toList()[0][0],
                currentStatus.values.toList()[0][1]),
            zoom: 15,
          ),
          layers: [
            MarkerLayerOptions(
              markers: [
                Marker(
                  height: 40,
                  width: 40,
                  point: LatLng(currentStatus.values.toList()[0][0],
                      currentStatus.values.toList()[0][1]),
                  builder: (ctx) => LocationMarker(
                    user: widget.userUID,
                    address: 'adddress',
                  ),
                ),
              ],
            ),
          ],
          children: <Widget>[
            TileLayerWidget(
                options: TileLayerOptions(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'])),
            MarkerLayerWidget(
                options: MarkerLayerOptions(markers: membersmarker)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(CupertinoIcons.restart),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? Loading() : locationMap();
  }
}
