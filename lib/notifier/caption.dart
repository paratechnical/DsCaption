import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dscaption/model/operation_result.dart';
import 'package:flutter/material.dart';

class CaptionProvider with ChangeNotifier {
  StreamSubscription<String>? _stdoutSubscription;

  StreamSubscription<String>? get stdoutSubscription => _stdoutSubscription;

  set stdoutSubscription(StreamSubscription<String>? value) {
    _stdoutSubscription = value;
  }

  StreamSubscription<String>? _stderrSubscription;

  StreamSubscription<String>? get stderrSubscription => _stderrSubscription;

  set stderrSubscription(StreamSubscription<String>? value) {
    _stderrSubscription = value;
  }

  Future<bool> Function()? _askUserToInstallBlipCaption;

  Future<bool> Function()? get askUserToInstallBlipCaption =>
      _askUserToInstallBlipCaption;

  set askUserToInstallBlipCaption(Future<bool> Function()? value) {
    _askUserToInstallBlipCaption = value;
  }

  String _generalOutput = "";
  String _errorOutput = "";
  String _imagePath = "";
  String _generatedCaption = "";
  bool _installedBlipCaption = false;
  bool _captioningInProgress = false;
  bool _blipCaptionSuccess = false;

  String get generalOutput => _generalOutput;
  String get errorOutput => _errorOutput;
  String get imagePath => _imagePath;
  String get generatedCaption => _generatedCaption;
  bool get captioningInProgress => _captioningInProgress;
  bool get blipCaptionSuccess => _blipCaptionSuccess;

  void _startCaptioning() {
    _generalOutput = "";
    _errorOutput = "";
    _captioningInProgress = true;
    _blipCaptionSuccess = false;
    notifyListeners();
  }

  void _finishCaptioning(bool success) {
    _captioningInProgress = false;
    _blipCaptionSuccess = success;
    notifyListeners();
  }

  Future<void> captionImage(String imagePath) async {
    _imagePath = imagePath;
    _startCaptioning();

    String pythonCommand = Platform.isMacOS ? 'python3' : 'python';

    String pipCommand = Platform.isMacOS ? 'pip3' : 'pip';

    if (!await isPythonInstalled(pythonCommand)) {
      //throw Exception('Python is not installed.');
      _errorOutput += "Python is not installed.\n";
    }

    await createAndActivateVenv(pythonCommand);

    if (!await isBlipCaptionInstalled(pythonCommand, pipCommand)) {
      if (askUserToInstallBlipCaption != null) {
        bool install = await askUserToInstallBlipCaption!.call();
        if (!install) {
          //throw Exception('blip_caption installation cancelled');
          _errorOutput += "blip_caption installation cancelled\n";
        }
      } else {
        //throw Exception('could not request blip_caption installation');
        _errorOutput += "could not request blip_caption installation\n";
      }

      _installedBlipCaption =
          await installBlipCaption(pythonCommand, pipCommand);
    } else {
      _installedBlipCaption = true;
    }

    if (_installedBlipCaption) {
      await runBlipCaption(pythonCommand);
    } else {
      // throw Exception(
      //     "could not determine wether blip captioning is installed ");
      _errorOutput +=
          "could not determine wether blip captioning is installed\n";
    }
  }

  Future<bool> isPythonInstalled(String pythonCommand) async {
    try {
      await Process.run(pythonCommand, ['--version']);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> createAndActivateVenv(String pythonCommand) async {
    if (!Directory('currentvenv').existsSync()) {
      await Process.run(pythonCommand, ['-m', 'venv', 'currentvenv']);
    }
  }

  Future<bool> isBlipCaptionInstalled(
      String pythonCommand, String pipCommand) async {
    try {
      ProcessResult blipCheck = await Process.run(
          'currentvenv/bin/${pipCommand}', ['show', 'blip_caption']);
      return blipCheck.exitCode == 0;
    } catch (e) {
      //throw Exception('blip_caption installation cancelled');
      _errorOutput +=
          "blip_caption installation cancelled\n";
      return false;
    }
  }

  Future<bool> installBlipCaption(
      String pythonCommand, String pipCommand) async {
    bool installedBlipCaption = false;

    if (Platform.isMacOS) {
      if (!await installTorchVision(pythonCommand, pipCommand)) {
        return false;
      }
    }

    Process process = await Process.start(
        'currentvenv/bin/${pipCommand}', ['install', 'blip_caption']);

    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      _generalOutput += data + "\n";
    }) as StreamSubscription<String>?;

    stderrSubscription = process.stderr.transform(utf8.decoder).listen((data) {
      _errorOutput += data + "\n";
    }) as StreamSubscription<String>?;

    int exitCode = await process.exitCode;
    if (exitCode == 0) {
      _generalOutput += 'blip_caption installed.\n';
      installedBlipCaption = true;
    } else {
      _generalOutput += 'Error installing blip_caption.\n';
    }

    await stdoutSubscription?.cancel();
    await stderrSubscription?.cancel();

    return installedBlipCaption;
  }

  Future<bool> installTorchVision(
      String pythonCommand, String pipCommand) async {
    bool installedTorchVision = false;

    Process process = await Process.start('currentvenv/bin/${pipCommand}', [
      'install',
      '--pre',
      'torch',
      'torchvision',
      'torchaudio',
      '--extra-index-url',
      'https://download.pytorch.org/whl/nightly/cpu'
    ]);

    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      _generalOutput += data + "\n";
    }) as StreamSubscription<String>?;

    stderrSubscription = process.stderr.transform(utf8.decoder).listen((data) {
      _generalOutput += data + "\n";
    }) as StreamSubscription<String>?;

    int exitCode = await process.exitCode;
    if (exitCode == 0) {
      _generalOutput += '\ntorchvision installed.';

      installedTorchVision = true;
    } else {
      _generalOutput += '\nError installing torchvision.';
    }

    await stdoutSubscription?.cancel();
    await stderrSubscription?.cancel();

    return installedTorchVision;
  }

  Future<void> runBlipCaption(String pythonCommand) async {
    _generalOutput += 'obtaining image caption...\n';

    Process process = await Process.start('currentvenv/bin/${pythonCommand}',
        ['-m', 'blip_caption', _imagePath, '--large']);

    stdoutSubscription = process.stdout.transform(utf8.decoder).listen((data) {
      _generalOutput += data + "\n";
    }) as StreamSubscription<String>?;

    stderrSubscription = process.stderr.transform(utf8.decoder).listen((data) {
      _errorOutput += data + "\n";
    }) as StreamSubscription<String>?;

    int exitCode = await process.exitCode;
    if (exitCode == 0) {
      _generatedCaption = _getLastParagraph(_generalOutput);
      _generalOutput += '!!!Success!!!';
      _finishCaptioning(true);
    } else {
      _generalOutput += '!!!Error!!!: ';
      _finishCaptioning(false);
    }

    await stdoutSubscription?.cancel();
    await stderrSubscription?.cancel();
  }

  String _getLastParagraph(String input) {
    // Split the input string by newline characters
    List<String> paragraphs = input.split('\n');

    // Remove any empty strings from the list
    paragraphs.removeWhere((paragraph) => paragraph.trim().isEmpty);

    // Return the last paragraph
    return paragraphs.isNotEmpty ? paragraphs.last : '';
  }
}
