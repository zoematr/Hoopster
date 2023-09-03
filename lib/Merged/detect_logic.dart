
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;


import 'package:tflite_flutter/tflite_flutter.dart';



import 'package:flutter/material.dart';

import 'package:hoopster/Merged/around_box.dart';


import 'package:flutter/cupertino.dart';


import 'dart:typed_data';


import 'package:exif/exif.dart';



enum _Codes {
  init,
  busy,
  ready,
  detect,
  result,
}


class _Command {
  const _Command(this.code, {this.args});

  final _Codes code;
  final List<Object>? args;
}


class Detector {
  static const String _modelPath = 'AssetsFolder\\newmodel.tflite';
  static const String _labelPath = 'AssetsFolder\\labelmap.txt';

  Detector._(this._isolate, this._interpreter, this._labels);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final List<String> _labels;


  late final SendPort _sendPort;

  bool _isReady = false;


  final StreamController<Map<String, dynamic>> resultsStream =
      StreamController<Map<String, dynamic>>();

  
  static Future<Detector> start() async {
    final ReceivePort receivePort = ReceivePort();
  
    final Isolate isolate =
        await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

    final Detector result = Detector._(
      isolate,
      await _loadModel(),
      await _loadLabels(),
    );
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  static Future<Interpreter> _loadModel() async {
    final interpreterOptions = InterpreterOptions();

  
    if (Platform.isAndroid) {
  
    }

  
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }

    return Interpreter.fromAsset(
      _modelPath,
      options: interpreterOptions..threads = 4,
    );
  }

  static Future<List<String>> _loadLabels() async {
    return (await rootBundle.loadString(_labelPath)).split('\n');
  }

  
  void processFrame(CameraImage cameraImage) {
    if (_isReady) {
      _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
    }
  }

  
  void _handleCommand(_Command command) {
    switch (command.code) {
      case _Codes.init:
        _sendPort = command.args?[0] as SendPort;
        
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_Codes.init, args: [
          rootIsolateToken,
          _interpreter.address,
          _labels,
        ]));
        return;
      case _Codes.ready:
        _isReady = true;
        return;
      case _Codes.busy:
        _isReady = false;
        return;
      case _Codes.result:
        _isReady = true;
        resultsStream.add(command.args?[0] as Map<String, dynamic>);
        return;
      default:
        debugPrint('Detector unrecognized command: ${command.code}');
    }
  }

  
  void stop() {
    _isolate.kill();
  }
}


class _DetectorServer {

  static const int mlModelInputSize = 300;


  static const double confidence = 0.5;
  Interpreter? _interpreter;
  List<String>? _labels;

  _DetectorServer(this._sendPort);

  final SendPort _sendPort;

  

  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
   
    sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
  }

  
  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _Codes.init:
       
        RootIsolateToken rootIsolateToken =
            command.args?[0] as RootIsolateToken;
       
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _labels = command.args?[2] as List<String>;
        _sendPort.send(const _Command(_Codes.ready));
        return;
      case _Codes.detect:
        _sendPort.send(const _Command(_Codes.busy));
        _convertCameraImage(command.args?[0] as CameraImage);
        return;
      default:
        debugPrint('_DetectorService unrecognized command ${command.code}');
    }
  }

  void _convertCameraImage(CameraImage cameraImage) {
    var preConversionTime = DateTime.now().millisecondsSinceEpoch;

    convertCameraImageToImage(cameraImage).then((image) {
      if (image != null) {
        if (Platform.isAndroid) {
          image = image_lib.copyRotate(image, angle: 90);
        }

        final results = analyseImage(image, preConversionTime);
        _sendPort.send(_Command(_Codes.result, args: [results]));
      }
    });
  }

  Map<String, dynamic> analyseImage(
      image_lib.Image? image, int preConversionTime) {
    var conversionElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;

    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

   
    final imageInput = image_lib.copyResize(
      image!,
      width: mlModelInputSize,
      height: mlModelInputSize,
    );

    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return Uint8List.fromList(
              [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
        },
      ),
    );

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    final output = _runInference(imageMatrix);

    
    final locationsRaw = output.first.first as List<List<double>>;

    final List<Rect> locations = locationsRaw
        .map((list) => list.map((value) => (value * mlModelInputSize)).toList())
        .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
        .toList();

    
    final classesRaw = output.elementAt(1).first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();

    
    final scores = output.elementAt(2).first as List<double>;

    
    final numberOfDetectionsRaw = output.last.first as double;
    final numberOfDetections = numberOfDetectionsRaw.toInt();

    final List<String> classification = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classification.add(_labels![classes[i]]);
    }

    
    List<Identification> recognitions = [];
    for (int i = 0; i < numberOfDetections; i++) {
    
      var score = scores[i];
      
      String label = classification[i];
      bool eq = (label.substring(0,label.length-1)== "sports ball");
      print("${label.substring(0,label.length-1)} and laptop are equal? ${eq}");

      if (score > confidence /*&& eq*/) {
        recognitions.add(
          Identification(i, label, score, locations[i]),
        );
      }
    }

    var inferenceElapsedTime =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    var totalElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preConversionTime;

    return {
      "recognitions": recognitions,
      "stats": <String, String>{
        'Conversion time:': conversionElapsedTime.toString(),
        'Pre-processing time:': preProcessElapsedTime.toString(),
        'Inference time:': inferenceElapsedTime.toString(),
        'Total prediction time:': totalElapsedTime.toString(),
        'Frame': '${image.width} X ${image.height}',
      },
    };
  }


  List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) {
    
    final input = [imageMatrix];

    
    final output = {
      0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
      1: [List<num>.filled(10, 0)],
      2: [List<num>.filled(10, 0)],
      3: [0.0],
    };

    _interpreter!.runForMultipleInputs([input], output);
    return output.values.toList();
  }
}

