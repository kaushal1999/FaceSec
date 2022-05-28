import 'dart:convert';
import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import '../faceModule/utils.dart';
import '../widgets/itemWidget.dart';

class ViewCriminals extends StatefulWidget {
 final bool results;
  final Set tempIds;
  const ViewCriminals({Key? key, required this.results, required this.tempIds})
      : super(key: key);

  @override
  State<ViewCriminals> createState() => _ViewCriminalsState();
}

class _ViewCriminalsState extends State<ViewCriminals> {
  dynamic data = {};
  late File jsonFile;
  bool setting = true;
  List<File> imgFiles = [];
  late bool results;
  late Set tempIds;
  @override
  void initState() {
    super.initState();
    setLocalData();
    results = widget.results;
    tempIds = widget.tempIds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(results ? 'Detected Criminals' : 'Added Criminals'),
        ),
        floatingActionButton: results
            ? Container()
            : (data.isEmpty)
                ? Container()
                : IconButton(
                    onPressed: () {
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.WARNING,
                        headerAnimationLoop: false,
                        animType: AnimType.TOPSLIDE,
                        showCloseIcon: true,
                        closeIcon: const Icon(Icons.close_fullscreen_outlined),
                        title: 'Warning',
                        descTextStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        desc:
                            'Click OK to detele all Criminals. Note: You can detele a single entry by sliding it left or right',
                        btnCancelOnPress: () {},
                        btnOkOnPress: () {
                          setState(() {
                            data = {};
                          });
                          jsonFile.writeAsStringSync(json.encode(data));
                        },
                      ).show();
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.black,
                    )),
        body: (setting)
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ((data.isEmpty && !results) || (tempIds.isEmpty && results))
                ? Center(
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(
                            Icons.auto_stories_outlined,
                            color: Colors.white,
                            size: 50,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            results
                                ? "No Criminal Detected in selected image"
                                : "No Criminal Added Yet",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    color: Colors.blueGrey[300],
                    child: ListView.builder(
                        itemCount: results ? tempIds.length : data.length,
                        itemBuilder: (context, index) {
                          final item = results
                              ? tempIds.elementAt(index)
                              : data.keys.elementAt(index);
                          return Dismissible(
                              background: Container(
                                color: Colors.red,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.delete,
                                        size: 25,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.delete,
                                        size: 25,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              key: Key(item),
                              onDismissed: results
                                  ? (_) {}
                                  : (_) {
                                      setState(() {
                                        data.remove(item);
                                        jsonFile.writeAsStringSync(
                                            json.encode(data));
                                      });
                                    },
                              child: ItemWidget(
                                  name: data[item][0],
                                  id: item,
                                  file: imgFiles[index]));
                        }),
                  ));
  }

  Future<void> setLocalData() async {
    jsonFile = await getFile();
    if (jsonFile.existsSync()) {
      data = json.decode(jsonFile.readAsStringSync());
    }
    dynamic keys = results ? tempIds : data.keys;
    for (String id in keys) {
      imgFiles.add(await getImageFile(id));
    }
    setState(() {
      setting = false;
    });
  }
}
