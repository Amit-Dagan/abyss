import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:todo_list/core/style/app_colors.dart';
import 'package:todo_list/domain/entities/planner_member.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:todo_list/domain/entities/story_task.dart';
import 'package:todo_list/domain/repo/planning_repository.dart';
import 'package:todo_list/domain/repo/story_summary_document_repository.dart';
import 'package:todo_list/domain/services/editor_session_service.dart';
import 'package:todo_list/domain/services/planning_action_service.dart';
import 'package:todo_list/presentation/widgets/editor_session_widgets.dart';
import 'package:todo_list/presentation/widgets/workspace_navigation_widgets.dart';
import 'package:todo_list/service_locator.dart';

enum _StoryDetailState { loading, waitingAccess, ready, saving, failure }

class StoryDetailScreen extends StatefulWidget {
  final String? storyId;

  const StoryDetailScreen({super.key, required this.storyId});

  bool get isCreating => storyId == null;

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final PlanningRepository _planningRepository = sl<PlanningRepository>();
  final StorySummaryDocumentRepository _summaryDocumentRepository =
      sl<StorySummaryDocumentRepository>();
  final PlanningActionService _actionService = sl<PlanningActionService>();
  final EditorSessionService _session = sl<EditorSessionService>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _newTaskController = TextEditingController();
  final FocusNode _summaryFocusNode = FocusNode();
  final ScrollController _summaryScrollController = ScrollController();

  _StoryDetailState _state = _StoryDetailState.loading;
  String? _errorMessage;
  String? _saveWarningMessage;
  StoryStatus _status = StoryStatus.backlog;
  StoryPriority _priority = StoryPriority.medium;
  String? _ownerUserId;
  bool _isEditingSummary = true;
  List<PlannerMemberEntity> _members = const <PlannerMemberEntity>[];
  List<StoryTaskEntity> _tasks = const <StoryTaskEntity>[];
  StoryEntity? _loadedStory;
  late QuillController _summaryController;

  @override
  void initState() {
    super.initState();
    _summaryController = _buildSummaryController(
      StorySummaryDocument.fromPlainText(''),
    );
    _session.addListener(_handleSessionChange);
    _loadStory();
  }

