import 'dart:convert';
import 'package:visualhdl_dart/src/chip.dart';
import 'package:visualhdl_dart/src/default_chips.dart';
import 'package:visualhdl_dart/src/parsing_error_handler.dart';
import 'package:visualhdl_dart/src/variable.dart';

class Parser {
  Chip parseHDLFile(String hdlFile) {
    _validateHDLFile(hdlFile);

    late String name;
    late VariableTable input;
    late VariableTable output;
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
          if (line.trim().contains('PARTS:') || line.trim().contains('}')) {
            continue;
          }
          parts.add(_ParserFunctions.getPart(partLine));
        }
      }
    }

    return Chip(
      name: name,
      input: input,
      output: output,
      parts: parts,
    );
  }

  String _cleanHDLFile(String hdlFile) =>
      hdlFile.replaceAll(RegExp(r'\/\/.*'), '').trim();

  void _validateHDLFile(String hdlFile) {
    String file = _cleanHDLFile(hdlFile);

    if (file.contains('CHIP')) {
      String chipPattern = r'CHIP[ \t]+\w+[ \t]*\{(?:[^\{\}]+)\}';

      bool hasValidChip =
          file.contains(RegExp(chipPattern), file.indexOf('CHIP'));

      if (!hasValidChip) {
        ParsingErrorHandler.handleInvalidChip(file);
      }
    } else {
      throw ParsingException(
        'Missing a chip implementation',
        'Try adding the \'CHIP\' keyword',
      );
    }

    if (file.contains('IN')) {
      String inputPattern =
          r'IN[ \t](?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\,)*(?:[ \t]*\w+\;$)';

      Iterable<String> inputPinout = LineSplitter()
          .convert(file.substring(file.indexOf('IN')))
          .takeWhile((e) => e.startsWith('IN'));

      if (inputPinout.length > 1) {
        throw ParsingException(
          'More than 1 input pinout was found',
          'Only a single pinout definition is supported',
        );
      } else {
        if (!inputPinout.single
            .contains(RegExp(inputPattern, multiLine: true))) {
          ParsingErrorHandler.handleInvalidIO(inputPinout.single);
        }
      }
    } else {
      throw ParsingException(
        'Missing the input pinout',
        'Try adding the \'IN\' keyword',
      );
    }

    if (file.contains('OUT')) {
      String outputPattern =
          r'OUT[ \t](?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\,)*(?:[ \t]*\w+\;$)';

      Iterable<String> outputPinout = LineSplitter()
          .convert(file.substring(file.indexOf('OUT')))
          .takeWhile((e) => e.startsWith('OUT'));

      if (outputPinout.length > 1) {
        throw ParsingException(
          'More than 1 output pinout was found',
          'Only a single pinout definition is supported',
        );
      } else {
        if (!outputPinout.single
            .contains(RegExp(outputPattern, multiLine: true))) {
          ParsingErrorHandler.handleInvalidIO(outputPinout.single, false);
        }
      }
    } else {
      throw ParsingException(
        'Missing the output pinout',
        'Try adding the \'OUT\' keyword',
      );
    }

    if (file.contains('PARTS:')) {
      // TODO(antarch): bus interval
      String partsPattern =
          r'\w+[ \t]*\((?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\,)*(?:[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*\)\;$)';

      for (final String line
          in LineSplitter().convert(file.substring(file.indexOf('PARTS:')))) {
        if (line.trim().contains('PARTS:') || line.trim().contains('}')) {
          continue;
        }

        if (!line.contains(RegExp(partsPattern, multiLine: true))) {
          ParsingErrorHandler.handleInvalidPart(line);
        }
      }
    } else {
      throw ParsingException(
        'Missing the parts of the chip',
        'Try adding the \'PARTS:\' keyword',
      );
    }
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
    // TODO(antarch): bus interval
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
