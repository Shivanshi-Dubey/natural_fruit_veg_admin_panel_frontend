import 'dart:html' as html;
import 'dart:convert';
import 'package:csv/csv.dart';

class CsvExport {
  static void downloadCsv({
    required String filename,
    required List<List<String>> rows,
  }) {
    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
