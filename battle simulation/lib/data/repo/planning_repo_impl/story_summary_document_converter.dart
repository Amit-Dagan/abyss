import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docx_creator/docx_creator.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';
import 'package:xml/xml.dart';

class StorySummaryDocumentConverter {
  const StorySummaryDocumentConverter();

  Future<List<Map<String, dynamic>>> importDocx(Uint8List bytes) async {
    // The docx_creator reader can throw LateInitializationError in optimized
    // web builds for otherwise valid files. Import uses our stable XML reader;
    // docx_creator remains useful for export.
    return _importDocxPlainText(bytes);
  }

  List<Map<String, dynamic>> _importDocxPlainText(Uint8List bytes) {
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    final ArchiveFile? documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) {
      throw StateError('Invalid .docx file: missing word/document.xml');
    }

    final XmlDocument document = XmlDocument.parse(
      utf8.decode(_fileBytes(documentFile)),
    );
    final _DocxNumberingMap numberingMap = _readNumberingMap(archive);
    final List<Map<String, dynamic>> operations = <Map<String, dynamic>>[];
    final Iterable<XmlElement> paragraphs = document.descendants
        .whereType<XmlElement>()
        .where((XmlElement element) => element.name.local == 'p');

    for (final XmlElement paragraph in paragraphs) {
      for (final _DocxRun run in _docxRuns(paragraph)) {
        if (run.text.isEmpty) {
          continue;
        }
        operations.add(
          run.attributes.isEmpty
              ? <String, dynamic>{'insert': run.text}
              : <String, dynamic>{
                  'insert': run.text,
                  'attributes': run.attributes,
                },
        );
      }

      final Map<String, dynamic> lineAttributes = _docxLineAttributes(
        paragraph,
        numberingMap,
      );
      operations.add(
        lineAttributes.isEmpty
            ? <String, dynamic>{'insert': '\n'}
            : <String, dynamic>{'insert': '\n', 'attributes': lineAttributes},
      );
    }

