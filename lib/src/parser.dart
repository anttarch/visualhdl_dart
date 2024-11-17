import 'dart:convert';
import 'package:visualhdl_dart/src/chip.dart';
import 'package:visualhdl_dart/src/variable.dart';

class Parser {
  void parseHDLFile(String hdlFile) {
    if (!_validateHDLFile(hdlFile)) return;

    String name;
    VariableTable input;
    VariableTable output;
    List<Chip> parts;

    for (final String line in LineSplitter().convert(hdlFile)) {
      if (line.contains('CHIP')) {
        _ParserFunctions.getChipName(line);
      }

      if (line.contains('IN')) {
        _ParserFunctions.getIOVariables(line);
      }

      if (line.contains('OUT')) {
        _ParserFunctions.getIOVariables(line, false);
      }

      if (line.contains('PARTS:')) {
        for (final String partLine in LineSplitter()
            .convert(hdlFile.substring(hdlFile.indexOf('PARTS:')))) {
          if (line == 'PARTS:' || line == '}') continue;
          _ParserFunctions.getParts(partLine);
        }
      }
    }
  }

  String _cleanHDLFile(String hdlFile) =>
      hdlFile.replaceAll(RegExp(r'\/\/.*'), '').trim();

  bool _validateHDLFile(String hdlFile) {
    bool result = false;
    String file = _cleanHDLFile(hdlFile);

    result = file.contains('CHIP');
    result &= file.contains('IN');
    result &= file.contains('OUT');
    result &= file.contains('PARTS:');

    if (result) {
      String chipPattern = r'CHIP[ \t]\w*[ \t]*\{[\s\S]*\}';
      String inputPattern =
          r'IN[ \t](?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\,)*(?:[ \t]*\w+\;$)';
      String outputPattern =
          r'OUT[ \t](?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\,)*(?:[ \t]*\w+\;$)';
      String partsPattern =
          r'\w+[ \t]*\((?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\,)*(?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\)\;$)';

      result &= file.contains(RegExp(chipPattern), file.indexOf('CHIP'));
      result &= file.contains(RegExp(inputPattern, multiLine: true));
      result &= file.contains(
          RegExp(outputPattern, multiLine: true), file.indexOf('OUT'));

      for (final String line
          in LineSplitter().convert(file.substring(file.indexOf('PARTS:')))) {
        if (line == 'PARTS:' || line == '}') continue;
        result &= line.contains(RegExp(partsPattern, multiLine: true));
      }
    }

    return result;
  }
}

class _ParserFunctions {
  static getChipName(String line) {
    String pattern = r'(?<name>(?<=CHIP[ \t])\w+(?=[ \t]*\{))';
    RegExp regexp = RegExp(pattern);

    Iterable<RegExpMatch> matches = regexp.allMatches(line);

    for (final match in matches) {
      print(match.namedGroup('name'));
    }
  }

  static getIOVariables(String line, [bool input = true]) {
    String pattern = r'(?<names>\w+(?:\[\d+\]){0,1}(?=[ \t]*\,|[ \t]*\;))';
    RegExp regexp = RegExp(pattern, multiLine: true);

    Iterable<RegExpMatch> matches = regexp.allMatches(line);

    for (final match in matches) {
      print(match.namedGroup('names'));
    }
  }

  static getParts(String line) {
    String pattern =
        r'(?<variables>\w+(?:\[\d+\]){0,1}[ \t]*\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*)';
    RegExp regexp = RegExp(pattern, multiLine: true);

    Iterable<RegExpMatch> matches = regexp.allMatches(line);

    for (final match in matches) {
      print(match.namedGroup('variables'));
    }
  }
}
