part of '../core_widget_factory.dart';

const _kTagLi = 'li';
const _kTagOrderedList = 'ol';
const _kTagUnorderedList = 'ul';
const _kAttributeLiType = 'type';
const _kAttributeLiTypeAlphaLower = 'a';
const _kAttributeLiTypeAlphaUpper = 'A';
const _kAttributeLiTypeDecimal = '1';
const _kAttributeLiTypeRomanLower = 'i';
const _kAttributeLiTypeRomanUpper = 'I';
const _kAttributeOlReversed = 'reversed';
const _kAttributeOlStart = 'start';
const _kCssListStyleType = 'list-style-type';
const _kCssListStyleTypeAlphaLower = 'lower-alpha';
const _kCssListStyleTypeAlphaUpper = 'upper-alpha';
const _kCssListStyleTypeAlphaLatinLower = 'lower-latin';
const _kCssListStyleTypeAlphaLatinUpper = 'upper-latin';
const _kCssListStyleTypeCircle = 'circle';
const _kCssListStyleTypeDecimal = 'decimal';
const _kCssListStyleTypeDisc = 'disc';
const _kCssListStyleTypeRomanLower = 'lower-roman';
const _kCssListStyleTypeRomanUpper = 'upper-roman';
const _kCssListStyleTypeSquare = 'square';

const __kCssPaddingInlineStart = 'padding-inline-start';

class _TagLi {
  final WidgetFactory wf;

  BuildOp _buildOp;
  BuildOp _liOp;

  _TagLi(this.wf);

  BuildOp get buildOp {
    _buildOp ??= BuildOp(
      defaultStyles: (meta, e) {
        final p = meta.parents?.where((op) => op == _buildOp)?.length ?? 0;

        final styles = [
          __kCssPaddingInlineStart,
          '2.5em',
          _kCssListStyleType,
          e.localName == _kTagOrderedList
              ? (e.attributes.containsKey(_kAttributeLiType)
                      ? _LiInput.listStyleTypeFromAttributeType(
                          e.attributes[_kAttributeLiType])
                      : null) ??
                  _kCssListStyleTypeDecimal
              : p == 0
                  ? _kCssListStyleTypeDisc
                  : p == 1
                      ? _kCssListStyleTypeCircle
                      : _kCssListStyleTypeSquare,
        ];

        if (p == 0) styles.addAll([_kCssMargin, '1em 0']);

        return styles;
      },
      onChild: (meta, e) =>
          e.localName == _kTagLi ? lazySet(meta, buildOp: liOp) : meta,
      onWidgets: (meta, widgets) => _buildList(meta, widgets),
    );
    return _buildOp;
  }

  BuildOp get liOp {
    _liOp ??= BuildOp(
      onWidgets: (meta, widgets) =>
          widgets.length == 1 && widgets.first is _LiPlaceholder
              ? widgets
              : [_placeholder(widgets, meta)],
    );
    return _liOp;
  }

  Iterable<Widget> _build(BuildContext c, Iterable<Widget> ws, _LiInput i) {
    final listMeta = i.listMeta;
    final paddingCss = i.paddingInlineStart ?? listMeta.paddingInlineStart;
    final paddingPx = paddingCss.getValue(c, i.meta.tsb);
    final padding = Directionality.of(c) == TextDirection.ltr
        ? EdgeInsets.only(left: paddingPx)
        : EdgeInsets.only(right: paddingPx);
    final style = i.meta.tsb.build(c);
    final listStyleType = i.listStyleType ?? listMeta.listStyleType;
    final markerIndex = listMeta.markerReversed
        ? (listMeta.markerStart ?? listMeta.markerCount) - i.markerIndex
        : (listMeta.markerStart ?? 1) + i.markerIndex;
    final markerText = wf.getListStyleMarker(listStyleType, markerIndex);

    return [
      Stack(children: <Widget>[
        wf.buildPadding(wf.buildColumn(ws), padding) ?? widget0,
        _buildMarker(c, style, markerText, paddingPx),
      ]),
    ];
  }

