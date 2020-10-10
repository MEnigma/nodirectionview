/*
* @auther : Mark
* @date : 2020-10-10
* @ide : VSCode
*/

import 'package:flutter/material.dart';
import 'package:nodirectionview/nodirectionview.dart';

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  int _index = 6;

  Color makeColor() {
    int r, g, b;
    r = _index % 255;
    g = (r * 2) % 255;
    b = (g * 2) % 255;
    return Color.fromRGBO(r, g, b, 1);
  }

  Widget randomColorBox() {
    _index += 1;
    return SizedBox.fromSize(
      size: Size(100, 100),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(2),
        color: makeColor(),
        child: Text(
          "$_index",
          style: TextStyle(backgroundColor: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: EdgeInsets.all(50),
      color: Colors.blueGrey,
      child: NodirectionView(
          child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox()
              ],
            ),
            Row(
              children: [
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox()
              ],
            ),
            Row(
              children: [
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox()
              ],
            ),
            Row(
              children: [
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox()
              ],
            ),
            Row(
              children: [
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox()
              ],
            ),
            Row(
              children: [
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox(),
                randomColorBox()
              ],
            )
          ],
        ),
      )),
    );
  }
}
