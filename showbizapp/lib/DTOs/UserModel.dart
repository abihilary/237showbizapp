import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel extends ChangeNotifier {
  String _username = '';
  String _subscriberId = '';

  String get username => _username;
  String get subscriberId => _subscriberId;

  get showAdmin => true;

  void setSubscriber(String name, String id) {
    _username = name;
    _subscriberId = id;
    notifyListeners();
  }

  // A new method to load the subscriber data from SharedPreferences
  Future<void> loadSubscriberData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('subscriberName');
    final id = prefs.getString('subscriberId');

    if (name != null && id != null) {
      setSubscriber(name, id);
    }
  }
}

