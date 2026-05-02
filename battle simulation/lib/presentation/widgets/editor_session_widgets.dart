import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';
import 'package:todo_list/service_locator.dart';

class EditorSessionAction extends StatelessWidget {
  const EditorSessionAction({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorSessionService session = sl<EditorSessionService>();

    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? child) {
        if (!session.supportsAuthentication) {
          return const SizedBox.shrink();
        }
        if (!session.isInitialized || session.isBusy) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
          );
        }

        return PopupMenuButton<_SessionAction>(
          tooltip: session.currentUserEmail ?? 'Account',
          icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
          onSelected: (_SessionAction action) async {
            switch (action) {
              case _SessionAction.signIn:
                await session.signIn();
                break;
              case _SessionAction.signOut:
                await session.signOut();
                break;
            }

            final String? message = session.errorMessage;
            if (context.mounted && message != null && message.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primaryColor,
                  content: Text(message),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<_SessionAction>>[
                if (session.isSignedIn && session.currentUserEmail != null)
                  PopupMenuItem<_SessionAction>(
                    enabled: false,
                    child: Text(session.currentUserEmail!),
                  ),
                if (session.isAdmin)
                  const PopupMenuItem<_SessionAction>(
                    enabled: false,
                    child: Text('ADMIN'),
                  ),
                PopupMenuItem<_SessionAction>(
                  value: session.isSignedIn
                      ? _SessionAction.signOut
                      : _SessionAction.signIn,
                  child: Text(session.isSignedIn ? 'Sign out' : 'Sign in'),
                ),
              ],
        );
      },
    );
  }
}

enum _SessionAction { signIn, signOut }

class EditorAccessBanner extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const EditorAccessBanner({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final EditorSessionService session = sl<EditorSessionService>();

    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? child) {
        if (!session.supportsAuthentication) {
          return const SizedBox.shrink();
        }

        final bool canPromptSignIn = !session.isSignedIn && !session.isBusy;
        final String? errorMessage = session.errorMessage;
        return Container(
          width: double.infinity,
          margin: margin,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: session.canEditUnits
                ? const Color(0xFFE7F7EF)
                : const Color(0xFFFFF6E4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: session.canEditUnits
                  ? const Color(0xFF8BD2A9)
                  : const Color(0xFFF2C36B),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                session.canEditUnits ? Icons.verified_user : Icons.lock_outline,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.isAdmin) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E7752),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      session.statusMessage,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Color(0xFF9A3C00),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canPromptSignIn)
                TextButton(
                  onPressed: () async {
                    await session.signIn();
                    final String? message = session.errorMessage;
                    if (context.mounted &&
                        message != null &&
                        message.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primaryColor,
                          content: Text(message),
                        ),
                      );
                    }
                  },
                  child: const Text('Sign in'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PlannerAccessBanner extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const PlannerAccessBanner({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final EditorSessionService session = sl<EditorSessionService>();

    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? child) {
        if (!session.supportsAuthentication) {
          return const SizedBox.shrink();
        }

        final bool canPromptSignIn = !session.isSignedIn && !session.isBusy;
        final String? errorMessage = session.errorMessage;
        return Container(
          width: double.infinity,
          margin: margin,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: session.canManageStories
                ? const Color(0xFFE7F7EF)
                : const Color(0xFFFFF6E4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: session.canManageStories
                  ? const Color(0xFF8BD2A9)
                  : const Color(0xFFF2C36B),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                session.canManageStories
                    ? Icons.edit_note_rounded
                    : Icons.lock_outline,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.isPlanner) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E7752),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'TEAM ACCESS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      session.plannerStatusMessage,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Color(0xFF9A3C00),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canPromptSignIn)
                TextButton(
                  onPressed: () async {
                    await session.signIn();
                    final String? message = session.errorMessage;
                    if (context.mounted &&
                        message != null &&
                        message.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primaryColor,
                          content: Text(message),
                        ),
                      );
                    }
                  },
                  child: const Text('Sign in'),
                ),
            ],
          ),
        );
      },
    );
  }
}
