import 'dart:core';

class Variable {
  Variable(this.name, [this.size = 1]);

  Variable.on() : this('true');

  Variable.off() : this('false');

  String name;
  int size;
  ({int start, int? end})? bus;

  String getSizeString() {
    if (size > 1) return '$name[$size]';
    return name;
  }

  @override
  String toString() {
    if (bus == null) {
      return getSizeString();
    }

    if (bus!.end != null) return '$name[${bus!.start}..${bus!.end}]';
    return '$name[${bus!.start}]';
  }

  Variable operator [](int size) {
    if (bus != null) {
      bus = (start: bus!.start, end: size);
    } else {
      bus = (start: size, end: null);
    }

    return this;
  }
}

class VariableTable {
  VariableTable(List<Variable> variables) {
    table.addAll(
      Map.fromIterable(
        variables,
        value: (v) {
          if ((v as Variable).size > 1) return Variable(v.name);
          return v;
        },
      ),
    );
  }

  VariableTable.manual(this.table);

  Map<Variable, Variable> table = {};

  Iterable<Variable> get keys => table.keys;
  Iterable<Variable> get values => table.values;

  void forEach(void Function(Variable, Variable) action) =>
      table.forEach(action);
}
