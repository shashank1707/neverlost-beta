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
  final currentUser, friendUser, chatRoomID;
  const LocationPage(
      {Key? key,
      required this.currentUser,
      required this.friendUser,
      required this.chatRoomID})
      : super(key: key);

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  bool isloading = true;
  late double userlat;
  late double userlong;
  late double friendlat;
  late double friendlong;
  double zoom = 15;
  late Stream userStream, friendStream;
  String adddress = '';
  String friendAdddress = '';
  bool friendMasterShare = false;
  bool userMasterShare = false;
  bool friendIsShare = false;
  bool userIsShare = false;
  @override
  void initState() {
    super.initState();
    if (mounted) {
      getUserStream();
    }
  }

  void getUserStream() async {
    if (mounted) {
      DatabaseMethods()
          .getUserSnapshots(widget.friendUser['uid'])
          .listen((event) async {
        setState(() {
          friendlat = event.data()!['latitude'];
          friendlong = event.data()!['longitude'];
          // friendAdddress = _getAddress(friendlat, friendlong) as String;
          friendMasterShare = event.data()!['locShare'];
        });
      });
      DatabaseMethods()
          .getUserSnapshots(widget.currentUser['uid'])
          .listen((event) async {
        setState(() {
          userMasterShare = event.data()!['locShare'];
          userlat = event.data()!['latitude'];
          userlong = event.data()!['longitude'];
          // adddress = _getAddress(userlat, userlong) as String;
          // print(adddress);
        });
      });

      DatabaseMethods().chatRoomDetail(widget.chatRoomID).listen((event) {
        if (event.data()!['users'][0] == widget.currentUser['email']) {
          setState(() {
            friendIsShare = event.data()!['isSharing'][1];
            userIsShare = event.data()!['isSharing'][0];
          });
        } else {
          setState(() {
            friendIsShare = event.data()!['isSharing'][0];
            userIsShare = event.data()!['isSharing'][1];
          });
        }
      });
      setState(() {
        isloading = false;
      });
    }
  }

  Future<String> _getAddress(double lat, double long) async {
    String address = '';
    if (userMasterShare && friendMasterShare && friendIsShare && userIsShare) {
      List<geo.Placemark> add = await geo.placemarkFromCoordinates(lat, long);
      Map data = add[0].toJson();
      address = data['name'] +
          ',' +
          data['locality'] +
          ',' +
          data['subAdministrativeArea'] +
          ',' +
          data['administrativeArea'] +
          ',' +
          data['postalCode'];
    }
    return address;
  }

  locationMap() {
    if (mounted) {
      return Scaffold(
        body: FlutterMap(
          options: MapOptions(
            interactiveFlags: InteractiveFlag.all,
            center: LatLng(friendlat, friendlong),
            zoom: zoom,
          ),
          layers: [
            MarkerLayerOptions(
              markers: [
                Marker(
                  height: 40,
                  width: 40,
                  point: LatLng(userlat, userlong),
                  builder: (ctx) => LocationMarker(
                    user: widget.currentUser,
                    address: adddress,
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
                  point: LatLng(friendlat, friendlong),
                  builder: (ctx) => LocationMarker(
                      user: widget.friendUser, address: friendAdddress),
                ),
              ],
            )),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _getAddress(userlat, userlong);
          },
          child: const Icon(CupertinoIcons.restart),
        ),
      );
    }
  }

  Widget requestShare() {
    if (!userMasterShare || !userIsShare) {
      return const Text('Turn on your Location Sharing from Settings');
    }
    if (!friendMasterShare || !friendIsShare) {
      return const Text('Request Your Friend to turn on Location Sharing');
    }
    return const Text('');
  }

  @override
  Widget build(BuildContext context) {
    return (userMasterShare &&
            friendMasterShare &&
            friendIsShare &&
            userIsShare)
        ? (isloading ? const Loading() : locationMap())
        : Center(child: requestShare());
  }
}
