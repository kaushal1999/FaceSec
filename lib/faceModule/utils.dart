import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:path_provider/path_provider.dart';

Future<CameraDescription> getCamera(CameraLensDirection dir) async {
  return await availableCameras().then(
    (List<CameraDescription> cameras) => cameras.firstWhere(
      (CameraDescription camera) => camera.lensDirection == dir,
    ),
  );
}

InputImageData buildMetaData(
  CameraImage image,
  InputImageRotation rotation,
) {
  return InputImageData(
    size: Size(image.width.toDouble(), image.height.toDouble()),
    imageRotation: rotation,
    inputImageFormat: InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21,
    planeData: image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList(),
  );
}

InputImage getInputImage(CameraImage image, CameraDescription description) {
  InputImageRotation rotation = rotationIntToImageRotation(
    description.sensorOrientation,
  );
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();
  InputImage inputImage = InputImage.fromBytes(
    bytes: bytes,
    inputImageData: buildMetaData(image, rotation),
  );
  return inputImage;
}

InputImage getInputImage1(String imagePath) {
  return InputImage.fromFilePath(imagePath);
}

InputImageRotation rotationIntToImageRotation(int rotation) {
  switch (rotation) {
    case 0:
      return InputImageRotation.rotation0deg;
    case 90:
      return InputImageRotation.rotation90deg;
    case 180:
      return InputImageRotation.rotation180deg;
    default:
      assert(rotation == 270);
      return InputImageRotation.rotation270deg;
  }
}

Float32List imageToByteListFloat32(
    imglib.Image image, int inputSize, double mean, double std) {
  var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < inputSize; i++) {
    for (var j = 0; j < inputSize; j++) {
      var pixel = image.getPixel(j, i);
      buffer[pixelIndex++] = (imglib.getRed(pixel) - mean) / std;
      buffer[pixelIndex++] = (imglib.getGreen(pixel) - mean) / std;
      buffer[pixelIndex++] = (imglib.getBlue(pixel) - mean) / std;
    }
  }
  return convertedBytes.buffer.asFloat32List();
}

double euclideanDistance(List e1, List e2) {
  double sum = 0.0;
  for (int i = 0; i < e1.length; i++) {
    sum += pow((e1[i] - e2[i]), 2);
  }
  return sqrt(sum);
}

Future<File> getFile() async {
  Directory tempDir = await getApplicationDocumentsDirectory();
  String _embPath = tempDir.path + '/emb.json';
  File jsonFile = File(_embPath);
  return jsonFile;
}

Future<File> getImageFile(String id) async {
  Directory tempDir = await getApplicationDocumentsDirectory();
  String _embPath = tempDir.path + id + '.jpg';
  File imageFile = File(_embPath);
  return imageFile;
}

String compareFaces(List currEmb, dynamic data) {
  double threshold = 1.0;
  double minDist = 999;
  double currDist = 0.0;
  String res = "unknown";
  for (String id in data.keys) {
    for (List list in data[id][1]) {
      currDist = euclideanDistance(list, currEmb);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        res = id;
      }
    }
  }
  return res;
}
