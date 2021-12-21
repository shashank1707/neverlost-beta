import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';

class NotifationDot extends StatelessWidget {
  final int dotNumer;
  const NotifationDot({Key? key, required this.dotNumer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration:
          const BoxDecoration(color: backgroundColor1, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$dotNumer',
          style: const TextStyle(fontSize: 10, color: textColor2),
        ),
      ),
    );
  }
}
