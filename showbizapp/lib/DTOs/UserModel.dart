import 'package:flutter/cupertino.dart';


class UserModel extends ChangeNotifier {
  String _username = '';
  String _subscriberId = '';

  String get username => _username;
  String get subscriberId => _subscriberId;

  void setUsername(String newUsername) {
    _username = newUsername;
    notifyListeners();
  }

  void setSubscriberId(String newSubscriberId) {
    _subscriberId = newSubscriberId;
    notifyListeners();
  }
}