bool theSame(String a, String b) {
  bool res = false;
  int c = 0;
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] == b[i]) {
      c++;
    } else {}
  }
  if (c == a.length) {
    res = true;
  }
  return res;
}

//SPACE//////////////////////////////////////////////////////////////////////////////////////////////////////




class TrackingWidget extends StatefulWidget {
  
  
  const TrackingWidget({super.key});

  @override
  State<TrackingWidget> createState() => _TrackingWidgetState();
}

class _TrackingWidgetState extends State<TrackingWidget>
    with WidgetsBindingObserver {
 
  late List<CameraDescription> cameras;


  CameraController? _cameraController;

  
  get _controller => _cameraController;

  
  
  Detector? _detector;
  StreamSubscription? _subscription;


  List<Identification>? results;


  Map<String, String>? stats;

  @override
  void initState() {
  
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStateAsync();
  }

  void _initStateAsync() async {
    
    _initializeCamera();
    
    Detector.start().then((instance) {
      setState(() {
        _detector = instance;
        _subscription = instance.resultsStream.stream.listen((values) {
          setState(() {
            results = values['recognitions'];
            stats = values['stats'];
          });
        });
      });
    });
  }

  
  void _initializeCamera() async {
    cameras = await availableCameras();
    
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false)
      ..initialize().then((_) async {
        
        await _controller.startImageStream(onLatestImageAvailable);
        setState(() {});

       
        ScreenParams.previewSize = _controller.value.previewSize!;
      });
  }

  @override
  Widget build(BuildContext context) {

    if (_cameraController == null || !_controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    var aspect = 1 / _controller.value.aspectRatio;

   return Stack(
      children: [
        AspectRatio(
          aspectRatio: aspect,
          child: CameraPreview(_controller),
        ),
        
        AspectRatio(
          aspectRatio: aspect,
          child: boundBoxes(),
        ),
      ],
    );
  }



  
  Widget boundBoxes() {
    if (results == null) {
      return const SizedBox.shrink();
    }
    return Stack(
        children: results!.map((box) => Boxes(result: box)).toList());
  }

  
  void onLatestImageAvailable(CameraImage cameraImage) async {
    _detector?.processFrame(cameraImage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _cameraController?.stopImageStream();
        _detector?.stop();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        _initStateAsync();
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
  }
}

//SPACE//////////////////////////////////////////////////////////////////////////////////////////////////////





class Identification {

  final int _id;

  
  final String _label;

  
  final double _score;

 
  final Rect _location;

  Identification(this._id, this._label, this._score, this._location);

  int get id => _id;

  String get label => _label;

  double get score => _score;

  Rect get location => _location;

  
  Rect get renderLocation {
    final double scaleX = ScreenParams.screenPreviewSize.width / 300;
    final double scaleY = ScreenParams.screenPreviewSize.height / 300;
    return Rect.fromLTWH(
      location.left * scaleX,
      location.top * scaleY,
      location.width * scaleX,
      location.height * scaleY,
    );
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}

//SPACE//////////////////////////////////////////////////////////////////////////////////////////////////////




Future<image_lib.Image?> convertCameraImageToImage(
    CameraImage cameraImage) async {
  image_lib.Image image;

  if (cameraImage.format.group == ImageFormatGroup.yuv420) {
    image = convertYUV420ToImage(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
    image = convertBGRA8888ToImage(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.jpeg) {
    image = convertJPEGToImage(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
    image = convertNV21ToImage(cameraImage);
  } else {
    return null;
  }

  return image;
}

image_lib.Image convertYUV420ToImage(CameraImage cameraImage) {
  final width = cameraImage.width;
  final height = cameraImage.height;

  final uvRowStride = cameraImage.planes[1].bytesPerRow;
  final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

  final yPlane = cameraImage.planes[0].bytes;
  final uPlane = cameraImage.planes[1].bytes;
  final vPlane = cameraImage.planes[2].bytes;

  final image = image_lib.Image(width: width, height: height);

  var uvIndex = 0;

  for (var y = 0; y < height; y++) {
    var pY = y * width;
    var pUV = uvIndex;

    for (var x = 0; x < width; x++) {
      final yValue = yPlane[pY];
      final uValue = uPlane[pUV];
      final vValue = vPlane[pUV];

      final r = yValue + 1.402 * (vValue - 128);
      final g = yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
      final b = yValue + 1.772 * (uValue - 128);

      image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);

      pY++;
      if (x % 2 == 1 && uvPixelStride == 2) {
        pUV += uvPixelStride;
      } else if (x % 2 == 1 && uvPixelStride == 1) {
        pUV++;
      }
    }

    if (y % 2 == 1) {
      uvIndex += uvRowStride;
    }
  }
  return image;
}

image_lib.Image convertBGRA8888ToImage(CameraImage cameraImage) {
  
  final bytes = cameraImage.planes[0].bytes;

  
  final image = image_lib.Image.fromBytes(
    width: cameraImage.width,
    height: cameraImage.height,
    bytes: bytes.buffer,
    order: image_lib.ChannelOrder.rgba,
  );

  return image;
}

image_lib.Image convertJPEGToImage(CameraImage cameraImage) {
  
  final bytes = cameraImage.planes[0].bytes;

  
  final image = image_lib.decodeImage(bytes);

  return image!;
}

image_lib.Image convertNV21ToImage(CameraImage cameraImage) {
  
  final yuvBytes = cameraImage.planes[0].bytes;
  final vuBytes = cameraImage.planes[1].bytes;

  
  final image = image_lib.Image(
    width: cameraImage.width,
    height: cameraImage.height,
  );

  
  convertNV21ToRGB(
    yuvBytes,
    vuBytes,
    cameraImage.width,
    cameraImage.height,
    image,
  );

  return image;
}

void convertNV21ToRGB(Uint8List yuvBytes, Uint8List vuBytes, int width,
    int height, image_lib.Image image) {
  
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final yIndex = y * width + x;
      final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

      final yValue = yuvBytes[yIndex];
      final uValue = vuBytes[uvIndex * 2];
      final vValue = vuBytes[uvIndex * 2 + 1];

      
      final r = yValue + 1.402 * (vValue - 128);
      final g = yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
      final b = yValue + 1.772 * (uValue - 128);

      
      image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);
    }
  }
}



Future<int> getExifRotation(CameraImage cameraImage) async {
  final exifData = await readExifFromBytes(cameraImage.planes[0].bytes);
  final ifd = exifData['Image Orientation'];

  if (ifd != null) {
    return ifd.values.toList()[0];
  }
  return 1;
}

image_lib.Image applyExifRotation(image_lib.Image image, int exifRotation) {
  if (exifRotation == 1) {
    return image_lib.copyRotate(image, angle: 0);
  } else if (exifRotation == 3) {
    return image_lib.copyRotate(image, angle: 180);
  } else if (exifRotation == 6) {
    return image_lib.copyRotate(image, angle: 90);
  } else if (exifRotation == 8) {
    return image_lib.copyRotate(image, angle: 270);
  }

  return image;
}

Future<void> saveImage(
  image_lib.Image image,
  String path,
  String name,
) async {
  Uint8List bytes = image_lib.encodeJpg(image);
  final fileOnDevice = File('$path/$name.jpg');
  await fileOnDevice.writeAsBytes(bytes, flush: true);
}
