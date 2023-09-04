import 'dart:ffi';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hoopster/Parabola.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/ShotChecker.dart';
import 'package:hoopster/detect_logic.dart';
import 'package:hoopster/screens/camera_screen.dart';
import 'package:hoopster/statsObjects.dart';

import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';






List<List<double>> normalizeToRectangle(List<List<double>> coor) {
  Point p1 = Point(coor[0][0], coor[0][1]);
  Point p2 = Point(coor[1][0], coor[1][1]);
  Point p3 = Point(coor[2][0], coor[2][1]);
  Point p4 = Point(coor[3][0], coor[3][1]);
  // Calculate the distances between the points
  final d12 = _distanceBetweenPoints(p1, p2);
  final d13 = _distanceBetweenPoints(p1, p3);
  final d14 = _distanceBetweenPoints(p1, p4);

  // Find the shortest and longest distances
  final minDistance = min(min(d12, d13), d14);
  final maxDistance = max(max(d12, d13), d14);

  // Determine the diagonal points based on the shortest and longest distances
  Point diagonal1, diagonal2;
  if (minDistance == d12) {
    diagonal1 = p2;
    diagonal2 = d13 < d14 ? p3 : p4;
  } else if (minDistance == d13) {
    diagonal1 = p3;
    diagonal2 = d12 < d14 ? p2 : p4;
  } else {
    diagonal1 = p4;
    diagonal2 = d12 < d13 ? p2 : p3;
  }

  // Calculate the new points to form a rectangle
  final normalizedP2 =
      _calculateNormalizedPoint(p1, diagonal1, diagonal2, maxDistance);
  final normalizedP3 =
      _calculateNormalizedPoint(p1, diagonal2, diagonal1, maxDistance);
  final normalizedP4 =
      _calculateNormalizedPoint(p1, diagonal1, diagonal2, minDistance);

  return [
    [p1.x.toDouble(), p1.y.toDouble()],
    [normalizedP2.x.toDouble(), normalizedP2.y.toDouble()],
    [normalizedP3.x.toDouble(), normalizedP3.y.toDouble()],
    [normalizedP4.x.toDouble(), normalizedP4.y.toDouble()]
  ];
}

double _distanceBetweenPoints(Point p1, Point p2) {
  final dx = p2.x - p1.x;
  final dy = p2.y - p1.y;
  return sqrt(dx * dx + dy * dy);
}

Point _calculateNormalizedPoint(
    Point reference, Point diagonal1, Point diagonal2, double targetDistance) {
  final dx = diagonal1.x - reference.x;
  final dy = diagonal1.y - reference.y;
  final currentDistance = sqrt(dx * dx + dy * dy);
  final scaleFactor = targetDistance / currentDistance;
  final normalizedX = reference.x + dx * scaleFactor;
  final normalizedY = reference.y + dy * scaleFactor;
  return Point(normalizedX, normalizedY);
}

void ShotLogicHandler(
    List<DateTime> Time, List<BoundingBox> BallBoxes, List<List<double>> Hoop) {
  if (Time.length >= 3) {
    bool _made = false;
    List<double> lx = [];
    List<double> ly = [];
    List<double> ti = [];
    List<List<double>> cr = [];
    for (int i = 0; i < BallBoxes.length; i++) {
      cr.add([BallBoxes[i].x, BallBoxes[i].y]);
      lx.add(BallBoxes[i].x);
      ly.add(BallBoxes[i].y);
      ti.add(fromDateTodouble(Time[i]));
    }

    bool _isIt = ParabolaChecker([time, lx, ly]);

    if (_isIt) {
      _made = ShotChecker(cr, Hoop);
    }
    if (_made) {
      Hit++;
    } else {
      Miss++;
    }
  }
}

double fromDateTodouble(DateTime d) {
  double t = 0;
  String s = "$d.minutes.$d.millisecond";
  t = double.parse(s);
  return t;
}
class BoundingBox {
  double x, y, width, height, confidence;
  int classId;
  BoundingBox(
      {required this.x,
      required this.y,
      required this.width,
      required this.height,
      required this.confidence,
      required this.classId});
}