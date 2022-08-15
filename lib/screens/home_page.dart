import 'dart:io';
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:face_recognition/faceModule/utils.dart';
import 'package:face_recognition/screens/detection.dart';
import 'package:face_recognition/screens/view_criminals.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../faceModule/model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List actions = [
    "Add Criminal's Images",
    "Detect Criminals",
    "Veiw & Edit Added Criminals"
  ];
  Interpreter? interpreter;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _id = TextEditingController();
  FaceDetector faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate));
  dynamic data = {};
  Set tempIds = {};
  late File jsonFile;
  File? imgFile;
  Directory? tempDir;
  AwesomeDialog? alert;
  List<List> outputs = [];
  bool processing = false;
  bool localImageTaken = false;
  imglib.Image? localImage;
  double threshold = 1.0;

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        await faceDetector.close();
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('FaceSec'),
          ),
          body: SizedBox(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'background.jpg',
                  fit: BoxFit.fill,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    buildButton(0),
                    buildButton(1),
                    buildButton(2),
                    SizedBox(
                      height: size.height * 0.07,
                    )
                  ],
                )
              ],
            ),
          )),
    );
  }

  Widget buildButton(int index) {
    Size size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
          onTap: () => selectAction(index),
          child: Card(
            elevation: 15,
            color: Colors.white60,
            shadowColor: Colors.white,
            shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(13)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Text(
                  actions[index],
                  style: TextStyle(
                      fontSize: size.width * 0.06, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )),
    );
  }

  selectAction(int index) async {
    if (index == 0) {
      AwesomeDialog(
          context: context,
          dialogType: DialogType.INFO,
          title: "Important",
          descTextStyle: const TextStyle(fontSize: 17),
          desc:
              "You may select more than one(slightly different images) for better recognition accuracy. Before Proceeding, make sure that images of the criminal are available in your phone storage. There should be no faces except that of criminal in selected images.",
          btnCancelText: 'Go back',
          btnCancelOnPress: () {},
          btnOkText: 'Proceed',
          btnOkOnPress: () {
            selectImages(0);
          }).show();
    } else if (index == 1) {
      AwesomeDialog(
          context: context,
          btnCancelText: 'Detect in Image',
          btnOkText: 'Livefeed using camera',
          title: 'Select Mode',
          dialogType: DialogType.QUESTION,
          btnCancelOnPress: () {
            selectImages(1);
          },
          btnOkOnPress: () {
            _startLiveDetection();
          }).show();
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ViewCriminals(
                    results: false,
                    tempIds: {},
                  )));
    }
  }

  void selectImages(int count) async {
    var _picker = ImagePicker();
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images == null) {
      return;
    }
    if (count != 1) {
      showDetailsFilldialogue();
    }
    interpreter = await loadModel();
    processImages(images, count);
  }

  processImages(List<XFile> images, int count) async {
    if (count == 1) {
      if (!mounted) return;
      alert = AwesomeDialog(
          context: context,
          dialogType: DialogType.INFO,
          title: 'Processing image...',
          dismissOnBackKeyPress: false,
          dismissOnTouchOutside: false);
      alert!.show();
    }

    processing = true;
    for (int i = 0; i < images.length; i++) {
      File imgFile = File(images[i].path);
      imglib.Image? img = imglib.decodeImage(imgFile.readAsBytesSync());
      jsonFile = await getFile();
      if (jsonFile.existsSync()) {
        data = json.decode(jsonFile.readAsStringSync());
      }
      InputImage inputImage = getInputImage1(images[i].path);
      List<Face> result = await faceDetector.processImage(inputImage);
      if (count != 1) {
        if (result.isEmpty || result.length > 1) {
          continue;
        }
      } else if (result.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        alert!.dismiss();
        AwesomeDialog(
                context: context,
                btnOkOnPress: () {},
                title: 'No face found in selected image')
            .show();
        processing = false;
        return;
      }
      for (Face _face in result) {
        double x, y, w, h;
        x = (_face.boundingBox.left - 10);
        y = (_face.boundingBox.top - 10);
        w = (_face.boundingBox.width + 10);
        h = (_face.boundingBox.height + 10);
        imglib.Image croppedImage =
            imglib.copyCrop(img!, x.round(), y.round(), w.round(), h.round());
        if (count != 1) {
          if (localImageTaken == false) {
            localImage = croppedImage;
            localImageTaken = true;
          }
        }
        croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);
        recog(croppedImage, count);
      }
    }
    if (count == 1) {
      await Future.delayed(const Duration(seconds: 2));
      alert!.dismiss();
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ViewCriminals(
                    results: true,
                    tempIds: tempIds,
                  )));
      tempIds = {};
    }

    processing = false;
    interpreter?.close();
    localImageTaken = false;
  }

  void recog(imglib.Image img, int count) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List.filled(1 * 192, null, growable: false).reshape([1, 192]);
    interpreter!.run(input, output);
    output = output.reshape([192]);
    output = List.from(output);
    if (count != 1) {
      outputs.add(output);
      return;
    }
    String? res = compare(output);
    if (res != null) tempIds.add(res);
  }

  String? compare(List currEmb) {
    double minDist = 999;
    double currDist = 0.0;
    String? res;
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

  _startLiveDetection() async {
    var status = await Permission.camera.request();
    if (status == PermissionStatus.permanentlyDenied) {
      AwesomeDialog(
              context: context,
              dialogType: DialogType.INFO,
              title:
                  'Camera permission required. Please grant camera permission in settings for this app',
              btnOkText: 'OK',
              btnOkOnPress: () {})
          .show();
    } else if (status == PermissionStatus.denied) {
      AwesomeDialog(
              context: context,
              dialogType: DialogType.INFO,
              title: 'Camera permission required!',
              btnOkText: 'Grant permission',
              btnOkOnPress: () {
                selectAction(1);
              },
              btnCancelText: 'Cancel',
              btnCancelOnPress: () {})
          .show();
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FaceRecognitionView()));
    }
  }

  _handle(String name, String id) {
    if (data == null || !(data.keys.contains(id))) {
      data[id] = [name, outputs];
      jsonFile.writeAsStringSync(json.encode(data));
      showSuccessDilogue();
      saveImageToDisk(id);
      outputs = [];
      return;
    }
    AwesomeDialog(
      context: context,
      animType: AnimType.SCALE,
      dialogType: DialogType.INFO,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Criminal with this id, already exists. Id should be unique for each Criminal',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 20),
          ),
          const SizedBox(
            height: 20,
          ),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                showSuccessDilogue();
                data[id] = [name, outputs];
                jsonFile.writeAsStringSync(json.encode(data));
                outputs = [];
                saveImageToDisk(id);
              },
              child: const Text(
                'Replace existing',
                style: TextStyle(fontSize: 17),
              )),
          const SizedBox(
            height: 10,
          ),
          TextButton(
            // width: 140,
            onPressed: () {
              Navigator.pop(context);
              showDetailsFilldialogue();
            },
            child: const Text('Try with another id',
                style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(
            height: 10,
          ),
          TextButton(
            // width: 140,
            onPressed: () {
              Navigator.pop(context);
              localImage = null;
            },
            child: const Text('Cancel', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(
            height: 10,
          ),
        ]),
      ),
    ).show();
  }

  saveImageToDisk(String id) async {
    imgFile = await getImageFile(id);
    imgFile!.writeAsBytesSync(imglib.encodeJpg(localImage!));
    localImage = null;
  }

  showDetailsFilldialogue() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add Criminal Details"),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _id,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: "Criminal Id", icon: Icon(Icons.person)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _name,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: "Name", icon: Icon(Icons.face)),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  outputs = [];
                  _name.clear();
                  _id.clear();
                },
              ),
              TextButton(
                  child: const Text("Save",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  onPressed: () {
                    if (_name.text.isEmpty || _id.text.isEmpty) {
                    } else {
                      Navigator.pop(context);
                      if (processing == false) {
                        _handle(
                            _name.text.toUpperCase(), _id.text.toUpperCase());
                      } else {
                        alert = AwesomeDialog(
                            context: context,
                            dialogType: DialogType.INFO,
                            title: 'Processing images...',
                            dismissOnBackKeyPress: false,
                            dismissOnTouchOutside: false);
                        alert!.show();
                        while (processing == true) {}
                        alert!.dismiss();
                        _handle(
                            _name.text.toUpperCase(), _id.text.toUpperCase());
                      }
                      _name.clear();
                      _id.clear();
                    }
                  }),
            ],
          );
        });
  }

  showSuccessDilogue() {
    AwesomeDialog(
      context: context,
      animType: AnimType.LEFTSLIDE,
      headerAnimationLoop: false,
      dialogType: DialogType.SUCCES,
      showCloseIcon: true,
      title: 'Success',
      desc: 'Criminal Added Successfully',
      btnOkOnPress: () {},
      btnOkIcon: Icons.check_circle,
    ).show();
  }
}