    if (operations.isEmpty) {
      return StorySummaryDocument.fromPlainText('');
    }
    return operations;
  }

  List<_DocxRun> _docxRuns(XmlElement paragraph) {
    final List<_DocxRun> runs = <_DocxRun>[];
    for (final XmlElement run in paragraph.childElements.where(
      (XmlElement element) => element.name.local == 'r',
    )) {
      final String text = run.descendants
          .whereType<XmlElement>()
          .where((XmlElement element) => element.name.local == 't')
          .map((XmlElement element) => element.innerText)
          .join();
      if (text.isEmpty) {
        continue;
      }
      runs.add(_DocxRun(text, _docxRunAttributes(run)));
    }
    return runs;
  }

  Map<String, dynamic> _docxRunAttributes(XmlElement run) {
    final XmlElement? runProperties = _firstDescendant(run, 'rPr');
    if (runProperties == null) {
      return const <String, dynamic>{};
    }

    final Map<String, dynamic> attributes = <String, dynamic>{};
    if (_hasProperty(runProperties, 'b')) {
      attributes['bold'] = true;
    }
    if (_hasProperty(runProperties, 'i')) {
      attributes['italic'] = true;
    }
    if (_hasProperty(runProperties, 'u')) {
      attributes['underline'] = true;
    }
    final String? runStyle = _attributeValue(
      _firstDescendant(runProperties, 'rStyle'),
      'val',
    );
    if (runStyle == 'Code' || runStyle == 'HyperlinkCode') {
      attributes['code'] = true;
    }
    return attributes;
  }

  Map<String, dynamic> _docxLineAttributes(
    XmlElement paragraph,
    _DocxNumberingMap numberingMap,
  ) {
    final XmlElement? style = paragraph.descendants
        .whereType<XmlElement>()
        .where((XmlElement element) => element.name.local == 'pStyle')
        .firstOrNull;
    final String? styleValue = style == null
        ? null
        : _attributeValue(style, 'val');
    final Map<String, dynamic> attributes = <String, dynamic>{};
    switch (styleValue) {
      case 'Heading1':
        attributes['header'] = 1;
        break;
      case 'Heading2':
        attributes['header'] = 2;
        break;
      case 'Heading3':
        attributes['header'] = 3;
        break;
      case 'Quote':
        attributes['blockquote'] = true;
        break;
    }

    final _DocxListInfo? listInfo = _docxListInfo(paragraph, numberingMap);
    if (listInfo != null) {
      attributes['list'] = listInfo.quillListType;
      if (listInfo.level > 0) {
        attributes['indent'] = listInfo.level;
      }
    }
    return attributes;
  }

  _DocxListInfo? _docxListInfo(
    XmlElement paragraph,
    _DocxNumberingMap numberingMap,
  ) {
    final XmlElement? numberProperties = _firstDescendant(paragraph, 'numPr');
    if (numberProperties == null) {
      return null;
    }
    final String? numId = _attributeValue(
      _firstDescendant(numberProperties, 'numId'),
      'val',
    );
    if (numId == null || numId == '0') {
      return null;
    }

    final int level =
        int.tryParse(
          _attributeValue(_firstDescendant(numberProperties, 'ilvl'), 'val') ??
              '',
        ) ??
        0;
    final String format = numberingMap.formatFor(numId, level) ?? 'bullet';
    return _DocxListInfo(
      level: level,
      quillListType: format == 'bullet' ? 'bullet' : 'ordered',
    );
  }

  _DocxNumberingMap _readNumberingMap(Archive archive) {
    final ArchiveFile? numberingFile = archive.findFile('word/numbering.xml');
    if (numberingFile == null) {
      return const _DocxNumberingMap();
    }

    final XmlDocument numbering = XmlDocument.parse(
      utf8.decode(_fileBytes(numberingFile)),
    );
    final Map<String, String> numToAbstract = <String, String>{};
    final Map<String, Map<int, String>> abstractFormats =
        <String, Map<int, String>>{};

    for (final XmlElement abstractNum
        in numbering.descendants.whereType<XmlElement>().where(
          (XmlElement element) => element.name.local == 'abstractNum',
        )) {
      final String? abstractId = _attributeValue(abstractNum, 'abstractNumId');
      if (abstractId == null) {
        continue;
      }
      final Map<int, String> levelFormats = <int, String>{};
      for (final XmlElement level in abstractNum.childElements.where(
        (XmlElement element) => element.name.local == 'lvl',
      )) {
        final int ilvl =
            int.tryParse(_attributeValue(level, 'ilvl') ?? '') ?? 0;
        final String? format = _attributeValue(
          _firstDescendant(level, 'numFmt'),
          'val',
        );
        if (format != null && format.isNotEmpty) {
          levelFormats[ilvl] = format;
        }
      }
      abstractFormats[abstractId] = levelFormats;
    }

    for (final XmlElement num
        in numbering.descendants.whereType<XmlElement>().where(
          (XmlElement element) => element.name.local == 'num',
        )) {
      final String? numId = _attributeValue(num, 'numId');
      final String? abstractId = _attributeValue(
        _firstDescendant(num, 'abstractNumId'),
        'val',
      );
      if (numId != null && abstractId != null) {
        numToAbstract[numId] = abstractId;
      }
    }

    return _DocxNumberingMap(
      numToAbstract: numToAbstract,
      abstractFormats: abstractFormats,
    );
  }

  XmlElement? _firstDescendant(XmlElement? element, String localName) {
    if (element == null) {
      return null;
    }
    return element.descendants
        .whereType<XmlElement>()
        .where((XmlElement candidate) => candidate.name.local == localName)
        .firstOrNull;
  }

  bool _hasProperty(XmlElement element, String localName) {
    final XmlElement? property = _firstDescendant(element, localName);
    if (property == null) {
      return false;
    }
    final String? value = _attributeValue(property, 'val');
    return value == null || value != 'false';
  }

  List<int> _fileBytes(ArchiveFile file) {
    return List<int>.from(file.content as List<int>);
  }

  String? _attributeValue(XmlElement? element, String localName) {
    if (element == null) {
      return null;
    }
    for (final XmlAttribute attribute in element.attributes) {
      if (attribute.name.local == localName) {
        return attribute.value;
      }
    }
    return null;
  }

  Future<Uint8List> exportDocx({
    required String storyTitle,
    required List<Map<String, dynamic>> document,
  }) async {
    final List<_QuillLine> lines = _parseLines(document);
    final List<DocxNode> elements = <DocxNode>[];
    final List<DocxListItem> pendingListItems = <DocxListItem>[];
    String? pendingListType;

    void flushList() {
      if (pendingListItems.isEmpty) {
        return;
      }
      elements.add(
        DocxList.items(
          List<DocxListItem>.from(pendingListItems),
          ordered: pendingListType == 'ordered',
        ),
      );
      pendingListItems.clear();
      pendingListType = null;
    }

    if (storyTitle.trim().isNotEmpty) {
      elements.add(DocxParagraph.heading1(storyTitle.trim()));
    }

    for (final _QuillLine line in lines) {
      final String? listType = line.listType;
      if (listType != null) {
        if (pendingListType != null && pendingListType != listType) {
          flushList();
        }
        pendingListType = listType;
        pendingListItems.add(DocxListItem.rich(_toDocxInlines(line.spans)));
        continue;
      }

      flushList();
      elements.add(_lineToDocxBlock(line));
    }
    flushList();

    final DocxBuiltDocument doc = DocxBuiltDocument(elements: elements);
    return DocxExporter().exportToBytes(doc);
  }

  List<_QuillLine> _parseLines(List<Map<String, dynamic>> document) {
    final List<_QuillLine> lines = <_QuillLine>[];
    final List<_QuillSpan> currentSpans = <_QuillSpan>[];

    for (final Map<String, dynamic> operation in document) {
      final Object? insert = operation['insert'];
      if (insert is! String) {
        continue;
      }

      final Map<String, dynamic> attributes = _normalizeAttributes(
        operation['attributes'],
      );
      int start = 0;
      for (int index = 0; index < insert.length; index++) {
        if (insert.codeUnitAt(index) != 10) {
          continue;
        }

        if (index > start) {
          currentSpans.add(
            _QuillSpan(
              insert.substring(start, index),
              _inlineAttributes(attributes),
            ),
          );
        }
        lines.add(
          _QuillLine(
            List<_QuillSpan>.from(currentSpans),
            _lineAttributes(attributes),
          ),
        );
        currentSpans.clear();
        start = index + 1;
      }

      if (start < insert.length) {
        currentSpans.add(
          _QuillSpan(insert.substring(start), _inlineAttributes(attributes)),
        );
      }
    }

    if (currentSpans.isNotEmpty) {
      lines.add(_QuillLine(List<_QuillSpan>.from(currentSpans), const {}));
    }
    if (lines.isEmpty) {
      lines.add(const _QuillLine(<_QuillSpan>[], <String, dynamic>{}));
    }
    return lines;
  }

  DocxBlock _lineToDocxBlock(_QuillLine line) {
    final List<DocxInline> children = _toDocxInlines(line.spans);
    final int? header = line.headerLevel;
    if (header != null) {
      return DocxParagraph(styleId: _headingStyle(header), children: children);
    }
    if (line.isCodeBlock) {
      return DocxParagraph(
        shadingFill: 'F5F5F5',
        children: _toDocxInlines(line.spans, forceCode: true),
      );
    }
    if (line.isBlockquote) {
      return DocxParagraph(
        indentLeft: 720,
        styleId: DocxStyleIds.quote,
        children: children,
      );
    }
    return DocxParagraph(children: children);
  }

  List<DocxInline> _toDocxInlines(
    List<_QuillSpan> spans, {
    bool forceCode = false,
  }) {
    if (spans.isEmpty) {
      return const <DocxInline>[DocxText('')];
    }
    return spans
        .map(
          (_QuillSpan span) => DocxText(
            span.text,
            fontWeight: span.isBold
                ? DocxFontWeight.bold
                : DocxFontWeight.normal,
            fontStyle: span.isItalic
                ? DocxFontStyle.italic
                : DocxFontStyle.normal,
            decorations: span.isUnderline
                ? const <DocxTextDecoration>[DocxTextDecoration.underline]
                : const <DocxTextDecoration>[],
            fontFamily: forceCode || span.isCode ? 'monospace' : null,
            href: span.link,
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _normalizeAttributes(Object? value) {
    if (value is! Map) {
      return const <String, dynamic>{};
    }
    return value.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  Map<String, dynamic> _inlineAttributes(Map<String, dynamic> attributes) {
    final Map<String, dynamic> inline = Map<String, dynamic>.from(attributes);
    for (final String key in <String>[
      'header',
      'list',
      'indent',
      'blockquote',
      'code-block',
    ]) {
      inline.remove(key);
    }
    return inline;
  }

  Map<String, dynamic> _lineAttributes(Map<String, dynamic> attributes) {
    final Map<String, dynamic> line = <String, dynamic>{};
    for (final String key in <String>[
      'header',
      'list',
      'indent',
      'blockquote',
      'code-block',
    ]) {
      if (attributes.containsKey(key)) {
        line[key] = attributes[key];
      }
    }
    return line;
  }

  String _headingStyle(int level) {
    return switch (level) {
      1 => DocxStyleIds.heading1,
      2 => DocxStyleIds.heading2,
      3 => DocxStyleIds.heading3,
      4 => DocxStyleIds.heading4,
      5 => DocxStyleIds.heading5,
      _ => DocxStyleIds.heading6,
    };
  }
}

class _QuillLine {
  final List<_QuillSpan> spans;
  final Map<String, dynamic> attributes;

  const _QuillLine(this.spans, this.attributes);

  int? get headerLevel {
    final Object? value = attributes['header'];
    if (value is int) {
      return value.clamp(1, 6);
    }
    if (value is num) {
      return value.toInt().clamp(1, 6);
    }
    return null;
  }

  String? get listType {
    final Object? value = attributes['list'];
    if (value == 'bullet' || value == 'ordered') {
      return value as String;
    }
    return null;
  }

  bool get isBlockquote => attributes['blockquote'] == true;

  bool get isCodeBlock => attributes['code-block'] == true;
}

class _QuillSpan {
  final String text;
  final Map<String, dynamic> attributes;

  const _QuillSpan(this.text, this.attributes);

  bool get isBold => attributes['bold'] == true;

  bool get isItalic => attributes['italic'] == true;

  bool get isUnderline => attributes['underline'] == true;

  bool get isCode => attributes['code'] == true;

  String? get link {
    final Object? value = attributes['link'];
    return value is String && value.isNotEmpty ? value : null;
  }
}

class _DocxRun {
  final String text;
  final Map<String, dynamic> attributes;

  const _DocxRun(this.text, this.attributes);
}

class _DocxListInfo {
  final int level;
  final String quillListType;

  const _DocxListInfo({required this.level, required this.quillListType});
}

class _DocxNumberingMap {
  final Map<String, String> numToAbstract;
  final Map<String, Map<int, String>> abstractFormats;

  const _DocxNumberingMap({
    this.numToAbstract = const <String, String>{},
    this.abstractFormats = const <String, Map<int, String>>{},
  });

  String? formatFor(String numId, int level) {
    final String? abstractId = numToAbstract[numId];
    if (abstractId == null) {
      return null;
    }
    final Map<int, String>? formats = abstractFormats[abstractId];
    if (formats == null || formats.isEmpty) {
      return null;
    }
    return formats[level] ?? formats[0];
  }
}
