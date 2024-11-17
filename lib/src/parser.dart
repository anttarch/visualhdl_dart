import 'dart:convert';
import 'package:visualhdl_dart/src/chip.dart';
import 'package:visualhdl_dart/src/default_chips.dart';
import 'package:visualhdl_dart/src/variable.dart';

class Parser {
  void parseHDLFile(String hdlFile) {
    if (!_validateHDLFile(hdlFile)) return;

    String name;
    VariableTable input;
    VariableTable output;
    List<Chip> parts = [];

    for (final String line in LineSplitter().convert(hdlFile)) {
      if (line.contains('CHIP')) {
        name = _ParserFunctions.getChipName(line);
      }

      if (line.contains('IN')) {
        input = _ParserFunctions.getIOVariables(line);
      }

      if (line.contains('OUT')) {
        output = _ParserFunctions.getIOVariables(line, false);
      }

      if (line.contains('PARTS:')) {
        for (final String partLine in LineSplitter()
            .convert(hdlFile.substring(hdlFile.indexOf('PARTS:')))) {
          if (line.contains('PARTS:') || line.contains('}')) continue;
          parts.add(_ParserFunctions.getPart(partLine));
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
      String chipPattern = r'CHIP[ \t]\w+[ \t]*\{(?:[^\{\}]+)\}';
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
  static String getChipName(String line) {
    String pattern = r'(?<name>(?<=CHIP[ \t])\w+(?=[ \t]*\{))';
    RegExp regexp = RegExp(pattern);

    Iterable<RegExpMatch> matches = regexp.allMatches(line);
    return matches.elementAt(0).namedGroup('name')!;
  }

  static VariableTable getIOVariables(String line, [bool input = true]) {
    String pattern = r'(?<pins>\w+(?:\[\d+\]){0,1}(?=[ \t]*\,|[ \t]*\;))';
    RegExp regexp = RegExp(pattern);
    List<Variable> result = [];

    Iterable<RegExpMatch> matches = regexp.allMatches(line);
    for (final match in matches) {
      result.add(Variable(match.namedGroup('pins')!));
    }

    return VariableTable(result);
  }

  static Chip getPart(String line) {
    String pattern =
        r'(?<chipName>\w+)(?=[ \t]*\()|(?<variables>\w+(?:\[\d+\]){0,1}[ \t]*\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*)';
    RegExp regexp = RegExp(pattern);
    String? chipName;
    Map<String, Map<Variable, Variable>> result = {};

    Iterable<RegExpMatch> matches = regexp.allMatches(line);
    for (final match in matches) {
      chipName = match.namedGroup('chipName') ?? chipName;
      String? variableAssignment = match.namedGroup('variables');
      if (variableAssignment != null) {
        String pin = variableAssignment.split('=')[0];
        String variable = variableAssignment.split('=')[1];
        if (result.containsKey(chipName)) {
          result.update(
              chipName!, (val) => {...val, Variable(pin): Variable(variable)});
        } else {
          result.addAll({
            chipName!: {Variable(pin): Variable(variable)}
          });
        }
      }
    }

    late Chip part;
    result.forEach((k, v) {
      switch (k) {
        case 'And':
          part = And(
            a: v.values.elementAt(0),
            b: v.values.elementAt(1),
            output: v.values.elementAt(2),
          );
        case 'Or':
          part = Or(
            a: v.values.elementAt(0),
            b: v.values.elementAt(1),
            output: v.values.elementAt(2),
          );
        case 'Not':
          part = Not(
            input: v.values.elementAt(0),
            output: v.values.elementAt(1),
          );
        case 'Nand':
          part = Nand(
            a: v.values.elementAt(0),
            b: v.values.elementAt(1),
            output: v.values.elementAt(2),
          );
        default:
          part = Chip(
            name: k,
            input: VariableTable.manual(
              Map.fromEntries(
                [
                  for (int i = 0; i < v.length - 1; i++) v.entries.elementAt(i),
                ],
              ),
            ),
            output: VariableTable.manual(Map.fromEntries([v.entries.last])),
            parts: [],
          );
      }
    });

    return part;
  }
}
