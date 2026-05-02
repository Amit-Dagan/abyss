import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/data/repo/planning_repo_impl/story_summary_document_converter.dart';
import 'package:todo_list/domain/entities/story_summary_document.dart';

void main() {
  group('StorySummaryDocumentConverter', () {
    const StorySummaryDocumentConverter converter =
        StorySummaryDocumentConverter();

    test(
      'imports docx bullet and ordered lists as Quill line attributes',
      () async {
        final List<Map<String, dynamic>> document = await converter.importDocx(
          _docxBytes(
            documentXml: '''
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr>
      <w:r><w:t>First bullet</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="2"/></w:numPr></w:pPr>
      <w:r><w:t>First ordered</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:numPr><w:ilvl w:val="1"/><w:numId w:val="1"/></w:numPr></w:pPr>
      <w:r><w:t>Nested bullet</w:t></w:r>
    </w:p>
  </w:body>
</w:document>
''',
            numberingXml: '''
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="10">
    <w:lvl w:ilvl="0"><w:numFmt w:val="bullet"/></w:lvl>
    <w:lvl w:ilvl="1"><w:numFmt w:val="bullet"/></w:lvl>
  </w:abstractNum>
  <w:abstractNum w:abstractNumId="20">
    <w:lvl w:ilvl="0"><w:numFmt w:val="decimal"/></w:lvl>
  </w:abstractNum>
  <w:num w:numId="1"><w:abstractNumId w:val="10"/></w:num>
  <w:num w:numId="2"><w:abstractNumId w:val="20"/></w:num>
</w:numbering>
''',
          ),
        );

        expect(document[0], <String, dynamic>{'insert': 'First bullet'});
        expect(document[1], <String, dynamic>{
          'insert': '\n',
          'attributes': <String, dynamic>{'list': 'bullet'},
        });
        expect(document[2], <String, dynamic>{'insert': 'First ordered'});
        expect(document[3], <String, dynamic>{
          'insert': '\n',
          'attributes': <String, dynamic>{'list': 'ordered'},
        });
        expect(document[4], <String, dynamic>{'insert': 'Nested bullet'});
        expect(document[5], <String, dynamic>{
          'insert': '\n',
          'attributes': <String, dynamic>{'list': 'bullet', 'indent': 1},
        });
      },
    );

    test('imports basic inline formatting from docx runs', () async {
      final List<Map<String, dynamic>> document = await converter.importDocx(
        _docxBytes(
          documentXml: '''
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r><w:rPr><w:b/></w:rPr><w:t>Bold</w:t></w:r>
      <w:r><w:t> normal </w:t></w:r>
      <w:r><w:rPr><w:i/><w:u w:val="single"/></w:rPr><w:t>styled</w:t></w:r>
    </w:p>
  </w:body>
</w:document>
''',
        ),
      );

      expect(document[0], <String, dynamic>{
        'insert': 'Bold',
        'attributes': <String, dynamic>{'bold': true},
      });
      expect(document[1], <String, dynamic>{'insert': ' normal '});
      expect(document[2], <String, dynamic>{
        'insert': 'styled',
        'attributes': <String, dynamic>{'italic': true, 'underline': true},
      });
    });

    test('does not convert raw delta json fallback into visible text', () {
      final List<Map<String, dynamic>> document =
          StorySummaryDocument.fromPlainText(
            '[{"insert":"This should not render as raw JSON"}]',
          );

      expect(StorySummaryDocument.toPlainText(document), isEmpty);
    });
  });
}

Uint8List _docxBytes({required String documentXml, String? numberingXml}) {
  final Archive archive = Archive();
  archive.addFile(_xmlFile('word/document.xml', documentXml));
  if (numberingXml != null) {
    archive.addFile(_xmlFile('word/numbering.xml', numberingXml));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

ArchiveFile _xmlFile(String name, String content) {
  final List<int> bytes = utf8.encode(content);
  return ArchiveFile(name, bytes.length, bytes);
}
