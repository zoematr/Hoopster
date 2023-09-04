import 'dart:io';
import 'package:ml_linalg/linalg.dart';

double parabolicFunc(double x, Vector coefficients) {
  return coefficients[0] * x * x + coefficients[1] * x + coefficients[2];
}

void main() {
  /*
  var data = File('object_position_data.txt').readAsStringSync();
  var lines = data.split('\n');


  var t = <double>[];
  var x_pos = <double>[];
  var y_pos = <double>[];

  for (var line in lines) {
    var values = line.split(',');
    t.add(double.parse(values[0]));
    x_pos.add(double.parse(values[1]));
    y_pos.add(double.parse(values[2]));
  }
*/
  List<double> t = [1, 2, 3, 4, 5, 6, 7, 8];
  List<double> x_pos = [1, 2, 3, 4, 5, 6, 7, 8];
  List<double> y_pos = [2, 5, 10, 17, 26, 37, 50, 65];

  var Liste = List.filled(t.length, 1);
  var xMatrix = Matrix.fromColumns([
    Vector.fromList(t.map((t) => t * t).toList()),
    Vector.fromList(t),
    Vector.fromList(Liste)
  ]);
  var xVector = Vector.fromList(x_pos);
  var popt_x =
      (xMatrix.transpose() * xMatrix).inverse() * xMatrix.transpose() * xVector;

  var yMatrix = Matrix.fromColumns([
    Vector.fromList(t.map((t) => t * t).toList()),
    Vector.fromList(t),
    Vector.fromList(Liste)
  ]);
  var yVector = Vector.fromList(y_pos);
  var popt_y =
      (yMatrix.transpose() * yMatrix).inverse() * yMatrix.transpose() * yVector;

  
  var x_fit = t.map((t) => parabolicFunc(t, popt_x as Vector)).toList();
  var y_fit = t.map((t) => parabolicFunc(t, popt_y as Vector)).toList();

  var residuals_x = <double>[];
  var residuals_y = <double>[];

  for (var i = 0; i < x_pos.length; i++) {
    var residual_x = x_pos[i] - x_fit[i];
    var residual_y = y_pos[i] - y_fit[i];
    residuals_x.add(residual_x);
    residuals_y.add(residual_y);
  }
  print("prova");

  var rss_x = residuals_x
      .map((residual) => residual * residual)
      .reduce((a, b) => a + b);
  var rss_y = residuals_y
      .map((residual) => residual * residual)
      .reduce((a, b) => a + b);


  var tss_x = x_pos
      .map((x) =>
          (x - x_pos.reduce((a, b) => a + b) / x_pos.length) *
          (x - x_pos.reduce((a, b) => a + b) / x_pos.length))
      .reduce((a, b) => a + b);
  var tss_y = y_pos
      .map((y) =>
          (y - y_pos.reduce((a, b) => a + b) / y_pos.length) *
          (y - y_pos.reduce((a, b) => a + b) / y_pos.length))
      .reduce((a, b) => a + b);


  var rSquared_x = 1 - (rss_x / tss_x);
  var rSquared_y = 1 - (rss_y / tss_y);

  if (rSquared_x >= 0.95 && rSquared_y >= 0.95) {
    print('True');
    return True;
  } else {
    print('False');
    return False;
  }
}
