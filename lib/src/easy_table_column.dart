import 'package:easy_table/src/easy_table_cell.dart';
import 'package:easy_table/src/easy_table_cell_builder.dart';
import 'package:easy_table/src/easy_table_header_cell_builder.dart';
import 'package:easy_table/src/easy_table_value_mapper.dart';
import 'package:flutter/widgets.dart';

class EasyTableColumn<ROW_VALUE> {
  EasyTableColumn(
      {this.cellBuilder,
      this.initialWidth = 100,
      this.valueMapper,
      this.name,
      this.fractionDigits,
      this.headerCellBuilder = HeaderCellBuilders.defaultHeaderCellBuilder});

  final String? name;
  final double initialWidth;
  final EasyTableValueMapper<ROW_VALUE>? valueMapper;
  final EasyTableCellBuilder<ROW_VALUE>? cellBuilder;
  final EasyTableHeaderCellBuilder? headerCellBuilder;
  final int? fractionDigits;

  Widget? buildCellWidget(BuildContext context, ROW_VALUE rowValue) {
    if (cellBuilder != null) {
      return cellBuilder!(context, rowValue);
    }
    if (valueMapper != null) {
      dynamic cellValue = valueMapper!(rowValue);
      if (cellValue is String) {
        return EasyTableCell(value: cellValue);
      } else if (cellValue is int) {
        return EasyTableCell.int(value: cellValue);
      } else if (cellValue is double) {
        return EasyTableCell.double(
            value: cellValue, fractionDigits: fractionDigits);
      } else if (cellValue == null) {
        return const EasyTableCell();
      }
      return EasyTableCell(value: cellValue.toString());
    }
    return null;
  }
}
