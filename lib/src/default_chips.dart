import 'package:visualhdl_dart/src/chip.dart';
import 'package:visualhdl_dart/src/variable.dart';

class And extends Chip {
  And({
    required Variable a,
    required Variable b,
    required Variable output,
  }) : super(
          name: 'And',
          input: VariableTable.manual(
            {
              Variable('a'): a,
              Variable('b'): b,
            },
          ),
          output: VariableTable.manual({
            Variable('out'): output,
          }),
          parts: [],
        );
}

class Or extends Chip {
  Or({
    required Variable a,
    required Variable b,
    required Variable output,
  }) : super(
          name: 'Or',
          input: VariableTable.manual(
            {
              Variable('a'): a,
              Variable('b'): b,
            },
          ),
          output: VariableTable.manual({
            Variable('out'): output,
          }),
          parts: [],
        );
}

class Not extends Chip {
  Not({
    required Variable input,
    required Variable output,
  }) : super(
          name: 'Not',
          input: VariableTable.manual(
            {
              Variable('in'): input,
            },
          ),
          output: VariableTable.manual({
            Variable('out'): output,
          }),
          parts: [],
        );
}

class Nand extends Chip {
  Nand({
    required Variable a,
    required Variable b,
    required Variable output,
  }) : super(
          name: 'Nand',
          input: VariableTable.manual(
            {
              Variable('a'): a,
              Variable('b'): b,
            },
          ),
          output: VariableTable.manual({
            Variable('out'): output,
          }),
          parts: [
            And(a: a, b: b, output: Variable('Nandab')),
            Not(input: Variable('Nandab'), output: output),
          ],
        );
}
