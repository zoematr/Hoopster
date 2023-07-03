import 'dart:ffi';
import 'dart:math';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/statsObjects.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import 'home_screen.dart';

int i = 0;
late CameraImage _cameraImage;
int counter = 0;
String lastSaved = "";
int Hit = 0;
int Miss = 0;
var height;
var width;
const int INPUT_SIZE = 419;
//late tfl.IsolateInterpreter isolate;
late tfl.Interpreter interpreter;

class CameraApp extends StatefulWidget {
  const CameraApp({Key? key}) : super(key: key);
  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  String _videoPath = '';
  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras.last,
      ResolutionPreset.low,
    );
    // Initiate the loading of the model

    loadModel().then((interpreter) {
      //isolate = tfl.IsolateInterpreter(address: interpreter.address);
      _initializeControllerFuture = controller.initialize().then((_) {
        controller.startImageStream((image) {
          _cameraFrameProcessing(image, interpreter);
        });
        if (!mounted) {
          return;
        }
        setState(() {});
      }).catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              // Handle access errors here.
              break;
            default:
              // Handle other errors here.
              break;
          }
        }
      });
    });
  }

  void _cameraFrameProcessing(CameraImage image, tfl.Interpreter interpreter) {
    _cameraImage = image;
    processCameraFrame(image, interpreter); // Process each camera frame
  }

  Future<tfl.Interpreter> loadModel() async {
    return tfl.Interpreter.fromAsset(
      'model.tflite',
      options: tfl.InterpreterOptions()..threads = 4,
    );
  }

  Future<void> processCameraFrame(
      CameraImage image, tfl.Interpreter interpreter) async {
    try {
      // Convert the CameraImage to a byte buffer

      Float32List convertedImage = convertCameraImage(image);
      List<List<int>> _outputShapes;
      List<tfl.TfLiteType> _outputTypes;
      var outputTensors = interpreter.getOutputTensors();
      _outputShapes = [];
      _outputTypes = [];
      outputTensors.forEach((tensor) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      });
      // Create output tensor. Assuming model has a single output

      TensorBuffer outputLocations = TensorBufferFloat(_outputShapes[0]);
      TensorBuffer outputClasses = TensorBufferFloat(_outputShapes[1]);
      TensorBuffer outputScores = TensorBufferFloat(_outputShapes[2]);
      TensorBuffer numLocations = TensorBufferFloat(_outputShapes[3]);
      Map<int, Object> outputs = {
        0: outputLocations.buffer,
        1: outputClasses.buffer,
        2: outputScores.buffer,
        3: numLocations.buffer,
      };
      // Create input tensor with the desired shape
      var inputShape = interpreter.getInputTensor(0).shape;
      //print(inputShape);
      //var inputShape = [1, 13, 13, 35];
      var inputTensor = <List<List<List<dynamic>>>>[
        List.generate(inputShape[1], (_) {
          return List.generate(inputShape[2], (_) {
            return List.generate(inputShape[3], (_) {
              return 0.0; // Placeholder value, modify this according to your needs
            });
          });
        })
      ];

      _outputShapes = [];
      _outputTypes = [];
      outputTensors.forEach((tensor) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      });

      // Copy the convertedImage data into the inputTensor