  Iterable<Widget> _buildList(NodeMetadata meta, Iterable<Widget> children) {
    final listMeta = _ListMetadata();
    for (final style in meta?.styles) {
      switch (style.key) {
        case _kCssListStyleType:
          listMeta.listStyleType = style.value;
          break;
        case __kCssPaddingInlineStart:
          final parsed = wf.parseCssLength(style.value);
          if (parsed != null) listMeta.paddingInlineStart = parsed;
      }
    }

    final a = meta.domElement.attributes;
    if (a.containsKey(_kAttributeOlReversed)) listMeta.markerReversed = true;
    if (a.containsKey(_kAttributeOlStart)) {
      listMeta.markerStart = int.tryParse(a[_kAttributeOlStart]);
    }

    for (final child in children) {
      if (!(child is _LiPlaceholder)) continue;
      final item = child as _LiPlaceholder;

      if (item.input.listMeta != null) {
        item.wrapWith((c, widgets, __) {
          final paddingPx = listMeta.paddingInlineStart.getValue(c, meta.tsb);
          final padding = Directionality.of(c) == TextDirection.ltr
              ? EdgeInsets.only(left: paddingPx)
              : EdgeInsets.only(right: paddingPx);

          return widgets.map((widget) => wf.buildPadding(widget, padding));
        });
        continue;
      }

      item.input.listMeta = listMeta;
      item.input.markerIndex = listMeta.markerCount++;
    }

    return children;
  }

  Widget _buildMarker(BuildContext c, TextStyle s, String t, double l) {
    final isLtr = Directionality.of(c) == TextDirection.ltr;
    final isRtl = !isLtr;
    return Positioned(
      left: isLtr ? 0.0 : null,
      right: isRtl ? 0.0 : null,
      top: 0.0,
      width: l * .75,
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.clip,
        text: TextSpan(style: s, text: t),
        textAlign: isLtr ? TextAlign.right : TextAlign.left,
        textScaleFactor: MediaQuery.of(c).textScaleFactor,
      ),
    );
  }

  _LiPlaceholder _placeholder(Iterable<Widget> children, NodeMetadata meta) {
    final a = meta.domElement.attributes;
    String listStyleType = a.containsKey(_kAttributeLiType)
        ? _LiInput.listStyleTypeFromAttributeType(a[_kAttributeLiType])
        : null;
    CssLength paddingInlineStart;
    for (final style in meta.styles) {
      switch (style.key) {
        case _kCssListStyleType:
          listStyleType = style.value;
          break;
        case __kCssPaddingInlineStart:
          final parsed = wf.parseCssLength(style.value);
          if (parsed != null) paddingInlineStart = parsed;
      }
    }

    return _LiPlaceholder(
      this,
      children,
      _LiInput()
        ..listStyleType = listStyleType
        ..meta = meta
        ..paddingInlineStart = paddingInlineStart,
    );
  }
}

class _LiPlaceholder extends WidgetPlaceholder<_LiInput> {
  final _LiInput input;

  _LiPlaceholder(
    _TagLi self,
    Iterable<Widget> children,
    this.input,
  ) : super(
          builder: self._build,
          children: children,
          input: input,
        );
}

class _LiInput {
  _ListMetadata listMeta;
  String listStyleType;
  int markerIndex;
  NodeMetadata meta;
  CssLength paddingInlineStart;

  static String listStyleTypeFromAttributeType(String type) {
    switch (type) {
      case _kAttributeLiTypeAlphaLower:
        return _kCssListStyleTypeAlphaLower;
      case _kAttributeLiTypeAlphaUpper:
        return _kCssListStyleTypeAlphaUpper;
      case _kAttributeLiTypeDecimal:
        return _kCssListStyleTypeDecimal;
      case _kAttributeLiTypeRomanLower:
        return _kCssListStyleTypeRomanLower;
      case _kAttributeLiTypeRomanUpper:
        return _kCssListStyleTypeRomanUpper;
    }

    return null;
  }
}

class _ListMetadata {
  String listStyleType = _kCssListStyleTypeDisc;
  int markerCount = 0;
  bool markerReversed = false;
  int markerStart;
  CssLength paddingInlineStart;
}
