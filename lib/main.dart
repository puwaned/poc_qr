import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  String? thumbnailUrl;
  String? originalUrl;

  void _incrementCounter() async {
    await PhotoManager.requestPermissionExtend();
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
    final path = paths.where((element) => element.name == "K PLUS").toList()[0];
    final entity = await path.getAssetListRange(start: 0, end: 1);
    final original = await entity.first.file;
    final thumbnail = await getThumbnailImage(entity.first);

    if (original != null && thumbnail != null) {
      setState(() {
        originalUrl = original.path;
        thumbnailUrl = thumbnail.path;
      });
    }

    if (thumbnail != null) {
      await loopQr(thumbnail.path);
    }
    // if (original != null) {
    //   await loopQr(original.path);
    // }
    // final picker = ImagePicker();
    // final file = await picker.pickImage(source: ImageSource.gallery);
    // if (file != null) {

    // }
  }

  Future loopQr(String pathName) async {
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
    final inputImage = InputImage.fromFilePath(pathName);
    for (var i = 1; i <= 30; i++) {
      try {
        final barcodes = await barcodeScanner.processImage(inputImage);
        print('round: $i, value: ${barcodes.first.displayValue}');
      } catch (err) {
        print('round: $i, error:$err');
      }
    }
  }

  static Future<File?> getThumbnailImage(AssetEntity entity) async {
    final ratio = entity.height / entity.width;
    final height = (1000 * ratio).floor();
    final thumb = await entity.thumbnailDataWithSize(
      ThumbnailSize(entity.width, entity.height),
      format: ThumbnailFormat.jpeg,
      quality: 30,
    );

    if (thumb == null) return null;

    final idTemp = entity.id.replaceAll(r'/', '');
    final directory = await getTemporaryDirectory();
    final resizedImageFile = File('${directory.path}/$idTemp.jpg');
    await resizedImageFile.writeAsBytes(thumb);
    return resizedImageFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(onPressed: _incrementCounter, child: Text("Read")),
            const SizedBox(
              height: 30,
            ),
            Text('Original'),
            if (originalUrl != null) Image.file(File(originalUrl!)),
            const SizedBox(
              height: 10,
            ),
            Text('Thumbnail'),
            if (thumbnailUrl != null) Image.file(File(thumbnailUrl!)),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
