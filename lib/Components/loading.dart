
import 'package:flutter/material.dart';
import 'package:neverlost_beta/Components/constants.dart';

class Loading extends StatelessWidget {
  const Loading({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: backgroundColor2,
      body: Center(child: CircularProgressIndicator(color: backgroundColor1,)),
    );
  }
}