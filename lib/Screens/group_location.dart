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
  Map locSharePermission = {};
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
          locSharePermission = event.data()!['locSharePermission'];
          currentStatus = event.data()!['lastLocation'];
          //currentStatus.remove(key)
          isLoading = false;
        });
      }
    });
  }

  getLocation() {
    if (mounted) {
      timer = Timer.periodic(const Duration(seconds: 5), (_) {
        for (var uid in locSharePermission.keys) {
          if (locSharePermission[uid] == true) {
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

  String calculateTime(_timestamp) {
    DateTime currentTime = DateTime.now();
    var timestamp =
        DateTime.fromMicrosecondsSinceEpoch(_timestamp.microsecondsSinceEpoch);
    var yearDiff = currentTime.year - timestamp.year;
    var monthDiff = currentTime.month - timestamp.month;
    var dayDiff = currentTime.day - timestamp.day;
    var hourDiff = currentTime.hour - timestamp.hour;
    var minDiff = currentTime.minute - timestamp.minute;

    var min = '${timestamp.minute}'.length > 1
        ? '${timestamp.minute}'
        : '0${timestamp.minute}';

    var hour = '${timestamp.hour}'.length > 1
        ? '${timestamp.hour}'
        : '0${timestamp.hour}';

    var day = '${timestamp.day}'.length > 1
        ? '${timestamp.day}'
        : '0${timestamp.day}';

    var month = '${timestamp.month}'.length > 1
        ? '${timestamp.month}'
        : '0${timestamp.month}';

    var year = '${timestamp.year}'.substring(2);

    if (yearDiff < 1 &&
        monthDiff < 1 &&
        dayDiff < 1 &&
        hourDiff < 1 &&
        minDiff < 1) {
      return 'Just Now';
    } else if (yearDiff < 1 && monthDiff < 1 && dayDiff < 1) {
      if (int.parse(hour) == 0) {
        return '12:$min AM';
      } else if (int.parse(hour) == 12) {
        return '12:$min PM';
      } else if (int.parse(hour) > 12) {
        return '${int.parse(hour) - 12}:$min PM';
      } else {
        return '$hour:$min AM';
      }
    } else if ((yearDiff < 1 && monthDiff < 1 && dayDiff < 2) ||
        (yearDiff < 1 && monthDiff <= 1 && dayDiff < 0) ||
        (yearDiff == 1 && currentTime.day == 1 && currentTime.month == 1)) {
      return 'Yesterday';
    } else {
      return '$day/$month/$year';
    }
  }

  setMarker() {
    // print(lastLocation);
    List<Marker> temp = [];
    currentStatus.forEach((key, value) {
      temp.add(Marker(
        height: 40,
        width: 40,
        point: LatLng(value[0].toDouble(), value[1].toDouble()),
        builder: (ctx) => LocationMarker(
          user: widget.key,
          address: locSharePermission[key]
              ? 'Hello'
              : calculateTime(lastLocation[key][2]),
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
            center: LatLng(currentStatus[widget.userUID][0].toDouble(),
                currentStatus[widget.userUID][1].toDouble()),
            zoom: 15,
          ),
          layers: [
            MarkerLayerOptions(
              markers: [
                Marker(
                  height: 40,
                  width: 40,
                  point: LatLng(currentStatus[widget.userUID][0].toDouble(),
                      currentStatus[widget.userUID][1].toDouble()),
                  builder: (ctx) => LocationMarker(
                    user: widget.userUID,
                    address: locSharePermission[widget.userUID]
                        ? 'Hello'
                        : calculateTime(lastLocation[widget.userUID][2]),
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
    return isLoading ? const Loading() : locationMap();
  }
}
