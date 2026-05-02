import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/presentation/widgets/editor_session_widgets.dart';

class WorkspaceHomeScreen extends StatelessWidget {
  const WorkspaceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIntroCard(),
              const SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool wide = constraints.maxWidth >= 860;
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _WorkspaceSegmentCard(
                              title: 'Simulators',
                              subtitle:
                                  'Battle demos, combat rules, unit sandboxing, and future game-system prototypes all live here.',
                              actionLabel: 'Open Simulators',
                              icon: Icons.sports_martial_arts_rounded,
                              accentColor: const Color(0xFF4A7BFF),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/simulators'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _WorkspaceSegmentCard(
                              title: 'Stories',
                              subtitle:
                                  'Internal planning for you and your partner: stories, tasks, owners, and priorities.',
                              actionLabel: 'Open Stories',
                              icon: Icons.assignment_rounded,
                              accentColor: const Color(0xFF1E7752),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/stories'),
                            ),
                          ),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _WorkspaceSegmentCard(
                            title: 'Simulators',
                            subtitle:
                                'Battle demos, combat rules, unit sandboxing, and future game-system prototypes all live here.',
                            actionLabel: 'Open Simulators',
                            icon: Icons.sports_martial_arts_rounded,
                            accentColor: const Color(0xFF4A7BFF),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/simulators'),
                          ),
                          const SizedBox(height: 16),
                          _WorkspaceSegmentCard(
                            title: 'Stories',
                            subtitle:
                                'Internal planning for you and your partner: stories, tasks, owners, and priorities.',
                            actionLabel: 'Open Stories',
                            icon: Icons.assignment_rounded,
                            accentColor: const Color(0xFF1E7752),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/stories'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ABYSS STUDIO',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: const <Widget>[EditorSessionAction()],
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.boxShadowColor,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One workspace, two loops',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use Simulators to explore the game itself, then capture learnings in Stories so you and your partner can turn them into real delivery work.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSegmentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onPressed;

  const _WorkspaceSegmentCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.boxShadowColor,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accentColor, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
