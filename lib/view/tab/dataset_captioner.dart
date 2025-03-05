import 'dart:io';
import 'package:dscaption/notifier/caption.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dscaption/view/page/home.dart';
import 'package:provider/provider.dart';

class DatasetCaptionerTab extends StatefulWidget {
  final HomePageState parentWidgetState;

  DatasetCaptionerTab({required this.parentWidgetState});

  @override
  DatasetCaptionerTabState createState() => DatasetCaptionerTabState();
}

class DatasetCaptionerTabState extends State<DatasetCaptionerTab> {
  TextEditingController initialFolderController = TextEditingController();
  TextEditingController separationDirController = TextEditingController();
  List<File> imageFiles = [];
  List<File> textFiles = [];
  String errorMessage = '';
  List<String> imageFileExtensions = ['.jpg', '.png'];

  void refreshFiles() async {
    setState(() {
      errorMessage = '';
    });

    String folderPath = initialFolderController.text;
    if (await Directory(folderPath).exists()) {
      List<FileSystemEntity> files = Directory(folderPath).listSync();
      imageFiles = files
          .where((file) => imageFileExtensions.any((ext) => file.path.endsWith(ext)))
          .map((file) => File(file.path))
          .toList();
      textFiles = files
          .where((file) => file.path.endsWith('.txt'))
          .map((file) => File(file.path))
          .toList();
      setState(() {});
    } else {
      setState(() {
        errorMessage = 'Invalid folder path';
      });
    }
  }

  void separateImages() async {
    String separationDir = separationDirController.text;

    if (!await Directory(separationDir).exists()) {
      try {
        await Directory(separationDir).create();
      } catch (e) {
        setState(() {
          errorMessage =
              'Separation folder does not exist and could not create folder';
        });
      }
    }

    if (await Directory(separationDir).exists()) {
      for (var imageFile in imageFiles) {
        String textFilePath = imageFile.path.replaceAll(RegExp(r'\.(jpg|png)$'), '.txt');
        if (!await File(textFilePath).exists()) {
          File(imageFile.path)
              .copy('$separationDir/${imageFile.path.split('/').last}');
        }
      }
    } else {
      setState(() {
        errorMessage = 'Invalid separation directory';
      });
    }
  }

  void captionImage(CaptionProvider captionProvider, File imageFile,
      TextEditingController textEditingController) async {
    try {
      await captionProvider.captionImage(imageFile.path);
      if (captionProvider.blipCaptionSuccess) {
        textEditingController.text = captionProvider.generatedCaption;
      } else {
        setState(() {
          errorMessage =
              'Error generating caption ' + captionProvider.errorOutput;
        });
      }

      // Handle the caption as needed
    } catch (e) {
      setState(() {
        errorMessage = 'Error generating caption';
      });
    }
  }

  Future<bool> askUserToInstallBlipCaption() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install blip_caption'),
        content:
            Text('blip_caption is not installed. Do you want to install it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dataset captioner'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: initialFolderController,
                      decoration: InputDecoration(labelText: 'Initial Folder'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: refreshFiles,
                    child: Text('Refresh'),
                  ),
                ],
              ),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              Row(
                children: [
                  Text('Images found: ${imageFiles.length}'),
                  SizedBox(width: 20),
                  Text('Text files found: ${textFiles.length}'),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: separationDirController,
                      decoration:
                          InputDecoration(labelText: 'Separation Directory'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: separateImages,
                    child: Text('Separate'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: imageFiles.length,
                  itemBuilder: (context, index) {
                    File imageFile = imageFiles[index];
                    String textFilePath =
                        imageFile.path.replaceAll(RegExp(r'\.(jpg|png)$'), '.txt');
                    TextEditingController textController =
                        TextEditingController();

                    if (File(textFilePath).existsSync()) {
                      textController.text =
                          File(textFilePath).readAsStringSync();
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Text(imageFile.path.split('/').last),
                            Consumer<CaptionProvider>(
                                builder: (context, captionProvider, child) {
                                  
                              if (captionProvider.askUserToInstallBlipCaption ==
                                  null) {
                                captionProvider.askUserToInstallBlipCaption =
                                    askUserToInstallBlipCaption;
                              }

                              return ElevatedButton(
                                onPressed: () =>
                                    captionProvider.captioningInProgress
                                        ? null
                                        : captionImage(captionProvider,
                                            imageFile, textController),
                                child: Text(captionProvider.captioningInProgress
                                    ? 'Captioning'
                                    : 'Caption'),
                              );
                            }),
                            ElevatedButton(
                              onPressed: () =>
                                  FlutterClipboard.copy(imageFile.path),
                              child: Text('Clipboard'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Process.run('open', [imageFile.path]),
                              child: Text('View Image'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Process.run('open', [textFilePath]),
                              child: Text('View Text'),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Image.file(imageFile, width: 100, height: 100),
                            Expanded(
                              child: TextField(
                                controller: textController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                File(textFilePath)
                                    .writeAsStringSync(textController.text);
                              },
                              child: Text('Update'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          )),
    );
  }
}
