import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_select/image_selector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Select App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Image Selector Example App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? file;

  CameraUiSettings cameraUiSettings = CameraUiSettings(
    appbarColor: Colors.teal,
    iconTheme: const IconThemeData(color: Colors.white),
    title: 'Shoot the Image',
    textStyle: const TextStyle(
      color: Colors.white,
    ),
  );
  pickImage(ImageFrom source) async {
    ImageSelect imageSelector = ImageSelect(cameraUiSettings: cameraUiSettings);
    await imageSelector.pickImage(context: context, source: source).then((pickedFile) {
      if (pickedFile != null) {
        setState(() {
          file = pickedFile;
        });
        Navigator.pop(context);
      }
    });
  }

  showSourceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Source',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                onTap: () => pickImage(ImageFrom.camera),
                title: const Text('Camera'),
              ),
              ListTile(
                title: const Text('Gallery'),
                onTap: () => pickImage(ImageFrom.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 400,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade400),
              width: MediaQuery.of(context).size.width * 0.74,
              child: file != null ? Image.file(file!) : const SizedBox.shrink(),
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: showSourceDialog,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.deepPurple,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Slect Image',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
