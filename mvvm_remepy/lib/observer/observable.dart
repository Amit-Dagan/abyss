import 'observer.dart';

mixin Observable<T extends ObservedData> {
  final Set<Observer> _observers = {};

  void addObserver(Observer observer) {
    _observers.add(observer);
  }

  void removeObserver(Observer observer) {
    observer.clear();
    _observers.remove(observer);
  }

  void notifyObservers(T data) {
    for (Observer observer in _observers) {
      if (observer.events.contains(data.event)) {
        observer.onNotify(data);
      }
    }
  }
}
