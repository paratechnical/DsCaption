import 'package:dscaption/notifier/caption.dart';
import 'package:dscaption/view/page/home.dart';
import 'package:dscaption/view/tab/dataset_captioner.dart';
import 'package:dscaption/view/tab/image_captioner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// void main() {
//   runApp(MyApp());
// }

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CaptionProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DSCaption',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

