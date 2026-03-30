import 'package:mvvm_remepy/observer/observer.dart';
import 'package:mvvm_remepy/provider/provider.dart';

class Model<T> {
  T? arguments;
  bool isLoading = false;
  String appBarTitle = '';
  bool willPop = true;
  String nextText = '';

  Model({this.arguments});
}

class ViewModel<T extends Model> with Provider, Observer {
  final T model;

  ViewModel({required this.model});

  void onViewLoaded(dynamic data) {}

  void onViewResumed() {}

  void onViewPaused() {}

  void dispose() {}
}
