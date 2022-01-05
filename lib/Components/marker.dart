import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:neverlost_beta/Components/constants.dart';

class LocationMarker extends StatelessWidget {
  final user, address;
  const LocationMarker({Key? key, required this.user, required this.address})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      elevation: 5,
      icon: Container(
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 2, color: backgroundColor1)),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Icon(Icons.person)),
      ),
      itemBuilder: (context) => <PopupMenuEntry>[
        PopupMenuItem(
          enabled: false,
          onTap: () {},
          child: Container(
            child: ListTile(
              leading: Container(
                width: 35,
                height: 35,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Icon(Icons.fast_forward)),
              ),
              title: Text(
                address,
                style: TextStyle(color: Colors.black),
              ),
            ),
            // child: Wrap(
            //   children: [
            //     Container(
            //       width: 35,
            //       height: 35,
            //       child: ClipRRect(
            //           borderRadius: BorderRadius.circular(100),
            //           child: Image.network(user['photoURL'])),
            //     ),
            //     Text(
            //       address,
            //       style: TextStyle(color: Colors.black),
            //       softWrap: true,
            //     ),
            //   ],
            // ),
          ),
        ),
        PopupMenuItem(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.call)),
              IconButton(onPressed: () {}, icon: Icon(Icons.message)),
              IconButton(onPressed: () {}, icon: Icon(Icons.help))
            ],
          ),
        ),
      ],
    );
  }
}
