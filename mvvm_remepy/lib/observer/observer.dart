import 'dart:ui';

class EventInfo<T> {
  final String name;
  T? extraInfo;

  EventInfo({required this.name, this.extraInfo});
}

class NavigateModel {
  final String routeName;
  dynamic arguments;
  bool? replace;

  NavigateModel({required this.routeName, this.arguments, this.replace});
}

class AlertAction {
  final String title;

  VoidCallback? onTap;

  AlertAction({
    required this.title,
    this.onTap,
  });
}

enum AlertModelType {
  basic,
  notification,
  actionBar;
}

class AlertModel {
  final AlertModelType type;
  String? title;
  String? body;
  List<AlertAction>? actions;

  AlertModel({
    this.type = AlertModelType.basic,
    this.title,
    this.actions,
    this.body,
  });
}

class ObservedData<T> {
  String? event;
  T? data;

  ObservedData({
    required this.event,
    this.data,
  });
}

mixin Observer<T> {
  final Set<String> _events = {};

  List<String> get events => _events.toList();

  void subscribeAll(List<String> events) {
    _events.addAll(events);
  }

  void unsubscribeAll(List<String> events) {
    _events.removeAll(events);
  }

  void subscribe({required String event}) {
    _events.add(event);
  }

  void unsubscribe({required String event}) {
    _events.remove(event);
  }

  void clear() {
    _events.clear();
  }

  void onNotify(ObservedData<T> data) {}
}
