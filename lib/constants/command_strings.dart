import 'dart:io';

class CommandStrings {
  static String pythonCommand = Platform.isMacOS ? 'python3' : 'python';
  static String pipCommand = Platform.isMacOS ? 'pip3' : 'pip';
  static String venvName = 'currentvenv';
  static String activateVenvCommand = Platform.isMacOS
      ? 'source $venvName/bin/activate'
      : '$venvName\\Scripts\\activate';
  static String pipCommandInsideVenv = Platform.isMacOS
      ? '$venvName/bin/$pipCommand'
      : '$venvName\\Scripts\\$pipCommand';
  static String pythonCommandInsideVenv = Platform.isMacOS
      ? '$venvName/bin/$pythonCommand'
      : '$venvName\\Scripts\\$pythonCommand';
}