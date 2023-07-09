import 'dart:io';
import 'package:ml_linalg/linalg.dart';

// Define a function to fit a second-degree polynomial curve to the position data
double parabolicFunc(double x, Vector coefficients) {
  return coefficients[0] * x * x + coefficients[1] * x + coefficients[2];
}

bool ParabolaChecker(List<dynamic> l) {
  /*
   //Load the object's position data over time from a file
  var data = File('object_position_data.txt').readAsStringSync();
  var lines = data.split('\n');


  var t = <double>[];
  var x_pos = <double>[];
  var y_pos = <double>[];

  // Extract the x and y positions and time stamps from the data
  for (var line in lines) {
    var values = line.split(',');
    t.add(double.parse(values[0]));
    x_pos.add(double.parse(values[1]));
    y_pos.add(double.parse(values[2]));
  }
*/
  List<double> t = l[0];
  List<double> x_pos = l[1];
  List<double> y_pos = l[2];
  // Fit a second-degree polynomial curve to the x and y coordinates of the object
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

  // Evaluate the curve at each time step
  var x_fit = t.map((t) => parabolicFunc(t, popt_x as Vector)).toList();
  var y_fit = t.map((t) => parabolicFunc(t, popt_y as Vector)).toList();

  // Calculate the residuals between the data and the fitted curve
  var residuals_x = <double>[];
  var residuals_y = <double>[];

  for (var i = 0; i < x_pos.length; i++) {
    var residual_x = x_pos[i] - x_fit[i];
    var residual_y = y_pos[i] - y_fit[i];
    residuals_x.add(residual_x);
    residuals_y.add(residual_y);
  }
  print("calculating resiguals");
  // Calculate the sum of squared residuals
  var rss_x = residuals_x
      .map((residual) => residual * residual)
      .reduce((a, b) => a + b);
  var rss_y = residuals_y
      .map((residual) => residual * residual)
      .reduce((a, b) => a + b);

  // Calculate the total sum of squares
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

  // Calculate the R-squared value
  var rSquared_x = 1 - (rss_x / tss_x);
  var rSquared_y = 1 - (rss_y / tss_y);

  // Determine whether the object followed a parabolic motion or not
  if (rSquared_x >= 0.95 && rSquared_y >= 0.95) {
    print('The object followed a parabolic motion.');
    return true;
  } else {
    print('The object did not follow a parabolic motion.');
    return false;
  }
}
