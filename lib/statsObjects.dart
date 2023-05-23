import 'package:flutter/material.dart';
import 'package:hoopster/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class statsObjects extends StatefulWidget {
  List<int> data;
  statsObjects(this.data, {super.key});

  @override
  State<statsObjects> createState() => _statsObjectstate(data);
}

class _statsObjectstate extends State<statsObjects> {
  List<int> chartData;
  _statsObjectstate(this.chartData);
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(5),
        child: Container(
          height: 200,
          width: w,
          color: Color.fromARGB(0, 255, 255, 255),
          child: Padding(
              padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
              child: BarChart(convert(chartData))),
        ));
  }

  BarChartData convert(List<int> Toconvert) {
    BarChartData converted = BarChartData();
    return converted;
  }
}
