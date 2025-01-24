import 'dart:core';

class Variable {
  Variable(this.name, [this.size = 1, this.clocked = false]);

  Variable.on() : this('true');

  Variable.off() : this('false');

  bool clocked;
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

  @override
  bool operator ==(Object other) {
    return other is Variable &&
        name == other.name &&
        size == other.size &&
        bus == other.bus;
  }

  @override
  int get hashCode => Object.hash(name, size, bus);

  Variable operator [](int size) {
    if (size == -1) {
      bus = null;

      return this;
    }

    if (bus != null && bus!.end == null) {
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

  @override
  bool operator ==(Object other) {
    return other is VariableTable && table == other.table;
  }

  @override
  int get hashCode => table.hashCode;

  void forEach(void Function(Variable, Variable) action) =>
      table.forEach(action);
}
