import 'dart:core';

class Variable {
  Variable(this.name, [this.size = 1]);

  Variable.on() : this('true');

  Variable.off() : this('false');

  String name;
  int size;
  (int, int?)? bus;

  String getSizeString() {
    if (size > 1) return '$name[$size]';
    return name;
  }

  @override
  String toString() {
    if (bus == null) {
      return getSizeString();
    }

    if (bus!.$2 != null) return '$name[${bus!.$1}..${bus!.$2}]';
    return '$name[${bus!.$1}]';
  }

  Variable operator [](int size) {
    if (bus != null) {
      bus = (bus!.$1, size);
    } else {
      bus = (size, null);
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
