import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';
import 'package:face_recognition/faceModule/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiver/collection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../faceModule/face_painter.dart';
import '../faceModule/utils.dart';

class FaceRecognitionView extends StatefulWidget {
  const FaceRecognitionView({Key? key}) : super(key: key);

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
  FaceDetector faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate));
  AudioCache player = AudioCache(prefix: 'assets/');
  late File jsonFile;
  bool closingCamera = false;
  Interpreter? interpreter;
  CameraController? _camera;
  dynamic data = {};
  bool _isDetecting = false;
  double threshold = 1.0;
  dynamic _scanResults;
  String _predRes = '';
  bool isStream = true;
  Directory? tempDir;
  List? e1;
  bool loading = true;
  var direction = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _start();
    player.load('alarm.mp3');
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  void _start() async {
    interpreter = await loadModel();
    initCamera();
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_camera != null) {
          await _camera!.stopImageStream();
          setState(() {
            closingCamera = true;
          });
          await _camera!.dispose();
          _camera = null;
          await faceDetector.close();
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Detecting...'),
        ),
        floatingActionButton: loading
            ? Container()
            : FloatingActionButton(
                onPressed: () {
                  if (direction == CameraLensDirection.front) {
                    direction = CameraLensDirection.back;
                  } else {
                    direction = CameraLensDirection.front;
                  }
                  toggleCamera();
                },
                child: const Icon(Icons.cameraswitch),
              ),
        body: closingCamera
            ? Container()
            : Builder(builder: (context) {
                if ((_camera == null || !_camera!.value.isInitialized) ||
                    loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Container(
                  alignment: Alignment.center,
                  // constraints: const BoxConstraints.expand(),
                  child: _camera == null
                      ? const Center(child: SizedBox())
                      : Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            CameraPreview(_camera!),
                            _buildResults(),
                          ],
                        ),
                );
              }),
      ),
    );
  }

  Widget _buildResults() {
    if (_scanResults == null ||
        _camera == null ||
        !_camera!.value.isInitialized) {
      return const SizedBox();
    }
    CustomPainter painter;

    final Size imageSize = Size(
      _camera!.value.previewSize!.height,
      _camera!.value.previewSize!.width,
    );
    painter = FaceDetectorPainter(imageSize, _scanResults, direction);
    bool check = _scanResults!.keys.any((e) => (e != "UNKNOWN"));
    if (check) {
      player.play('alarm.mp3',
          mode: PlayerMode.LOW_LATENCY, isNotification: true);
    }
    return CustomPaint(
      painter: painter,
    );
  }

  void initCamera() async {
    CameraDescription description = await getCamera(direction);
    _camera = CameraController(
      description,
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _camera!.initialize();
    loading = false;
    jsonFile = await getFile();
    if (jsonFile.existsSync()) {
      data = json.decode(jsonFile.readAsStringSync());
    }

    _camera!.startImageStream((CameraImage image) async {
      if (_camera != null) {
        if (_isDetecting) return;
        _isDetecting = true;
        dynamic finalResult = Multimap<String, Face>();

        InputImage inputImage = getInputImage(image, description);
        List<Face> result = await faceDetector.processImage(inputImage);

        String res;
        Face _face;

        imglib.Image convertedImage = convertCameraImage(image, direction);

        for (_face in result) {
          double x, y, w, h;
          x = (_face.boundingBox.left - 10);
          y = (_face.boundingBox.top - 10);
          w = (_face.boundingBox.width + 10);
          h = (_face.boundingBox.height + 10);
          imglib.Image croppedImage = imglib.copyCrop(
              convertedImage, x.round(), y.round(), w.round(), h.round());
          croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);
          res = recog(croppedImage);
          finalResult.add(res, _face);
        }
        _scanResults = finalResult;
        _isDetecting = false;
        setState(() {});
      }
    });
  }

  String recog(imglib.Image img) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List.filled(1 * 192, null, growable: false).reshape([1, 192]);
    interpreter!.run(input, output);
    output = output.reshape([192]);
    e1 = List.from(output);
    return compare(e1!).toUpperCase();
  }

  String compare(List currEmb) {
    double minDist = 999;
    double currDist = 0.0;
    _predRes = "unknown";
    for (String id in data.keys) {
      for (List list in data[id][1]) {
        currDist = euclideanDistance(list, currEmb);
        if (currDist <= threshold && currDist < minDist) {
          minDist = currDist;
          _predRes = data[id][0];
        }
      }
    }
    return _predRes;
  }

  Future<void> toggleCamera() async {
    initCamera();
  }
}
