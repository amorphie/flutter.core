import 'dart:convert';

class _Constant {
  static const keyState = "state";
  static const keyMessage = "message";
}

class SignalrEkycData {
  final String state;
  final String message;

  SignalrEkycData({required this.state, required this.message});

  String encode() {
    return jsonEncode({
      _Constant.keyState: state,
      _Constant.keyMessage: message,
    });
  }

  factory SignalrEkycData.decode(String jsonString) {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return SignalrEkycData(
      state: jsonMap[_Constant.keyState],
      message: jsonMap[_Constant.keyMessage],
    );
  }
}
