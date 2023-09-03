import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:hoopster/Merged/detect_logic.dart';


/// Individual bounding box
class Boxes extends StatelessWidget {
  final Identification result;

  const Boxes({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Color for bounding box
    Color color = Colors.primaries[
        (result.label.length + result.label.codeUnitAt(0) + result.id) %
            Colors.primaries.length];

    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        width: result.renderLocation.width,
        height: result.renderLocation.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: const BorderRadius.all(Radius.circular(2))),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(result.label),
                  Text(" ${result.score.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



/// Singleton to record size related data
class ScreenParams {
  static late Size screenSize;
  static late Size previewSize;

  static double previewRatio = max(previewSize.height, previewSize.width) /
      min(previewSize.height, previewSize.width);

  static Size screenPreviewSize =
      Size(screenSize.width, screenSize.width * previewRatio);
}
