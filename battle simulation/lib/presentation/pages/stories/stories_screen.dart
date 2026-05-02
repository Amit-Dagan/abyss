import 'package:flutter/material.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/entities/planner_member.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_task.dart';
import 'package:todo_list/domain/repo/planning_repository.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';
import 'package:todo_list/presentation/widgets/editor_session_widgets.dart';
import 'package:todo_list/presentation/widgets/workspace_navigation_widgets.dart';
import 'package:todo_list/service_locator.dart';

enum _StoriesLoadState { loading, waitingAccess, ready, failure }

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final PlanningRepository _planningRepository = sl<PlanningRepository>();
  final EditorSessionService _session = sl<EditorSessionService>();
  final TextEditingController _searchController = TextEditingController();

  _StoriesLoadState _state = _StoriesLoadState.loading;
  List<StoryEntity> _stories = const <StoryEntity>[];
  List<PlannerMemberEntity> _members = const <PlannerMemberEntity>[];
  Map<String, int> _taskCounts = const <String, int>{};
  StoryStatus? _statusFilter;
  StoryPriority? _priorityFilter;
  String? _ownerFilter;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _session.addListener(_handleSessionChange);
    _loadStories();
  }

  @override
  void dispose() {
    _session.removeListener(_handleSessionChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<StoryEntity> filteredStories = _stories
        .where((StoryEntity story) {
          final bool statusMatches =
              _statusFilter == null || story.status == _statusFilter;
          final bool priorityMatches =
              _priorityFilter == null || story.priority == _priorityFilter;
          final bool ownerMatches =
              _ownerFilter == null || story.ownerUserId == _ownerFilter;
          final String haystack = '${story.title}\n${story.summary}'
              .toLowerCase();
          final bool searchMatches =
              _searchQuery.isEmpty || haystack.contains(_searchQuery);
          return statusMatches &&
              priorityMatches &&
              ownerMatches &&
              searchMatches;
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'STORIES',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: [
          const WorkspaceNavigationAction(
            currentDestination: WorkspaceDestination.stories,
          ),
          const EditorSessionAction(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: _buildBody(context, filteredStories))],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<StoryEntity> filteredStories) {
    switch (_state) {
      case _StoriesLoadState.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      case _StoriesLoadState.waitingAccess:
        return _buildMessageCard(
          title: 'Stories are locked',
          message:
              'Sign in with a team-approved account to open the Stories workspace.',
        );
      case _StoriesLoadState.failure:
        return _buildMessageCard(
          title: 'Could not load stories',
          message: _errorMessage ?? 'Unknown error.',
        );
      case _StoriesLoadState.ready:
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isDesktop = constraints.maxWidth >= 980;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, isDesktop: isDesktop),
                const SizedBox(height: 16),
                _buildFiltersBar(isDesktop: isDesktop),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredStories.isEmpty
                      ? _buildMessageCard(
                          title: 'No stories match the current view',
                          message:
                              'Adjust the search or filters, or create a new story to get started.',
                        )
                      : isDesktop
                      ? _buildDesktopList(context, filteredStories)
                      : _buildCompactList(context, filteredStories),
                ),
              ],
            );
          },
        );
    }
  }

  Widget _buildHeader(BuildContext context, {required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E41479B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stories workspace',
                      style: TextStyle(
                        color: AppColors.textPrimaryColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track feature stories, subtasks, ownership, and priority in a desktop-first planning surface.',
                      style: const TextStyle(
                        color: AppColors.textMutedColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 20),
                _buildCreateStoryButton(context),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (String value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search stories by title or summary',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 12),
                _buildCreateStoryButton(context),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateStoryButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _session.canManageStories || !_session.supportsAuthentication
          ? () async {
              await Navigator.pushNamed(context, '/stories/new');
              await _loadStories();
            }
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Story'),
    );
  }

  Widget _buildFiltersBar({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.45),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: isDesktop ? 180 : 220, child: _buildStatusDropdown()),
          SizedBox(
            width: isDesktop ? 180 : 220,
            child: _buildPriorityDropdown(),
          ),
          SizedBox(width: isDesktop ? 220 : 260, child: _buildOwnerDropdown()),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _statusFilter = null;
                _priorityFilter = null;
                _ownerFilter = null;
                _searchQuery = '';
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopList(
    BuildContext context,
    List<StoryEntity> filteredStories,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F1238),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('Story', style: _DesktopHeaderTextStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Status', style: _DesktopHeaderTextStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Priority', style: _DesktopHeaderTextStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Owner', style: _DesktopHeaderTextStyle()),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Tasks', style: _DesktopHeaderTextStyle()),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderColor),
          Expanded(
            child: ListView.separated(
              itemCount: filteredStories.length,
              separatorBuilder: (_, separatorIndex) =>
                  const Divider(height: 1, color: AppColors.surfaceMutedColor),
              itemBuilder: (BuildContext context, int index) {
                final StoryEntity story = filteredStories[index];
                final PlannerMemberEntity? owner = _findOwner(
                  story.ownerUserId,
                );
                return InkWell(
                  onTap: () async {
                    await Navigator.pushNamed(context, '/stories/${story.id}');
                    await _loadStories();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: _buildDesktopStoryCell(story)),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildStatusBadge(story.status),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildPriorityBadge(story.priority),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            owner?.label ?? 'Unassigned',
                            style: const TextStyle(
                              color: AppColors.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${_taskCounts[story.id] ?? 0}',
                            style: const TextStyle(
                              color: AppColors.textPrimaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactList(
    BuildContext context,
    List<StoryEntity> filteredStories,
  ) {
    return ListView.builder(
      itemCount: filteredStories.length,
      itemBuilder: (BuildContext context, int index) {
        final StoryEntity story = filteredStories[index];
        final PlannerMemberEntity? owner = _findOwner(story.ownerUserId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await Navigator.pushNamed(context, '/stories/${story.id}');
              await _loadStories();
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.borderColor.withValues(alpha: 0.55),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F1238),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusBadge(story.status),
                      _buildPriorityBadge(story.priority),
                      if (owner != null) _buildOwnerBadge(owner.label),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    story.title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story.summary.isEmpty
                        ? 'No description yet.'
                        : story.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMutedColor,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Tasks ${_taskCounts[story.id] ?? 0}',
                        style: const TextStyle(
                          color: AppColors.textPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMutedColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopStoryCell(StoryEntity story) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          story.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          story.summary.isEmpty ? 'No description yet.' : story.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMutedColor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<StoryStatus?>(
      initialValue: _statusFilter,
      isExpanded: true,
      decoration: _filterDecoration('All statuses'),
      onChanged: (StoryStatus? value) {
        setState(() {
          _statusFilter = value;
        });
      },
      items: <DropdownMenuItem<StoryStatus?>>[
        const DropdownMenuItem<StoryStatus?>(
          value: null,
          child: Text('All statuses'),
        ),
        ...StoryStatus.values.map(
          (StoryStatus status) => DropdownMenuItem<StoryStatus?>(
            value: status,
            child: Text(status.label),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<StoryPriority?>(
      initialValue: _priorityFilter,
      isExpanded: true,
      decoration: _filterDecoration('All priorities'),
      onChanged: (StoryPriority? value) {
        setState(() {
          _priorityFilter = value;
        });
      },
      items: <DropdownMenuItem<StoryPriority?>>[
        const DropdownMenuItem<StoryPriority?>(
          value: null,
          child: Text('All priorities'),
        ),
        ...StoryPriority.values.map(
          (StoryPriority priority) => DropdownMenuItem<StoryPriority?>(
            value: priority,
            child: Text(priority.label),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerDropdown() {
    return DropdownButtonFormField<String?>(
      initialValue: _ownerFilter,
      isExpanded: true,
      decoration: _filterDecoration('All owners'),
      onChanged: (String? value) {
        setState(() {
          _ownerFilter = value;
        });
      },
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(value: null, child: Text('All owners')),
        ..._members.map(
          (PlannerMemberEntity member) => DropdownMenuItem<String?>(
            value: member.uid,
            child: Text(
              member.compactLabel,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
      selectedItemBuilder: (BuildContext context) => <Widget>[
        const Text('All owners', overflow: TextOverflow.ellipsis, maxLines: 1),
        ..._members.map(
          (PlannerMemberEntity member) => Text(
            member.compactLabel,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.4),
      ),
    );
  }

  Widget _buildMessageCard({required String title, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_late_outlined,
            color: AppColors.primaryColor,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StoryStatus status) {
    final Color background = switch (status) {
      StoryStatus.backlog => AppColors.warningTintColor,
      StoryStatus.inProgress => AppColors.infoTintColor,
      StoryStatus.review => const Color(0xFFE9E3FF),
      StoryStatus.done => AppColors.successTintColor,
    };
    return _buildBadge(status.label, background);
  }

  Widget _buildPriorityBadge(StoryPriority priority) {
    final Color background = switch (priority) {
      StoryPriority.low => AppColors.successTintColor,
      StoryPriority.medium => AppColors.warningTintColor,
      StoryPriority.high => const Color(0xFFFFE5E7),
      StoryPriority.critical => const Color(0xFFFFD6DA),
    };
    return _buildBadge(priority.label, background);
  }

  Widget _buildOwnerBadge(String label) {
    return _buildBadge(label, AppColors.surfaceMutedColor);
  }

  Widget _buildBadge(String text, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _loadStories() async {
    if (_session.supportsAuthentication && !_session.canManageStories) {
      setState(() {
        _state = _StoriesLoadState.waitingAccess;
      });
      return;
    }

    setState(() {
      _state = _StoriesLoadState.loading;
      _errorMessage = null;
    });

    try {
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
            _planningRepository.getStories(),
            _planningRepository.getAssignableMembers(),
          ]);
      final List<StoryEntity> stories = results[0] as List<StoryEntity>;
      final List<PlannerMemberEntity> members =
          results[1] as List<PlannerMemberEntity>;
      final List<List<StoryTaskEntity>> taskSets = await Future.wait(
        stories.map(
          (StoryEntity story) => _planningRepository.getTasks(story.id),
        ),
      );
      final Map<String, int> taskCounts = <String, int>{};
      for (int index = 0; index < stories.length; index++) {
        taskCounts[stories[index].id] = taskSets[index].length;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _stories = stories;
        _members = members;
        _taskCounts = taskCounts;
        _state = _StoriesLoadState.ready;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _StoriesLoadState.failure;
        _errorMessage = error.toString();
      });
    }
  }

  void _handleSessionChange() {
    _loadStories();
  }

  PlannerMemberEntity? _findOwner(String? ownerUserId) {
    if (ownerUserId == null) {
      return null;
    }
    for (final PlannerMemberEntity member in _members) {
      if (member.uid == ownerUserId) {
        return member;
      }
    }
    return null;
  }
}

class _DesktopHeaderTextStyle extends TextStyle {
  const _DesktopHeaderTextStyle()
    : super(
        color: AppColors.textMutedColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      );
}
