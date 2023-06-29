import 'package:hoopster/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  DateTime date;
  int Hit = 0;
  int Miss = 0;
  int Year = 0;
  String s = "";
  String Day = "";
  String Month = "";
  double dayMonth = 0.0;

  Session(this.date, this.Hit, this.Miss) {
    Day = date.day.toString();
    Month = date.month.toString();
    Year = date.year;
    if (Day.length == 1) {
      Day = "0" + Day;
    }
    if (Month.length == 1) {
      Month = "0" + Month;
    }
    dayMonth = double.parse("${Day}.${Month}");
  }

  void save() {
    List<String>? Slist = prefs!.getStringList('Session');
    s = "${Day}.${Month} ${Hit} ${Miss} ${Year}";
    prefs?.clear();
    if (Slist != null) {
      if(Slist.length==0){prefs?.setStringList("Session", Slist! + [s]);}
      for (String sl in Slist) {
        if (s == sl) {
          prefs?.setStringList("Session", Slist);
          break;
        } else {
          prefs?.setStringList("Session", Slist! + [s]);
        }
      }
    }
  }

  double computeAccuracy() {
    double Accuracy = (Hit / (Miss + Hit) * 100);
    return Accuracy;
  }
}

void saveAll(List<Session> all) {
  for (Session x in all) {
    x.save();
  }
}

List<Session> getAll() {
  List<Session> ret = [];
  List<String>? items = prefs!.getStringList('Session');

  for (String x in items!) {
    List<String> s = x.split(" ");
    List<String> dayMonth = s[0].split(".");
    DateTime d = DateTime(
        int.parse(s[3]), int.parse(dayMonth[1]), int.parse(dayMonth[0]));
    Session S = Session(d, int.parse(s[1]), int.parse(s[2]));
    ret.add(S);
  }
  return ret;
}

List<List<double>> parseForgraph(List<Session> all) {
  List<List<double>> ret = [];
  List<double> dates = [];
  List<List<double>> Shots = [];

  for (Session s in all) {
    List<double> Shot = [];
    dates.add(s.dayMonth);
    Shot.add(s.Miss.toDouble());
    Shot.add(s.Hit.toDouble());
    Shot.add(s.computeAccuracy());
    Shots.add(Shot);
  }
  ret.add(dates);
  for (List<double> Ld in Shots) {
    ret.add(Ld);
  }

  return ret;
}
