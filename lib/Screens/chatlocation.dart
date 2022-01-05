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

class LocationPage extends StatefulWidget {
  final String currentUID, friendUID, chatRoomID;
  const LocationPage(
      {Key? key,
      required this.currentUID,
      required this.friendUID,
      required this.chatRoomID})
      : super(key: key);

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  bool isLoading = true;
  Map lastLocation = {};
  Map locSharePermission = {};
  Map currentStatus = {};
  double zoom = 15;
  late Timer timer;
  @override
  void initState() {
    super.initState();
    getData().then((value) => getLocation());
  }

  Future<void> getData() async {
    DatabaseMethods().chatRoomDetail(widget.chatRoomID).listen((event) {
      if (mounted) {
        setState(() {
          lastLocation = event.data()!['lastLocation'];
          locSharePermission = event.data()!['locSharePermission'];
          print(lastLocation);
        });
      }
    });
    setState(() {
      currentStatus = lastLocation;
    });
  }

  getLocation() {
    timer = Timer.periodic(Duration(seconds: 5), (_) {
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
              currentStatus.update(
                  uid, (value) => [lastLocation[uid][0], lastLocation[uid][1]]);
            });
          }
        }
      }
    });
    setState(() {
      isLoading = false;
    });
  }
  // Future<String> _getAddress(double lat, double long) async {
  //   String address = '';
  //   if (userMasterShare && friendMasterShare && friendIsShare && userIsShare) {
  //     List<geo.Placemark> add = await geo.placemarkFromCoordinates(lat, long);
  //     Map data = add[0].toJson();
  //     address = data['name'] +
  //         ',' +
  //         data['locality'] +
  //         ',' +
  //         data['subAdministrativeArea'] +
  //         ',' +
  //         data['administrativeArea'] +
  //         ',' +
  //         data['postalCode'];
  //   }
  //   return address;
  // }

  locationMap() {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          interactiveFlags: InteractiveFlag.all,
          center: LatLng(currentStatus[widget.friendUID][0].toDouble(),
              currentStatus[widget.friendUID][1].toDouble()),
          zoom: zoom,
        ),
        layers: [
          MarkerLayerOptions(
            markers: [
              Marker(
                height: 40,
                width: 40,
                point: LatLng(currentStatus[widget.currentUID][0].toDouble(),
                    currentStatus[widget.currentUID][0].toDouble()),
                builder: (ctx) => LocationMarker(
                  user: widget.currentUID,
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
              options: MarkerLayerOptions(
            markers: [
              Marker(
                height: 40,
                width: 40,
                point: LatLng(currentStatus[widget.friendUID][0].toDouble(),
                    currentStatus[widget.friendUID][1].toDouble()),
                builder: (ctx) => LocationMarker(
                    user: widget.friendUID, address: 'friendAdddress'),
              ),
            ],
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(CupertinoIcons.restart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? const Loading() : Loading();
  }
}
