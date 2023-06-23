import 'package:flutter/material.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/main.dart';
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
//List<int> bo = [1, 2, 3, 4, 5, 6, 7];
List<List<double>> tr0 = [
  [20.03, 02.04, 02.04],
  [5, 9],
  [3, 1],
  [9, 4]
];

List<List<double>> tr1 = [
  [01.04, 02.04, 02.04],
  [92, 78, 32]
];
statsObjects Graph1 = statsObjects([], "");
statsObjects Graph2 = statsObjects([], "");

Widget globalUpdate() {
  Graph1 = statsObjects(parseForgraph(allSessions), "shots");
  Graph2 = statsObjects(parseForgraph(allSessions), "shots");
  List<statsObjects> GraphList = [];
  GraphList.add(Graph1);
  GraphList.add(Graph2);

  return ListView.builder(
    itemCount: 2,
    itemBuilder: (context, index) {
      return GraphList[index];
    },
  );
}

String basketButton = "Assets\BasketButton.png";
Widget lView = globalUpdate();

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //final List<CameraDescription>firstCamera;

  _HomeScreenState(/*this.firstCamera*/);
  @override
  Widget build(BuildContext context) {
    globalUpdate();
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 93, 70, 94),
      appBar: AppBar(
        title: Text("Hoopster",
            style: TextStyle(fontFamily: 'Dogica', letterSpacing: 0.2)),
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
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Color.fromARGB(151, 0, 0, 0),
                        blurRadius: 8,
                        spreadRadius: 1)
                  ],
                  color: Color.fromARGB(255, 57, 57, 57),
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(5),
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5))),
              width: w - 20,
              height: (h / 2) - 110 / 2,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 6.5, 0, 0),
                  child: Text("Stats",
                      style: TextStyle(
                          fontFamily: "Dogica",
                          fontSize: 15,
                          color: Color.fromARGB(255, 255, 255, 255))),
                ),
                Expanded(child: lView = globalUpdate())
              ]))
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
                color: Color.fromARGB(0, 93, 70, 94),
                boxShadow: [
                  BoxShadow(
                      color: Color.fromARGB(74, 0, 0, 0),
                      blurRadius: 7,
                      spreadRadius: 0)
                ],
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
