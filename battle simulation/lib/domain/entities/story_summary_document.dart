class StorySummaryDocument {
  static List<Map<String, dynamic>> fromFirestore(
    Object? rawDocument, {
    String? fallbackPlainText,
  }) {
    final List<Map<String, dynamic>> normalized = _normalizeDocument(
      rawDocument,
    );
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return fromPlainText(fallbackPlainText ?? '');
  }

  static List<Map<String, dynamic>> fromPlainText(String text) {
    final String normalized = _withoutRawDeltaJson(text.trimRight());
    if (normalized.isEmpty) {
      return <Map<String, dynamic>>[
        <String, dynamic>{'insert': '\n'},
      ];
    }

    final List<String> paragraphs = normalized
        .split(RegExp(r'\n{2,}'))
        .map((String paragraph) => paragraph.trim())
        .where((String paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);

    if (paragraphs.isEmpty) {
      return <Map<String, dynamic>>[
        <String, dynamic>{'insert': '\n'},
      ];
    }

    final List<Map<String, dynamic>> operations = <Map<String, dynamic>>[];
    for (final String paragraph in paragraphs) {
      operations.add(<String, dynamic>{'insert': paragraph});
      operations.add(<String, dynamic>{'insert': '\n'});
    }
    return operations;
  }

  static String toPlainText(List<Map<String, dynamic>> document) {
    final StringBuffer buffer = StringBuffer();
    for (final Map<String, dynamic> operation in document) {
      final Object? insert = operation['insert'];
      if (insert is String) {
        buffer.write(insert);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\n+$'), '').trim();
  }

  static List<Map<String, dynamic>> clone(List<Map<String, dynamic>> document) {
    return document
        .map(
          (Map<String, dynamic> operation) => operation.map(
            (String key, dynamic value) =>
                MapEntry<String, dynamic>(key, _cloneJsonValue(value)),
          ),
        )
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _normalizeDocument(Object? rawDocument) {
    if (rawDocument is! List) {
      return const <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> operations = <Map<String, dynamic>>[];
    for (final Object? item in rawDocument) {
      if (item is Map) {
        final Object? insert = item['insert'];
        if (insert is! String) {
          continue;
        }
        final Map<String, dynamic> operation = <String, dynamic>{
          'insert': insert,
        };
        final Object? rawAttributes = item['attributes'];
        if (rawAttributes is Map) {
          final Map<String, dynamic> attributes = rawAttributes.map(
            (dynamic key, dynamic value) => MapEntry<String, dynamic>(
              key.toString(),
              _cloneJsonValue(value),
            ),
          );
          if (attributes.isNotEmpty) {
            operation['attributes'] = attributes;
          }
        }
        operations.add(operation);
      }
    }
    if (operations.isNotEmpty) {
      final Object? lastInsert = operations.last['insert'];
      if (lastInsert is String && !lastInsert.endsWith('\n')) {
        operations.add(<String, dynamic>{'insert': '\n'});
      }
    }
    return operations;
  }

  static String _withoutRawDeltaJson(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final bool looksLikeJson =
        (trimmed.startsWith('[') && trimmed.endsWith(']')) ||
        (trimmed.startsWith('{') && trimmed.endsWith('}'));
    if (!looksLikeJson || !trimmed.contains('"insert"')) {
      return text;
    }
    return '';
  }

  static dynamic _cloneJsonValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic nestedValue) => MapEntry<String, dynamic>(
          key.toString(),
          _cloneJsonValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneJsonValue).toList(growable: false);
    }
    return value;
  }
}
