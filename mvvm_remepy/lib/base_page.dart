import 'package:flutter/material.dart';
import 'package:mvvm_remepy/provider/consumer.dart';
import 'package:mvvm_remepy/view_model.dart';

import 'observer/observer.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

abstract class BasePage<M extends Model, VM extends ViewModel<M>>
    extends StatefulWidget {
  final VM viewModel;

  const BasePage({required this.viewModel, super.key});

  @override
  BasePageState<M, VM, BasePage<M, VM>> createState();
}

abstract class BasePageState<M extends Model, VM extends ViewModel<M>,
        T extends BasePage<M, VM>> extends State<T>
    with RouteAware
    implements Consumer<M> {
  M get model => viewModel.model;
  late VM viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.viewModel;
    viewModel.addConsumer(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.onViewLoaded(ModalRoute.settingsOf(context)?.arguments);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    viewModel.onViewResumed();
  }

  @override
  void didPushNext() {
    super.didPushNext();
    viewModel.onViewPaused();
  }

  @override
  void dispose() {
    widget.viewModel.removeConsumer(this);
    routeObserver.unsubscribe(this);
    widget.viewModel.dispose();
    super.dispose();
  }

  Widget get body => const Placeholder();

  Widget? get loader => null;

  Widget? get drawer => null;

  Widget? get bottomNavigationBar => null;

  Widget? get floatingActionButton => null;

  TextDirection get direction => Directionality.of(context);

  Color get backgroundColor;

  bool get extendBody => false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: model.willPop,
      child: Directionality(
        textDirection: direction,
        child: Theme(
          data: themeData,
          child: Scaffold(
            backgroundColor: backgroundColor,
            drawer: drawer,
            appBar: appBar,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButtonAnimator:
                FloatingActionButtonAnimator.noAnimation,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: floatingActionButton,
            body: body,
            extendBody: extendBody,
          ),
        ),
      ),
    );
  }

  ThemeData get themeData => Theme.of(context);

  PreferredSizeWidget? get appBar {
    return AppBar(
      title: Text(model.appBarTitle),
      backgroundColor: Colors.blue[100],
    );
  }

  @override
  void onNotify([M? data]) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void onAlert(AlertModel alertModel) {}

  @override
  void onNavigate(NavigateModel navigateModel) {
    if (navigateModel.routeName.isEmpty) {
      Navigator.pop(context);
      return;
    }
    if (navigateModel.replace == true) {
      Navigator.pushReplacementNamed(context, navigateModel.routeName,
          arguments: navigateModel.arguments);
    } else {
      Navigator.pushNamed(context, navigateModel.routeName,
          arguments: navigateModel.arguments);
    }
  }

  @override
  void onEvent(EventInfo info) {}
}
