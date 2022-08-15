import 'dart:io';
import 'package:flutter/material.dart';

class CriminalTile extends StatelessWidget {
  final String name;
  final String id;
  final File file;
  const CriminalTile(
      {Key? key, required this.name, required this.id, required this.file})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.amber,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            iconColor: Colors.black,
            children: [
              Card(
                child: buildImage(),
              )
            ],
            leading: Text(id,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18))),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildImage() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Image.file(
        file,
        fit: BoxFit.contain,
      ),
    );
  }
}
