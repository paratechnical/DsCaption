class OperationResult {
  bool _result;

  bool get result => _result;

  set result(bool value) {
    _result = value;
  }
  String _generalOutput;

  String get generalOutput => _generalOutput;

  set generalOutput(String value) {
    _generalOutput = value;
  }
  String _errorOutput;

  String get errorOutput => _errorOutput;

  set errorOutput(String value) {
    _errorOutput = value;
  }

  void clear()
  {
    _result = false;
    _generalOutput = "";
    _errorOutput = "";
  }

  OperationResult({required bool result, required String generalOutput, required String errorOutput}) : _errorOutput = errorOutput, _generalOutput = generalOutput, _result = result;
}