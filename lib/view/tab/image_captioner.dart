import 'dart:async';
import 'dart:io';
import 'package:dscaption/constants/command_strings.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class ImageCaptionerTab extends StatefulWidget {

  ImageCaptionerTab({Key? key}) : super(key: key);
  
  @override
  ImageCaptionerTabState createState() => ImageCaptionerTabState();
}

class ImageCaptionerTabState extends State<ImageCaptionerTab> {
  String imagePath = '';
  String output = '';
  String generatedCaption = '';
  bool isCaptioning = false;
  StreamSubscription<String>? stdoutSubscription;
  StreamSubscription<String>? stderrSubscription;

  Future<String> obtainImageCaption(String path) async
  {
    setState(() {
        imagePath = path;
      });
      await captionImage();

      return generatedCaption;
  }

  void browseImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        imagePath = result.files.single.path!;
      });
    }
  }

  Future<void> captionImage() async {
    bool installedBlipCaption = false;

    setState(() {
      output = '';
      generatedCaption = '';
      isCaptioning = true;
    });

    if (!await isPythonInstalled()) {
      setState(() {
        output = 'Python is not installed.';
        isCaptioning = false;
      });
      return;
    }

    await createAndActivateVenv();

    if (!await isBlipCaptionInstalled()) {
      bool install = await askUserToInstallBlipCaption();
      if (!install) {
        setState(() {
          output = 'blip_caption installation cancelled.';
        });
        return;
      }
      installedBlipCaption =
          await installBlipCaption();
    } else {
      installedBlipCaption = true;
    }

    if (installedBlipCaption) {
      await runBlipCaption();
    }
  }

  Future<bool> isPythonInstalled() async {
    try {
      await Process.run(CommandStrings.pythonCommand, ['--version']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> createAndActivateVenv() async {
    if (!Directory(CommandStrings.venvName).existsSync()) {
      await Process.run(CommandStrings.pythonCommand, ['-m', 'venv', CommandStrings.venvName]);
      await Process.run(CommandStrings.activateVenvCommand,[]);
    }
  }

  Future<bool> isBlipCaptionInstalled() async {
    try {
      ProcessResult blipCheck = await Process.run(
          CommandStrings.pipCommandInsideVenv, ['show', 'blip_caption']);
      return blipCheck.exitCode == 0;
    } catch (e) {
      return false;
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

  Future<bool> installBlipCaption() async {
    bool installedBlipCaption = false;
    setState(() {
      output += 'installing blip_caption...';
    });

    if (Platform.isMacOS) {
      if (!await installTorchVision()) {
        return false;
      }
    }

    Process process = await Process.start(
        CommandStrings.pipCommandInsideVenv, ['install', 'blip_caption']);

    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      setState(() {
        output += data;
      });
    }) as StreamSubscription<String>?;

    stderrSubscription = process.stderr.transform(utf8.decoder).listen((data) {
      setState(() {
        output += data;
      });
    }) as StreamSubscription<String>?;

    int exitCode = await process.exitCode;
    if (exitCode == 0) {
      setState(() {
        output += '\nblip_caption installed.';
      });
      installedBlipCaption = true;
    } else {
      setState(() {
        output += '\nError installing blip_caption.';
      });
    }

    await stdoutSubscription?.cancel();
    await stderrSubscription?.cancel();

    return installedBlipCaption;
  }

  Future<bool> installTorchVision() async {
    bool installedTorchVision = false;

    Process process = await Process.start(CommandStrings.pipCommandInsideVenv, [
      'install',
      '--pre',
      'torch',
      'torchvision',
      'torchaudio',
      '--extra-index-url',
      'https://download.pytorch.org/whl/nightly/cpu'
    ]);

    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      setState(() {
        output += data;
      });
    }) as StreamSubscription<String>?;

    stderrSubscription = process.stderr.transform(utf8.decoder).listen((data) {
      setState(() {
        output += data;
      });
    }) as StreamSubscription<String>?;

    int exitCode = await process.exitCode;
    if (exitCode == 0) {
      setState(() {
        output += '\ntorchvision installed.';
      });
      installedTorchVision = true;
    } else {
      setState(() {
        output += '\nError installing torchvision.';
      });
    }

    await stdoutSubscription?.cancel();
    await stderrSubscription?.cancel();

    return installedTorchVision;
  }

  Future<void> runBlipCaption() async {
    setState(() {
      output += 'obtaining image caption...';
    });

    Process process = await Process.start(
        CommandStrings.pipCommandInsideVenv, ['-m', 'blip_caption', imagePath, '--large']);

    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      setState(() {
        output += data;
      });
    }) as StreamSubscription<String>?;

    stderrSubscription = process.stderr.transform(utf8.decoder).listen((data) {
      setState(() {
        output += data;
      });
    }) as StreamSubscription<String>?;

    int exitCode = await process.exitCode;
    if (exitCode == 0) {
      setState(() {
        generatedCaption = output;
        output += 'Success: ' + output;
      });
    } else {
      setState(() {
        output += 'Error: ' + output;
      });
    }

    await stdoutSubscription?.cancel();
    await stderrSubscription?.cancel();

    setState(() {
      isCaptioning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Captioning'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: browseImage,
              child: Text('Browse'),
            ),
            TextField(
              controller: TextEditingController(text: imagePath),
              decoration: InputDecoration(labelText: 'ImagePath'),
              readOnly: true,
            ),
            ElevatedButton(
              onPressed: isCaptioning ? null : captionImage,
              child: Text(isCaptioning ? 'Captioning...' : 'Caption'),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: TextField(
                  controller: TextEditingController(text: output),
                  decoration: InputDecoration(labelText: 'Output'),
                  readOnly: true,
                  maxLines: 5,
                  expands: false,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: TextField(
                  controller: TextEditingController(text: generatedCaption),
                  decoration: InputDecoration(labelText: 'GeneratedCaption'),
                  readOnly: true,
                  maxLines: 5,
                  expands: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}