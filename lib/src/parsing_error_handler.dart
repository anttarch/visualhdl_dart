class ParsingErrorHandler {
  static void _validateBus(String line) {
    // Bus size without pin
    if (line.contains(RegExp(r'(?<!\w)(?:\[\d*\])'))) {
      throw ParsingException(
        'Invalid pin syntax',
        'Cannot have a bus size without a pin',
      );
    }

    // Empty bus size
    if (line.contains(RegExp(r'\w+\[\]'))) {
      throw ParsingException(
        'Invalid bus syntax',
        'Cannot have an empty bus size',
      );
    }

    // Non-digit bus size
    if (line.contains(RegExp(r'\w+\[.*[^\d.]+.*\]'))) {
      throw ParsingException(
        'Invalid bus size',
        'Try removing letters and/or symbols',
      );
    }

    // TODO(antarch): bus interval
  }

  static void handleInvalidChip(String chip) {
    // Missing chips's name
    if (chip.contains(RegExp(r'CHIP[ \t]*\{'))) {
      throw ParsingException(
        'Missing chip\'s name',
        'A name is needed to identify the chip',
      );
    }

    if (chip.contains(RegExp(r'CHIP[ \t]+(?:.+[^[:alpha:]]+.+)[ \t]*\{'))) {
      throw ParsingException(
        'Invalid chip name',
        'Try removing non-alphabetical characters',
      );
    }

    // Generic
    // Missing ending bracket
    throw ParsingException(
      'Missing a chip implementation',
      'Try adding the ending bracket',
    );
  }

  static void handleInvalidIO(String ioLine, [bool input = true]) {
    // Missing IN/OUT keyword
    // if (!a.contains(input ? 'IN' : 'OUT')) {
    //   throw ParsingException(
    //     'Missing the ${input ? 'input' : 'output'} pinout',
    //     'Try adding the \'IN\' keyword',
    //   );
    // }

    // Missing semi-colon
    if (ioLine.contains(RegExp(r'.*;$'))) {
      throw ParsingException(
        'Invalid syntax',
        'Try adding a semi-colon (;) at the end',
      );
    }

    // Pins not separated by comma
    if (ioLine.substring(ioLine.indexOf(input ? 'IN' : 'OUT')).contains(
        RegExp(r'(?:\w+(?:\[\d+\]){0,1}[ \t]+\w+(?:\[\d+\]){0,1})+'))) {
      throw ParsingException(
        'Invalid pin syntax',
        'Try separating the pins with a comma (,)',
      );
    }

    _validateBus(ioLine);

    throw ParsingException(
      'Invalid ${input ? 'input' : 'output'} pinout',
    );
  }

  static void handleInvalidPart(String partLine) {
    // Missing chip's part definition
    if (!partLine.contains(RegExp(r'(?:\w+[ \t]*)(?=\(.*\)\;)'))) {
      throw ParsingException(
        'Invalid part syntax',
        'Try adding the definition for the part',
      );
    }

    // Missing chip's part name
    if (!partLine.contains(RegExp(r'\w*[ \t]*\(.*\)\;'))) {
      throw ParsingException(
        'Invalid part syntax',
        'Try adding a name to the part',
      );
    }

    // Missing semi-colon
    if (partLine.contains(RegExp(r'.*;$'))) {
      throw ParsingException(
        'Invalid syntax',
        'Try adding a semi-colon (;) at the end',
      );
    }

    _validateBus(partLine);

    // Pins not separated by comma
    if (partLine.contains(RegExp(
        r'\w+[ \t]*(?:\[\d+\]){0,1}\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]+\w+'))) {
      throw ParsingException(
        'Invalid part definition syntax',
        'Try separating the pins with a comma (,)',
      );
    }

    // Variable assigned to nothing
    if (partLine.contains(
        RegExp(r'(?:,|\()[^\w]*[ \t]*\=[ \t]*\w+(?:\[\d+\]){0,1}[ \t]*'))) {
      throw ParsingException(
        'Invalid part definition syntax',
        'Cannot assign a variable to nothing',
      );
    }

    // Pin assigned to nothing
    if (partLine
        .contains(RegExp(r'\w+(?:\[\d+\]){0,1}[ \t]*\=[^\w]*[ \t]*(?:,|\))'))) {
      throw ParsingException(
        'Invalid part definition syntax',
        'Cannot assign a pin to nothing',
      );
    }
  }
}

class ParsingException implements Exception {
  final String? details;
  final String message;

  @pragma("vm:entry-point")
  const ParsingException([this.message = '', this.details]);

  @override
  String toString() {
    return message;
  }
}
