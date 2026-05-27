// Needs csv file from the assets
// handles the reading and processing of raw data to typesafe entity
import 'package:tudloapp/data/csv_reader.dart';
import 'package:tudloapp/data/dictionary/dictionary_item.dart';

class DictionaryService {
  final CsvReader _reader;

  DictionaryService()
    : _reader = CsvReader(filepath: 'assets/data/dictionary.csv');

  Future<List<DictionaryEntry>> getEntries() async {
    final rawData = await _reader.read();

    rawData.removeAt(0); // skip header row

    return rawData.map((row) {
      return DictionaryEntry(hiligaynon: row[0] ?? '', english: row[1] ?? '');
    }).toList();
  }
}
