import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:hoopster/screens/home_screen.dart';
import 'package:fl_chart/fl_chart.dart';

List<String> dates = [];

class statsObjects extends StatefulWidget {
  List<List<double>> data;
  String type = "";
  statsObjects(this.data, this.type, {super.key});

  @override
  State<statsObjects> createState() => _statsObjectstate(data, type);
}

class _statsObjectstate extends State<statsObjects> {
  List<List<double>> chartData;
  String type = "";
  String title = "";
  _statsObjectstate(this.chartData, this.type);
  @override
  Widget build(BuildContext context) {
    dates = DtoS(chartData[0]);
    if (type == "shots") {
      title = "Shots";
    } else {
      title = "Accuracy";
    }
    return Padding(
        padding: EdgeInsets.fromLTRB(5, 15, 5, 0),
        child: Container(
            height: 200,
            width: w,
            color: Color.fromARGB(0, 255, 255, 255),
            child: Column(children: [
              Text(
                title,
                style: TextStyle(
                    fontFamily: "Dogica", fontSize: 10, color: Colors.white),
              ),
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: BarChart(convert(chartData, type)))),
            ])));
  }

  BarChartData convert(List<List<double>> Toconvert, String t) {
    List<BarChartGroupData> barGroupdata = [];
    FlTitlesData _titles = FlTitlesData();

    if (t == "shots") {
      for (int i = 0; i < Toconvert[0].length; i++) {
        barGroupdata.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(
              toY: Toconvert[i + 1][0].toDouble(),
              color: Color.fromARGB(255, 255, 0, 0)),
          BarChartRodData(
              toY: Toconvert[i + 1][0].toDouble() +
                  Toconvert[i + 1][1].toDouble(),
              color: Color.fromARGB(255, 157, 0, 201)),
          BarChartRodData(
              toY: Toconvert[i + 1][1].toDouble(),
              color: Color.fromARGB(255, 0, 255, 0))
        ]));
      }
    } else if (t == "accuracy") {
      for (int i = 0; i < Toconvert[0].length; i++) {
        barGroupdata.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(
              toY: Toconvert[i+1][2].toInt().toDouble(),
              color: Color.fromARGB(255, 255, 234, 0))
        ]));
      }
    }

    for (int i = 0; i < Toconvert[0].length; i++) {}

    BarChartData converted = BarChartData(
      titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: getTitles,
        reservedSize: 38,
      ))),
      barGroups: barGroupdata,
    );
    return converted;
  }
}

Widget getTitles(double value, TitleMeta meta) {
  int x = 0;
  const style =
      TextStyle(color: Colors.white, fontFamily: "Dogica", fontSize: 10);

  int getValues() {
    int i;

    return 0;
  }

  // x = getValues();

  Widget text;

  text = Text(
    dates[value.toInt()],
    style: style,
  );

  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 16,
    child: text,
  );
}

class BarTitles {
  static SideTitles getBottomTitles() => SideTitles();
}

List<String> DtoS(List<double> D) {
  List<String> S = [];
  for (double d in D) {
    String z = d.toString();
    if (z.length <=4) {
      z = "0${z}";
    }
    z = z.replaceAll(".", "");
    String s = "${z[0]}${z[1]}/${z[2]}${z[3]}";
    S.add(s);
  }
  return S;
}
