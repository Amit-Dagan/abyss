import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:todo_list/data/repo/planning_repo_impl/story_summary_document_converter.dart';
import 'package:todo_list/domain/entities/story.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:todo_list/domain/entities/story_task.dart';
import 'package:todo_list/domain/repo/story_summary_document_repository.dart';

class FirebaseStorySummaryDocumentRepository
    implements StorySummaryDocumentRepository {
  final FirebaseStorage _storage;
  final StorySummaryDocumentConverter _converter;

  FirebaseStorySummaryDocumentRepository({
    FirebaseStorage? storage,
    StorySummaryDocumentConverter? converter,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _converter = converter ?? const StorySummaryDocumentConverter();

  @override
  Future<List<Map<String, dynamic>>> loadSummaryDocument(
    StoryEntity story,
  ) async {
    return _loadDocument(
      path: story.summaryDocumentPath,
      embeddedDocument: story.summaryDocument,
      fallbackPlainText: story.summary,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> loadTaskSummaryDocument(
    StoryTaskEntity task,
  ) async {
    return _loadDocument(
      path: task.summaryDocumentPath,
      embeddedDocument: task.summaryDocument,
      fallbackPlainText: task.summary,
    );
  }

  Future<List<Map<String, dynamic>>> _loadDocument({
    required String? path,
    required List<Map<String, dynamic>> embeddedDocument,
    required String fallbackPlainText,
  }) async {
    if (path != null && path.isNotEmpty) {
      try {
        final Uint8List? bytes = await _storage
            .ref(path)
            .getData(1048576)
            .timeout(const Duration(seconds: 8));
        if (bytes != null) {
          return _decodeDocument(bytes, fallbackPlainText: fallbackPlainText);
        }
      } on FormatException {
        return StorySummaryDocument.fromPlainText(fallbackPlainText);
      } on Object {
        // Keep old stories readable while storage documents are being migrated
        // or when Storage is temporarily unavailable.
      }
    }

    if (embeddedDocument.isNotEmpty) {
      return StorySummaryDocument.clone(embeddedDocument);
    }
    return StorySummaryDocument.fromPlainText(fallbackPlainText);
  }

  @override
  Future<StorySummarySaveResult> saveSummaryDocument({
    required String storyId,
    required List<Map<String, dynamic>> document,
  }) async {
    return _saveDocument(
      path: StorySummaryDocumentRepository.pathForStoryId(storyId),
      document: document,
    );
  }

  @override
  Future<StorySummarySaveResult> saveTaskSummaryDocument({
    required String storyId,
    required String taskId,
    required List<Map<String, dynamic>> document,
  }) async {
    return _saveDocument(
      path: StorySummaryDocumentRepository.pathForTaskId(storyId, taskId),
      document: document,
    );
  }

  Future<StorySummarySaveResult> _saveDocument({
    required String path,
    required List<Map<String, dynamic>> document,
  }) async {
    final DateTime updatedAt = DateTime.now();
    final String payload = jsonEncode(StorySummaryDocument.clone(document));
    await _storage
        .ref(path)
        .putData(
          Uint8List.fromList(utf8.encode(payload)),
          SettableMetadata(
            contentType: 'application/json',
            customMetadata: <String, String>{
              'documentVersion': StorySummaryDocumentRepository.currentVersion
                  .toString(),
              'updatedAt': updatedAt.toIso8601String(),
            },
          ),
        )
        .timeout(const Duration(seconds: 15));
    return StorySummarySaveResult(
      path: path,
      updatedAt: updatedAt,
      version: StorySummaryDocumentRepository.currentVersion,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> importDocx(Uint8List bytes) {
    return _converter.importDocx(bytes);
  }

  @override
  Future<Uint8List> exportDocx({
    required String storyTitle,
    required List<Map<String, dynamic>> document,
  }) {
    return _converter.exportDocx(storyTitle: storyTitle, document: document);
  }

  List<Map<String, dynamic>> _decodeDocument(
    Uint8List bytes, {
    required String fallbackPlainText,
  }) {
    final Object? decoded = jsonDecode(utf8.decode(bytes));
    final Object? rawDocument = decoded is Map ? decoded['ops'] : decoded;
    return StorySummaryDocument.fromFirestore(
      rawDocument,
      fallbackPlainText: fallbackPlainText,
    );
  }
}
