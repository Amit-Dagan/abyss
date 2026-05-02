import 'package:flutter/material.dart';

enum WorkspaceDestination { home, simulators, stories }

class WorkspaceNavigationAction extends StatelessWidget {
  final WorkspaceDestination currentDestination;

  const WorkspaceNavigationAction({
    super.key,
    required this.currentDestination,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<WorkspaceDestination>(
      tooltip: 'Navigate',
      icon: const Icon(Icons.space_dashboard_outlined, color: Colors.white),
      onSelected: (WorkspaceDestination destination) {
        switch (destination) {
          case WorkspaceDestination.home:
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            break;
          case WorkspaceDestination.simulators:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/simulators',
              (route) => false,
            );
            break;
          case WorkspaceDestination.stories:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/stories',
              (route) => false,
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => WorkspaceDestination.values
          .where((WorkspaceDestination destination) => destination != currentDestination)
          .map((WorkspaceDestination destination) {
            return PopupMenuItem<WorkspaceDestination>(
              value: destination,
              child: Text(_labelFor(destination)),
            );
          })
          .toList(growable: false),
    );
  }

  String _labelFor(WorkspaceDestination destination) => switch (destination) {
    WorkspaceDestination.home => 'Home',
    WorkspaceDestination.simulators => 'Simulators',
    WorkspaceDestination.stories => 'Stories',
  };
}
