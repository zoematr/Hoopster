import 'dart:math' as math;

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

double sigmoid(double x) {
  return 1 / (1 + math.exp(-x));
}

List<BoundingBox> decodeTensor(List<double> tensor, double threshold) {
  int gridSize = 13;
  int numBoxes = 5;
  int numClasses = 2;

  var anchors = [
    0.57273,
    0.677385,
    1.87446,
    2.06253,
    3.33843,
    5.47434,
    7.88282,
    3.52778,
    9.77052,
    9.16828
  ];

  List<BoundingBox> boxes = [];

  for (int y = 0; y < gridSize; y++) {
    for (int x = 0; x < gridSize; x++) {
      for (int b = 0; b < numBoxes; b++) {
        int index = (y * gridSize + x) * numBoxes * (5 + numClasses) +
            b * (5 + numClasses);
        double tx = tensor[index];
        double ty = tensor[index + 1];
        double tw = tensor[index + 2];
        double th = tensor[index + 3];
        double confidence = sigmoid(tensor[index + 4]);

        double centerX = (sigmoid(tx) + x) / gridSize;
        double centerY = (sigmoid(ty) + y) / gridSize;
        double width = math.exp(tw) * anchors[2 * b] / gridSize;
        double height = math.exp(th) * anchors[2 * b + 1] / gridSize;

        if (confidence > threshold) {
          double maxClassProb = 0;
          int classId = 0;
          for (int c = 0; c < numClasses; c++) {
            double classProb = sigmoid(tensor[index + 5 + c]);
            if (classProb > maxClassProb) {
              maxClassProb = classProb;
              classId = c;
            }
          }

          double finalScore = confidence * maxClassProb;
          if (finalScore > threshold) {
            boxes.add(BoundingBox(
                x: centerX,
                y: centerY,
                width: width,
                height: height,
                confidence: finalScore,
                classId: classId));
          }
        }
      }
    }
  }

  return boxes;
}
