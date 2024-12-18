import 'package:dscaption/model/fileitem.dart';
import 'package:flutter/material.dart';

class FileProvider with ChangeNotifier {
  List<FileItem> files = [];
  FileItem? currentFile;

  void loadFiles(String folderPath) {

  // if (await Directory(folderPath).exists()) {
  //     List<FileSystemEntity> files = Directory(folderPath).listSync();
  //     imageFiles = files.where((file) => file.path.endsWith('.png')).map((file) => File(file.path)).toList();
  //     textFiles = files.where((file) => file.path.endsWith('.txt')).map((file) => File(file.path)).toList();
  //     setState(() {});
  //   } else {
  //     setState(() {
  //       errorMessage = 'Invalid folder path';
  //     });
  //   }

  //   // Load files from the directory
  //   // For simplicity, let's assume we have a list of FileItem objects
  //   files = [
  //     FileItem(imageFilePath: '$path/file1.png', textFilePath: 'Description 1'),
  //     FileItem(imageFilePath: '$path/file2.png', textFilePath: 'Description 2'),
  //   ];
    notifyListeners();
  }

  void setCurrentFile(FileItem file) {
    currentFile = file;
    notifyListeners();
  }

  void updateDescription(String description) {
    if (currentFile != null) {
      currentFile!.textFilePath = description;
      notifyListeners();
    }
  }
}