// Copy the convertedImage data into the inputTensor
      for (int i = 0; i < convertedImage.length; i++) {
        int index = i;
        int c = index % 3;
        index = index ~/ 3;
        int x = index % 512;
        index = index ~/ 512;

        int y = index;
        inputTensor[0][y][x][c] = convertedImage[i];
      }

      // Run inference on the frame

      //await isolate.run(inputTensor, {0: output});

      //isolate.close();
      //interpreter.close();
      interpreter.runForMultipleInputs(inputTensor, outputs);
      print(outputs);
      // Process the inference results
      //print("here2, line 120");
      //processInferenceResults(output);
    } catch (e) {
      print('Failed to run model on frame: $e');
    }
  }

  Float32List convertCameraImage(CameraImage image) {
    var width = image.width;
    var height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    // Create an Image buffer

    img.Image imago = img.Image(height: height, width: width);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;
        final int yValue = image.planes[0].bytes[index];
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];
        List rgbColor = yuv2rgb(yValue, uValue, vValue);
        // Set the pixel color
        imago.setPixelRgba(x, y, rgbColor[0], rgbColor[1], rgbColor[2], 1);
      }
    }
    // Resize the image to 416x416
    img.Image resizedImage = img.copyResize(imago, width: 512, height: 512);
    Float32List modelInput = Float32List(1 * 512 * 512 * 3);

    int pixelIndex = 0;
    for (int i = 0; i < 512; i++) {
      for (int j = 0; j < 512; j++) {
        var pixel = resizedImage.getPixelSafe(i, j);
        modelInput[pixelIndex] = pixel.r / 255.0;
        modelInput[pixelIndex + 1] = pixel.g / 255.0;
        modelInput[pixelIndex + 2] = pixel.b / 255.0;
        pixelIndex += 3;
      }
    }

    return modelInput;
  }

  void processInferenceResults(List<dynamic> output) {
    // Process the inference output to get the labels and their coordinates
    List<Map<String, dynamic>> labels = [];
    for (dynamic label in output) {
      String text = label['label'];
      double confidence = label['confidence'];
      Map<String, dynamic> coordinates = label['rect'];
      // Check if the label is "ball" or "hoop"
      if (text == "ball" || text == "hoop") {
        labels.add({
          'text': text,
          'confidence': confidence,
          'coordinates': coordinates,
        });
      }
    }
    if (labels.isEmpty) {
      // No recognitions found, do nothing
      return;
    }
    // Do something with the filtered labels
    // ...
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onRecordButtonPressed() async {
    try {
      if (controller.value.isRecordingVideo) {
        final path = await controller.stopVideoRecording();
        setState(() {
          _videoPath = path as String;
        });
        //processVideo(
        //    _videoPath); // Pass the video path to the processing function
      } else {
        await _initializeControllerFuture;
        final now = DateTime.now();
        final formattedDate =
            '${now.year}-${now.month}-${now.day} ${now.hour}-${now.minute}-${now.second}';
        final fileName = 'hoopster_${formattedDate}.mp4';
        final path = '${Directory.systemTemp.path}/$fileName';

        //await controller.startVideoRecording();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isInitialized) {
      return;
    }
    if (!controller.value.isRecordingVideo) {
      return;
    }
    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      print('Error: ${e.code}\n${e.description}');
      return;
    }
  }

  Future<void> _saveImage(List<int> _imageBytes) async {
    counter++;
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/frame${counter}.png';
    lastSaved = imagePath;
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(_imageBytes);
    print('Image saved to: $imagePath');
  }

  void capture() async {
    int _1 = Random().nextInt(20);
    int _2 = Random().nextInt(20);
    DateTime n = DateTime.now();
    setState(() {
      // allSessions.add(Session(n, _1, _2));
      // lView = globalUpdate();
    });
    if (_cameraImage != null) {
      Uint8List colored = Uint8List(_cameraImage.planes[0].bytes.length * 3);
      int b = 0;
      img.Image image = _cameraImage as img.Image;
      var input = [1, 13, 13, 3];
      //img.Image image = convertCameraImage(_cameraImage);
      img.Image Rimage = img.copyRotate(image, angle: 90);
      //_saveImage(Rimage.data);
      // Convert the image to RGB format using image package
      // img.Image image = img.Image.fromBytes(
      //   _cameraImage.width,
      //   _cameraImage.height,
      //   _cameraImage.planes[0].bytes,
      //   format: img.Format.yuv420,
      // );
      // img.Image Rimage = img.copyRotate(image, 90);
      // _saveImage(Rimage.getBytes(format: img.Format.rgb));
      // Run inference on the converted image
      // Process the inference results
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: Color.fromARGB(255, 255, 0, 0),
      );
    }
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            SizedBox(child: CameraPreview(controller)),
            Expanded(
              child: Container(
                color: Color.fromARGB(255, 93, 70, 94),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Hit.toString(),
                      style: TextStyle(
                        fontFamily: "Dogica",
                        fontSize: 60,
                        color: Color.fromARGB(255, 0, 255, 0),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB((w / 3) - 65, 0, (w / 3) - 65, 0),
                      child: GestureDetector(
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(basketButton),
                              fit: BoxFit.fill,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(80, 0, 0, 0),
                                spreadRadius: 1,
                                blurRadius: 5,
                              )
                            ],
                            color: Color.fromARGB(0, 255, 255, 255),
                            borderRadius: BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                        ),
                        onTap: () => {
                          //capture(),
                          setState(() {
                            Miss++;
                            Hit++;
                          })
                        },
                        onDoubleTap: () => {
                          //Session s= Session(DateTime.now(), 10, 7);
                        },
                      ),
                    ),
                    Text(
                      Miss.toString(),
                      style: TextStyle(
                        fontFamily: "Dogica",
                        fontSize: 60,
                        color: Color.fromARGB(255, 255, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Uint8List yuv2rgb(int y, int u, int v) {
  double yd = y.toDouble();
  double ud = u.toDouble() - 128.0;
  double vd = v.toDouble() - 128.0;
  double r = yd + 1.402 * vd;
  double g = yd - 0.344136 * ud - 0.714136 * vd;
  double b = yd + 1.772 * ud;
  r = r.clamp(0, 255).roundToDouble();
  g = g.clamp(0, 255).roundToDouble();
  b = b.clamp(0, 255).roundToDouble();
  return Uint8List.fromList([r.toInt(), g.toInt(), b.toInt()]);
}

TensorImage getProcessedImage(TensorImage inputImage) {
  int padSize;
  padSize = max(inputImage.height, inputImage.width);

  // create ImageProcessor
  ImageProcessor imageProcessor = ImageProcessorBuilder()
      // Padding the image
      .add(ResizeWithCropOrPadOp(padSize, padSize))
      // Resizing to input size
      .add(ResizeOp(419, 419, ResizeMethod.BILINEAR))
      .build();

  inputImage = imageProcessor.process(inputImage);
  return inputImage;
}
