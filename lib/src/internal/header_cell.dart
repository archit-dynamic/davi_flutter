import 'package:axis_layout/axis_layout.dart';
import 'package:davi/davi.dart';
import 'package:davi/src/internal/sort_util.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// [Davi] header cell.
@internal
class DaviHeaderCell<DATA> extends StatefulWidget {
  /// Builds a header cell.
  const DaviHeaderCell({Key? key,
    required this.model,
    required this.column,
    required this.resizable,
    required this.tapToSortEnabled,
    required this.columnIndex,
    required this.isMultiSorted,
    this.columnMinWidth})
      : super(key: key);

  final DaviModel<DATA> model;
  final DaviColumn<DATA> column;
  final bool resizable;
  final bool tapToSortEnabled;
  final int columnIndex;
  final bool isMultiSorted;
  final double? columnMinWidth;

  @override
  State<StatefulWidget> createState() => _DaviHeaderCellState();
}

class _DaviHeaderCellState extends State<DaviHeaderCell> {
  bool _hovered = false;
  bool _headerCellHovered = false;
  double _lastDragPos = 0;

  @override
  Widget build(BuildContext context) {
    HeaderCellThemeData theme = DaviTheme
        .of(context)
        .headerCell;

    final bool resizing = widget.model.columnInResizing == widget.column;
    final bool sortEnabled = widget.tapToSortEnabled &&
        !resizing &&
        widget.model.columnInResizing == null;
    final bool resizable = widget.resizable &&
        widget.column.resizable &&
        widget.column.grow == null &&
        (sortEnabled || resizing);

    List<Widget> children = [];

    if (widget.column.leading != null) {
      children.add(Align(
          alignment: widget.column.headerAlignment ?? theme.alignment,
          child: widget.column.leading!));
    }
    children.add(AxisLayoutChild(
        shrink: theme.expandableName ? 0 : 1,
        expand: theme.expandableName ? 1 : 0,
        child: _textWidget(context)
    ));

    final DaviSort? sort = widget.column.sort;
    if (sort != null) {
      Widget sortIconWidget =
      theme.sortIconBuilder(sort.direction, theme.sortIconColors);
      children.add(Align(
        alignment: widget.column.headerAlignment ?? theme.alignment,
        child: sortIconWidget,
      ));

      if (widget.isMultiSorted) {
        if (theme.sortPriorityGap != null) {
          children.add(SizedBox(width: theme.sortPriorityGap));
        }
        children.add(Align(
            alignment: widget.column.headerAlignment ?? theme.alignment,
            child: Text(widget.column.sortPriority!.toString(),
                style: TextStyle(
                    color: theme.sortPriorityColor,
                    fontSize: theme.sortPrioritySize))));
      }
    }

    if (widget.column.trailing != null) {
      var trailingWidget = widget.column.trailing;

      trailingWidget = Visibility(
          visible: _headerCellHovered || _hovered || widget.column.showTrailingIcon == true,
          child: trailingWidget!);

      children.add(trailingWidget);
    }

    Widget header = AxisLayout(
        axis: Axis.horizontal,
        crossAlignment: CrossAlignment.stretch,
        children: children);
    final EdgeInsets? padding = widget.column.headerPadding ?? theme.padding;
    if (padding != null) {
      header = Padding(padding: padding, child: header);
    }

    // if (widget.column.trailing != null) {
    //   header = MouseRegion(
    //       onEnter: (e) =>
    //           setState(() {
    //             _headerCellHovered = true;
    //           }),
    //       onExit: (e) =>
    //           setState(() {
    //             _headerCellHovered = false;
    //           }),
    //       child: header);
    // }

    if (widget.column.sortable) {
      header = MouseRegion(
          cursor: sortEnabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: sortEnabled ? _onHeaderSortPressed : null,
              child: header));
    }

    if (resizable) {
      header = MouseRegion(
          onEnter: (e) =>
              setState(() {
                _hovered = true;
              }),
          onExit: (e) =>
              setState(() {
                _hovered = false;
              }),
          child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: header),
        Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: _resizeWidget(context: context, resizing: resizing))
      ]));
    }
    return Semantics(
        readOnly: true,
        enabled: true,
        label: 'header ${widget.columnIndex}',
        child: ClipRect(key: ValueKey(_headerCellHovered), child: header));
  }

  Widget _textWidget(BuildContext context) {
    DaviThemeData theme = DaviTheme.of(context);
    Widget? text;
    if (widget.column.name != null) {
      text = Text(widget.column.name!,
          overflow: TextOverflow.ellipsis,
          style: widget.column.headerTextStyle ?? theme.headerCell.textStyle);
    }
    return Align(
        alignment: widget.column.headerAlignment ?? theme.headerCell.alignment,
        child: text);
  }

  Widget _resizeWidget({required BuildContext context, required resizing}) {
    DaviThemeData theme = DaviTheme.of(context);
    return GestureDetector(
        onHorizontalDragStart: _onResizeDragStart,
        onHorizontalDragEnd: _onResizeDragEnd,
        onHorizontalDragUpdate: _onResizeDragUpdate,
        behavior: HitTestBehavior.opaque,
        child: Container(
            width: theme.headerCell.resizeAreaWidth,
            color: _hovered || resizing
                ? theme.headerCell.resizeAreaHoverColor
                : null));
    // return MouseRegion(
    //     onEnter: (e) =>
    //         setState(() {
    //           _hovered = true;
    //         }),
    //     onExit: (e) =>
    //         setState(() {
    //           _hovered = false;
    //         }),
    //     cursor: SystemMouseCursors.resizeColumn,
    //     child: GestureDetector(
    //         onHorizontalDragStart: _onResizeDragStart,
    //         onHorizontalDragEnd: _onResizeDragEnd,
    //         onHorizontalDragUpdate: _onResizeDragUpdate,
    //         behavior: HitTestBehavior.opaque,
    //         child: Container(
    //             width: theme.headerCell.resizeAreaWidth,
    //             color: _headerCellHovered || resizing
    //                 ? theme.headerCell.resizeAreaHoverColor
    //                 : null)));
  }

  void _onResizeDragStart(DragStartDetails details) {
    final Offset pos = details.globalPosition;
    setState(() {
      _lastDragPos = pos.dx;
    });
    widget.model.columnInResizing = widget.column;
  }

  void _onResizeDragUpdate(DragUpdateDetails details) {
    final Offset pos = details.globalPosition;
    final double diff = pos.dx - _lastDragPos;
    if (widget.columnMinWidth != null &&
        widget.column.width + diff < widget.columnMinWidth!) {
      return;
    }
    widget.column.width += diff;
    _lastDragPos = pos.dx;
  }

  void _onResizeDragEnd(DragEndDetails details) {
    widget.model.columnInResizing = null;
  }

  void _onHeaderSortPressed() {
    List<DaviSort> sortList = SortUtil.newSortList(
        sortList: widget.model.sortList,
        multiSortEnabled: widget.model.multiSortEnabled,
        alwaysSorted: widget.model.alwaysSorted,
        columnIdToSort: widget.column.id);
    widget.model.sort(sortList);
  }
}
