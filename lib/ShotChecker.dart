import 'dart:math';

import 'package:hoopster/screens/recording_screen2.dart';

bool ShotChecker(List<List<double>> hoop, List<List<double>> ball) {
  List<double> Hcorner1 = hoop[0];
  List<double> Hcorner2 = hoop[1];
  List<double> Hcorner3 = hoop[2];
  List<double> Hcorner4 = hoop[3];

  List<double> Bcorner1 = ball[0];
  List<double> Bcorner2 = ball[1];
  List<double> Bcorner3 = ball[2];
  List<double> Bcorner4 = ball[3];

  double Hlato1 = (Hcorner1[0] - Hcorner2[0]).abs();
  double Hlato2 = (Hcorner2[1] - Hcorner4[1]).abs();
  double Hlato3 = (Hcorner3[0] - Hcorner4[0]).abs();
  double Hlato4 = (Hcorner1[1] - Hcorner3[1]).abs();

  double Blato1 = (Bcorner1[0] - Bcorner2[0]).abs();
  double Blato2 = (Bcorner2[1] - Bcorner4[1]).abs();
  double Blato3 = (Bcorner3[0] - Bcorner4[0]).abs();
  double Blato4 = (Bcorner1[1] - Bcorner3[1]).abs();

  double AH = Hlato1 * Hlato2;
  double AB = Blato1 * Blato2;

  double BA = bigger(AH, AB);

  bool made = false;
  //List<Point> Lrect1 = computeRectangle(hoop);
  //List<Point> Lrect2 = computeRectangle(ball);
  Rectangle rect1 = Rectangle(Hcorner1[0], Hcorner1[1], Hlato1, Hlato2);
  Rectangle rect2 = Rectangle(Bcorner1[0], Bcorner1[1], Blato1, Blato2);

  Rectangle? insters = rect1.intersection(rect2);
  if (insters != null) {
    double A = (insters.height * insters.width).toDouble();

    double p = A / (min(AH, AB)) * 100;

    if (p >= 95) {
      made = true;
    } else {
      made = false;
    }

    /*if ((A - BA).abs() <= BA * 0.5) {
      made = true;
    } else {
      made = true;
    }*/
  }

  return made;
}

/*List<Point> computeRectangle(List<List<int>> arr1) {
  List<Point> coor = [];
  List<int> corner1 = arr1[0];
  List<int> corner2 = arr1[1];
  List<int> corner3 = arr1[2];
  List<int> corner4 = arr1[3];

  int lato1 = (corner1[0] - corner2[0]).abs();
  int lato2 = (corner2[1] - corner4[1]).abs();
  int lato3 = (corner3[0] - corner4[0]).abs();
  int lato4 = (corner1[1] - corner3[1]).abs();

  int A = lato1 * lato2;

  coor = generateSquareCoordinates(corner1[0], corner1[1], corner2[0],
      corner2[1], corner3[0], corner3[1], corner4[0], corner4[1]);

  return coor;
}

List<Point> generateSquareCoordinates(
    int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
  int minX = [x1, x2, x3, x4].reduce((a, b) => a < b ? a : b);
  int maxX = [x1, x2, x3, x4].reduce((a, b) => a > b ? a : b);
  int minY = [y1, y2, y3, y4].reduce((a, b) => a < b ? a : b);
  int maxY = [y1, y2, y3, y4].reduce((a, b) => a > b ? a : b);

  List<Point> squareCoordinates = [];
  for (int x = minX; x <= maxX; x++) {
    for (int y = minY; y <= maxY; y++) {
      squareCoordinates.add(Point(x, y));
    }
  }

  return squareCoordinates;
}
*/
double bigger(double A1, double A2) {
  if (A1 >= A2) {
    return A1;
  } else {
    return A2;
  }
}