  @override
  void dispose() {
    _session.removeListener(_handleSessionChange);
    _titleController.dispose();
    _newTaskController.dispose();
    _summaryController.dispose();
    _summaryFocusNode.dispose();
    _summaryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isCreating ? 'CREATE STORY' : 'STORY',
          style: const TextStyle(
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
            children: [Expanded(child: _buildBody(context))],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case _StoryDetailState.loading:
      case _StoryDetailState.saving:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      case _StoryDetailState.waitingAccess:
        return _buildMessageCard(
          title: 'Stories are locked',
          message: 'Sign in with a team-enabled account to edit story details.',
        );
      case _StoryDetailState.failure:
        return _buildMessageCard(
          title: 'Could not load story',
          message: _errorMessage ?? 'Unknown error.',
        );
      case _StoryDetailState.ready:
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isDesktop = constraints.maxWidth >= 1100;
            final bool isTablet = constraints.maxWidth >= 760;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 320,
                    child: _buildDetailsRail(
                      compact: false,
                      fillAvailableHeight: true,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildPrimaryColumn(context, isTablet: true),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPrimaryColumn(context, isTablet: isTablet),
                  const SizedBox(height: 16),
                  _buildDetailsRail(compact: !isTablet),
                ],
              ),
            );
          },
        );
    }
  }

  Widget _buildPrimaryColumn(BuildContext context, {required bool isTablet}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopHeader(context, isTablet: isTablet),
        if (_saveWarningMessage != null) ...[
          const SizedBox(height: 12),
          _buildInlineWarning(_saveWarningMessage!),
        ],
        const SizedBox(height: 18),
        _buildSummarySection(),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context, {required bool isTablet}) {
    return _buildSectionCard(
      title: null,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed:
                    _session.canManageStories ||
                        !_session.supportsAuthentication
                    ? _saveStory
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save_rounded),
                label: Text(widget.isCreating ? 'Create Story' : 'Save Story'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  textAlign: _titleTextAlign(context),
                  textDirection: _titleTextDirection(context),
                  style: const TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Story title',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                SizedBox(
                  width: isTablet ? 210 : double.infinity,
                  child: _buildPriorityDropdown(),
                ),
                SizedBox(
                  width: isTablet ? 210 : double.infinity,
                  child: _buildStatusDropdown(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final bool hasSummary = _currentSummaryPlainText().isNotEmpty;
    _summaryController.readOnly = !_isEditingSummary;

    return _buildSectionCard(
      title: 'Description',
      action: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Tooltip(
            message: 'Import .docx',
            child: IconButton(
              onPressed: _importSummaryDocx,
              icon: const Icon(Icons.upload_file_rounded),
            ),
          ),
          Tooltip(
            message: 'Download .docx',
            child: IconButton(
              onPressed: _downloadSummaryDocx,
              icon: const Icon(Icons.download_rounded),
            ),
          ),
          Tooltip(
            message: 'Full screen editor',
            child: IconButton(
              onPressed: _openFullScreenSummaryEditor,
              icon: const Icon(Icons.open_in_full_rounded),
            ),
          ),
          if (!_isEditingSummary)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isEditingSummary = true;
                });
                _summaryFocusNode.requestFocus();
              },
              icon: const Icon(Icons.edit_rounded),
              label: Text(hasSummary ? 'Edit description' : 'Add description'),
            )
          else
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isEditingSummary = false;
                });
              },
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Preview'),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditingSummary) ...[
            _buildSummaryToolbar(_summaryController, _summaryFocusNode),
            const SizedBox(height: 12),
          ],
          Container(
            constraints: BoxConstraints(
              minHeight: _isEditingSummary ? 380 : 320,
              maxHeight: _isEditingSummary ? 620 : 560,
            ),
            decoration: BoxDecoration(
              color: _isEditingSummary
                  ? AppColors.whiteColor
                  : AppColors.surfaceColor,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(18),
            ),
            child: hasSummary || _isEditingSummary
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: QuillEditor(
                      controller: _summaryController,
                      focusNode: _summaryFocusNode,
                      scrollController: _summaryScrollController,
                      config: QuillEditorConfig(
                        placeholder: 'Write the story description here...',
                        padding: const EdgeInsets.all(18),
                      ),
                    ),
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        _isEditingSummary = true;
                      });
                      _summaryFocusNode.requestFocus();
                    },
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Add a richer story description with formatting, lists, links, and headings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMutedColor,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryToolbar(QuillController controller, FocusNode focusNode) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: QuillSimpleToolbar(
        controller: controller,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: true,
          color: AppColors.surfaceColor,
          toolbarSectionSpacing: 10,
          toolbarRunSpacing: 10,
          iconTheme: const QuillIconTheme(
            iconButtonUnselectedData: IconButtonData(
              color: AppColors.primaryColor,
            ),
            iconButtonSelectedData: IconButtonData(color: AppColors.whiteColor),
          ),
          showFontFamily: false,
          showFontSize: false,
          showSmallButton: false,
          showInlineCode: true,
          showBackgroundColorButton: false,
          showColorButton: false,
          showListCheck: false,
          showIndent: false,
          showDirection: false,
          showAlignmentButtons: false,
          showSubscript: false,
          showSuperscript: false,
          showStrikeThrough: false,
          showClearFormat: false,
          showClipboardCopy: false,
          showClipboardCut: false,
          showClipboardPaste: true,
          showDividers: false,
          showSearchButton: false,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              afterButtonPressed: () {
                focusNode.requestFocus();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksCard({bool fillAvailableHeight = false}) {
    return _buildSectionCard(
      title: 'Tasks',
      action: Text(
        '${_tasks.length} total',
        style: const TextStyle(
          color: AppColors.textMutedColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, fillAvailableHeight ? 0 : 18),
      expandChild: fillAvailableHeight,
      child: Column(
        mainAxisSize: fillAvailableHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTaskController,
                    decoration: _inputDecoration('Add a new task'),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: widget.isCreating ? null : _addTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_tasks.isEmpty && fillAvailableHeight)
            const Expanded(child: _EmptyTasksMessage())
          else if (_tasks.isEmpty)
            const _EmptyTasksMessage()
          else if (fillAvailableHeight)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _tasks
                    .map((StoryTaskEntity task) => _buildTaskRow(task))
                    .toList(growable: false),
              ),
            )
          else
            Column(
              children: _tasks
                  .map((StoryTaskEntity task) => _buildTaskRow(task))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  TextAlign _titleTextAlign(BuildContext context) {
    return _titleTextDirection(context) == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
  }

  TextDirection _titleTextDirection(BuildContext context) {
    final Locale? locale = Localizations.maybeLocaleOf(context);
    final String? languageCode = locale?.languageCode.toLowerCase();
    const Set<String> rtlLanguageCodes = <String>{'ar', 'fa', 'he', 'iw', 'ur'};
    if (languageCode != null && rtlLanguageCodes.contains(languageCode)) {
      return TextDirection.rtl;
    }
    return Directionality.of(context);
  }

  Widget _buildDetailsRail({
    required bool compact,
    bool fillAvailableHeight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          title: 'Details',
          padding: EdgeInsets.all(compact ? 18 : 20),
          child: Column(
            children: [
              _buildMetaField(label: 'Assignee', child: _buildOwnerDropdown()),
              _buildMetaField(
                label: 'Created',
                child: Text(
                  _loadedStory?.createdAt == null
                      ? 'Created after first save'
                      : _formatDateTime(_loadedStory!.createdAt!),
                  style: const TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildMetaField(
                label: 'Updated',
                child: Text(
                  _loadedStory?.updatedAt == null
                      ? 'Not saved yet'
                      : _formatDateTime(_loadedStory!.updatedAt!),
                  style: const TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildMetaField(
                label: 'Progress snapshot',
                child: Text(
                  '${_tasks.where((task) => task.status == StoryTaskStatus.done).length} of ${_tasks.length} tasks done',
                  style: const TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (fillAvailableHeight)
          Expanded(child: _buildTasksCard(fillAvailableHeight: true))
        else
          _buildTasksCard(),
      ],
    );
  }

  Widget _buildTaskRow(StoryTaskEntity task) {
    final PlannerMemberEntity? owner = _findOwner(task.ownerUserId);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            '/stories/${task.storyId}/tasks/${task.id}',
          );
          await _loadStory();
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 720;
            return Padding(
              padding: const EdgeInsets.all(14),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildTaskStatusPill(task.status),
                            const SizedBox(width: 10),
                            _buildPriorityPill(task.priority),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMutedColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTaskTitleBlock(task),
                        const SizedBox(height: 8),
                        Text(
                          '${owner?.compactLabel ?? 'Unassigned'} · ${task.updatedAt == null ? 'Not saved yet' : _formatDateTime(task.updatedAt!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildTaskStatusPill(task.status),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: _buildTaskTitleBlock(task)),
                        const SizedBox(width: 12),
                        _buildPriorityPill(task.priority),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: Text(
                            owner?.compactLabel ?? 'Unassigned',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: Text(
                            task.updatedAt == null
                                ? 'Not saved yet'
                                : _formatDateTime(task.updatedAt!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMutedColor,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskTitleBlock(StoryTaskEntity task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title.isEmpty ? 'Untitled task' : task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (task.summary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMutedColor,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildTaskStatusPill(StoryTaskStatus status) {
    final Color background = switch (status) {
      StoryTaskStatus.todo => AppColors.warningTintColor,
      StoryTaskStatus.inProgress => AppColors.infoTintColor,
      StoryTaskStatus.done => AppColors.successTintColor,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPriorityPill(StoryPriority priority) {
    final Color background = switch (priority) {
      StoryPriority.low => AppColors.successTintColor,
      StoryPriority.medium => AppColors.warningTintColor,
      StoryPriority.high => const Color(0xFFFFE5E7),
      StoryPriority.critical => const Color(0xFFFFD6DA),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority.label,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String? title,
    required Widget child,
    Widget? action,
    EdgeInsets padding = const EdgeInsets.all(22),
    bool expandChild = false,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.55),
        ),
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
          if (title != null || action != null) ...[
            Row(
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (action case final Widget actionWidget) actionWidget,
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (expandChild) Expanded(child: child) else child,
        ],
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

  Widget _buildInlineWarning(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningTintColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE29D33)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE29D33)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimaryColor,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<StoryStatus>(
      key: ValueKey<String>('story-status-${_status.firestoreValue}'),
      initialValue: _status,
      isExpanded: true,
      decoration: _inputDecoration('Status'),
      items: StoryStatus.values
          .map(
            (StoryStatus status) => DropdownMenuItem<StoryStatus>(
              value: status,
              child: Text(status.label),
            ),
          )
          .toList(growable: false),
      onChanged: (StoryStatus? value) {
        if (value == null) {
          return;
        }
        setState(() {
          _status = value;
        });
      },
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<StoryPriority>(
      key: ValueKey<String>('story-priority-${_priority.firestoreValue}'),
      initialValue: _priority,
      isExpanded: true,
      decoration: _inputDecoration('Priority'),
      items: StoryPriority.values
          .map(
            (StoryPriority priority) => DropdownMenuItem<StoryPriority>(
              value: priority,
              child: Text(priority.label),
            ),
          )
          .toList(growable: false),
      onChanged: (StoryPriority? value) {
        if (value == null) {
          return;
        }
        setState(() {
          _priority = value;
        });
      },
    );
  }

  Widget _buildOwnerDropdown() {
    return DropdownButtonFormField<String?>(
      key: ValueKey<String>('story-owner-${_ownerUserId ?? 'none'}'),
      initialValue: _ownerUserId,
      isExpanded: true,
      decoration: _inputDecoration('Owner'),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
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
        const Text('Unassigned', overflow: TextOverflow.ellipsis, maxLines: 1),
        ..._members.map(
          (PlannerMemberEntity member) => Text(
            member.compactLabel,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
      onChanged: (String? value) {
        setState(() {
          _ownerUserId = value;
        });
      },
    );
  }

  Future<void> _loadStory() async {
    if (_session.supportsAuthentication && !_session.canManageStories) {
      setState(() {
        _state = _StoryDetailState.waitingAccess;
      });
      return;
    }

    setState(() {
      _state = _StoryDetailState.loading;
      _errorMessage = null;
    });

    try {
      final List<PlannerMemberEntity> members = await _planningRepository
          .getAssignableMembers();
      StoryEntity? story;
      List<StoryTaskEntity> tasks = const <StoryTaskEntity>[];
      if (!widget.isCreating && widget.storyId != null) {
        story = await _planningRepository.getStory(widget.storyId!);
        if (story == null) {
          throw StateError('Story not found.');
        }
        story = story.copyWith(
          summaryDocument: await _summaryDocumentRepository.loadSummaryDocument(
            story,
          ),
        );
        tasks = await _planningRepository.getTasks(widget.storyId!);
      }

      if (!mounted) {
        return;
      }

      _members = members;
      _loadedStory = story;
      _syncFormState(story, tasks);
      setState(() {
        _saveWarningMessage = null;
        _state = _StoryDetailState.ready;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _StoryDetailState.failure;
        _errorMessage = error.toString();
      });
    }
  }

  void _syncFormState(StoryEntity? story, List<StoryTaskEntity> tasks) {
    _titleController.text = story?.title ?? '';
    _status = story?.status ?? StoryStatus.backlog;
    _priority = story?.priority ?? StoryPriority.medium;
    _ownerUserId = story?.ownerUserId ?? _session.currentUserId;
    _replaceSummaryController(
      story?.summaryDocument ?? StorySummaryDocument.fromPlainText(''),
    );
    _isEditingSummary = widget.isCreating || _currentSummaryPlainText().isEmpty;

    _tasks = tasks;
  }

  Future<void> _importSummaryDocx() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['docx'],
        withData: true,
      );
      final PlatformFile? file = result?.files.isEmpty ?? true
          ? null
          : result!.files.first;
      final Uint8List? bytes = file?.bytes;
      if (bytes == null) {
        _showMessage('Could not read the selected .docx file.');
        return;
      }

      final List<Map<String, dynamic>> importedDocument =
          await _summaryDocumentRepository.importDocx(bytes);
      final String preview = StorySummaryDocument.toPlainText(importedDocument);
      if (!mounted) {
        return;
      }
      final bool shouldReplace = await _confirmSummaryImport(preview);
      if (!shouldReplace || !mounted) {
        return;
      }
      setState(() {
        _replaceSummaryController(importedDocument);
        _isEditingSummary = true;
      });
      _summaryFocusNode.requestFocus();
      _showMessage('Imported ${file!.name}. Save the story to persist it.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not import .docx: $error');
    }
  }

  Future<void> _downloadSummaryDocx() async {
    try {
      final Uint8List bytes = await _summaryDocumentRepository.exportDocx(
        storyTitle: _titleController.text.trim(),
        document: _currentSummaryDocument(),
      );
      await FilePicker.platform.saveFile(
        dialogTitle: 'Download story description',
        fileName: _summaryDownloadFileName(),
        type: FileType.custom,
        allowedExtensions: const <String>['docx'],
        bytes: bytes,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Downloaded story description.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not download .docx: $error');
    }
  }

  Future<void> _openFullScreenSummaryEditor() async {
    final List<Map<String, dynamic>> startingDocument =
        _currentSummaryDocument();
    final List<Map<String, dynamic>>? updatedDocument =
        await showDialog<List<Map<String, dynamic>>>(
          context: context,
          builder: (BuildContext context) {
            final FocusNode dialogFocusNode = FocusNode();
            final ScrollController dialogScrollController = ScrollController();
            final QuillController dialogController = _buildSummaryController(
              startingDocument,
            );

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter _) {
                return Dialog.fullscreen(
                  backgroundColor: AppColors.backgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Full screen description editor',
                                style: TextStyle(
                                  color: AppColors.textPrimaryColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                dialogController.dispose();
                                dialogFocusNode.dispose();
                                dialogScrollController.dispose();
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () {
                                final List<Map<String, dynamic>> document =
                                    _documentFromController(dialogController);
                                dialogController.dispose();
                                dialogFocusNode.dispose();
                                dialogScrollController.dispose();
                                Navigator.pop(context, document);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Apply'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSummaryToolbar(dialogController, dialogFocusNode),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              border: Border.all(color: AppColors.borderColor),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: QuillEditor(
                                controller: dialogController,
                                focusNode: dialogFocusNode,
                                scrollController: dialogScrollController,
                                config: const QuillEditorConfig(
                                  placeholder:
                                      'Write the story description here...',
                                  padding: EdgeInsets.all(22),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

    if (updatedDocument == null || !mounted) {
      return;
    }
    setState(() {
      _replaceSummaryController(updatedDocument);
      _isEditingSummary = true;
    });
  }

  Future<bool> _confirmSummaryImport(String preview) async {
    final String visiblePreview = preview.trim().isEmpty
        ? 'This document has no readable text.'
        : preview.trim();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Replace description?'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Importing this .docx will replace the current description in the editor.\n\nPreview:\n$visiblePreview',
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _saveStory() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Title is required.');
      return;
    }

    setState(() {
      _state = _StoryDetailState.saving;
    });

    try {
      final StoryEntity draftStory = _buildDraftStory();
      late final StorySaveResult saveResult;
      if (widget.isCreating) {
        saveResult = await _actionService.createStory(draftStory);
      } else {
        saveResult = await _actionService.updateStory(draftStory);
      }

      if (!mounted) {
        return;
      }

      final String? uploadWarning = saveResult.summaryDocumentUploaded
          ? null
          : 'Story metadata saved, but the rich description did not upload to Firebase Storage. Keep this tab open and try Save again. Error: ${saveResult.summaryUploadError}';
      _showMessage(
        uploadWarning == null
            ? (widget.isCreating ? 'Story created.' : 'Story saved.')
            : 'Story saved, but rich description upload failed.',
      );
      setState(() {
        _isEditingSummary = false;
        _loadedStory = draftStory.copyWith(updatedAt: DateTime.now());
        _saveWarningMessage = uploadWarning;
        _state = _StoryDetailState.ready;
      });
      if (widget.isCreating && saveResult.summaryDocumentUploaded) {
        Navigator.pushReplacementNamed(context, '/stories/${draftStory.id}');
        return;
      }

      if (saveResult.summaryDocumentUploaded) {
        await _loadStory();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _StoryDetailState.ready;
        _errorMessage = error.toString();
        _saveWarningMessage = 'Could not save story: $error';
      });
      _showMessage('Could not save story: $error');
    }
  }

  StoryEntity _buildDraftStory() {
    final List<Map<String, dynamic>> summaryDocument =
        _currentSummaryDocument();
    final String summaryPlainText = StorySummaryDocument.toPlainText(
      summaryDocument,
    );

    return StoryEntity(
      id:
          widget.storyId ??
          _loadedStory?.id ??
          _actionService.createId('story'),
      title: _titleController.text.trim(),
      summary: summaryPlainText,
      summaryDocument: summaryDocument,
      summaryDocumentPath: _loadedStory?.summaryDocumentPath,
      summaryUpdatedAt: _loadedStory?.summaryUpdatedAt,
      summaryDocumentVersion: _loadedStory?.summaryDocumentVersion,
      status: _status,
      ownerUserId: _ownerUserId,
      priority: _priority,
      createdAt: _loadedStory?.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _addTask() async {
    final String value = _newTaskController.text.trim();
    if (value.isEmpty) {
      return;
    }
    if (widget.isCreating || _loadedStory == null) {
      _showMessage('Save the story before adding subtasks.');
      return;
    }

    final StoryTaskEntity task = StoryTaskEntity(
      id: _actionService.createId('task'),
      storyId: _loadedStory!.id,
      title: value,
      summary: '',
      summaryDocument: StorySummaryDocument.fromPlainText(''),
      summaryDocumentPath: null,
      summaryUpdatedAt: null,
      summaryDocumentVersion: null,
      status: StoryTaskStatus.todo,
      ownerUserId: _ownerUserId,
      priority: StoryPriority.medium,
      orderIndex: _tasks.length,
      createdAt: null,
      updatedAt: DateTime.now(),
    );
    await _actionService.createTask(task);
    _newTaskController.clear();
    await _loadStory();
  }

  void _handleSessionChange() {
    _loadStory();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryColor,
        duration: const Duration(seconds: 8),
        content: Text(message),
      ),
    );
  }

  void _replaceSummaryController(List<Map<String, dynamic>> document) {
    final QuillController previousController = _summaryController;
    _summaryController = _buildSummaryController(document);
    previousController.dispose();
  }

  QuillController _buildSummaryController(List<Map<String, dynamic>> document) {
    try {
      return QuillController(
        document: Document.fromJson(StorySummaryDocument.clone(document)),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );
    } on Object {
      return QuillController(
        document: Document.fromJson(
          StorySummaryDocument.fromPlainText(
            StorySummaryDocument.toPlainText(document),
          ),
        ),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );
    }
  }

  List<Map<String, dynamic>> _currentSummaryDocument() {
    return _documentFromController(_summaryController);
  }

  List<Map<String, dynamic>> _documentFromController(
    QuillController controller,
  ) {
    return controller.document
        .toDelta()
        .toJson()
        .map<Map<String, dynamic>>(
          (dynamic item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
        )
        .toList(growable: false);
  }

  String _currentSummaryPlainText() {
    return StorySummaryDocument.toPlainText(_currentSummaryDocument());
  }

  String _summaryDownloadFileName() {
    final String title = _titleController.text.trim().isEmpty
        ? 'story'
        : _titleController.text.trim();
    final String safeTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '${safeTitle.isEmpty ? 'story' : safeTitle}-summary.docx';
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.whiteColor,
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
      labelStyle: const TextStyle(color: AppColors.textMutedColor),
    );
  }

  String _formatDate(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _formatDateTime(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '${_formatDate(value)} $hour:$minute';
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

class _EmptyTasksMessage extends StatelessWidget {
  const _EmptyTasksMessage();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topLeft,
      child: Text(
        'No tasks yet. Add one here to break the story into smaller work items.',
        style: TextStyle(
          color: AppColors.textMutedColor,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
