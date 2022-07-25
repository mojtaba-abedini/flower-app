import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'IRANSans',
      ),
      home: MyHomePage(title: 'تطبیق گل و گیاه'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  List _output;
  final picker = ImagePicker();
  String label;

  @override
  void initState() {
    super.initState();

    loadModelFiles().then((value) {
      setState(() {});
    });
  }

  loadModelFiles() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Tflite.close();
    super.dispose();
  }

  detectImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.6,
      imageMean: 127.5,
      // defaults to 117.0
      imageStd: 127.5, // defaults to 1.0
    );
    setState(() {
      _output = output;
    });
  }

  Future<void> chooseImageFromGallery() async {
    var appDir = (await getTemporaryDirectory()).path;
    new Directory(appDir).delete(recursive: true);

    var image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });

    detectImage(_image);

    print(_output);
    outputLabel();
  }

  Future<void> captureImageFromCamera() async {
    var appDir = (await getTemporaryDirectory()).path;
    new Directory(appDir).delete(recursive: true);

    var image = await picker.getImage(source: ImageSource.camera);

    setState(() {
      _image = File(image.path);
    });

    detectImage(_image);

    print(_output);
    outputLabel();
  }

  outputLabel() {
    (_output != null && (_output[0]['confidence'] as double) > 0.97)
        ? label = ('نام : ${_output[0]['label']}' +
            "\n" +
            'میزان تطبیق : ${(_output[0]['confidence'])}')
        : label = 'نتیجه ای پیدا نشد';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image != null
                ? Image.file(
                    _image,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Icon(
                    Icons.image,
                    size: 100,
                  ),
            Container(
              margin: EdgeInsets.only(top: 20),
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox.fromSize(
                    size: Size(100, 100), // button width and height
                    child: ClipOval(
                      child: Material(
                        color: Colors.blue, // button color
                        child: InkWell(
                          splashColor: Colors.green, // splash color
                          onTap: () {
                            captureImageFromCamera();
                          }, // button pressed
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                              ), // icon
                              Text("Camera"), // text
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 25),
                  SizedBox.fromSize(
                    size: Size(100, 100), // button width and height
                    child: ClipOval(
                      child: Material(
                        color: Colors.blue, // button color
                        child: InkWell(
                          splashColor: Colors.green, // splash color
                          onTap: () {
                            chooseImageFromGallery();
                          }, // button pressed
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.photo,
                                size: 40,
                              ), // icon
                              Text("Gallery"), // text
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: label != null
                  ? Text('$label',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20))
                  : Text(''),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    ));
  }
}
