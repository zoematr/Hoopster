import 'package:flutter/material.dart';
import 'package:hoopster/screens/recording_screen2.dart';
import 'package:hoopster/screens/stats_screen.dart';
import 'package:hoopster/screens/settings_screen.dart';
import 'package:hoopster/screens/about_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hoopster/statsObjects.dart';

//late List<CameraDescription> _cameras;
double h = 0;
double w = 0;
List<int> bo = [1, 2, 3, 4, 5, 6, 7];
statsObjects Graph1 = statsObjects(bo);
statsObjects Graph2 = statsObjects(bo);
statsObjects Graph3 = statsObjects(bo);

String basketButton = "Assets\\BasketButton.png";

class HomeScreen extends StatelessWidget {
  //final List<CameraDescription>firstCamera;

  const HomeScreen(/*this.firstCamera*/);
  @override
  Widget build(BuildContext context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 93, 70, 94),
      appBar: AppBar(
        title: Text('Hoopster'),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              width: w,
              height: (h / 2) - 95 / 2,
              color: Color.fromARGB(0, 255, 255, 255),
              child: Center(
                  child: _buildButton(
                      context, 'Start Recording', CameraApp(/*firstCamera*/)))),
          Container(
            width: w,
            height: (h / 2) - 95 / 2,
            color: Color.fromARGB(0, 255, 0, 0),
            child: ListView(children: [Graph1, Graph2, Graph3]),
          )
        ],
      )),
    );
  }

  Widget _buildButton(BuildContext context, String text, Widget screen) {
    return Padding(
        padding: EdgeInsets.all(0),
        child: GestureDetector(
          child: Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
             image: DecorationImage(
          image: AssetImage(basketButton),
          fit: BoxFit.fill,
        ),
                color: Color.fromARGB(0, 255, 255, 255),
                boxShadow: [BoxShadow(color: Color.fromARGB(74, 0, 0, 0),
                blurRadius: 7,spreadRadius: 0)],
                borderRadius: BorderRadius.all(Radius.circular(80))),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
        ));
  }
}
