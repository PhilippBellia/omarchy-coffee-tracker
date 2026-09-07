import QtQuick
import qs.Commons
import qs.Ui

// A NumberField whose label cannot widen the cell it sits in.
//
// NumberField renders its own label as an unbounded Text, so the Column's
// implicitWidth follows the label rather than the field. In a Grid that is
// enough to break the panel: the longest label decides the column width,
// the Grid grows past the width it was given, and the settings column next
// to it ends up underneath. "Residual caffeine (mg)" did exactly that to
// the extraction sliders, while the German "Restkoffein (mg)" fit and hid
// the problem.
//
// So the label is drawn here instead — clamped to the cell and elided —
// and NumberField is left with the field alone. The layout is then a
// property of the panel rather than of whichever translation is loaded.
Column {
  id: root

  property string label: ""
  property int value: 0
  property int from: 0
  property int to: 100
  property int stepSize: 1
  property real fieldWidth: Style.spacing.numberFieldWidth
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  // The SpinBox, for callers that need to know whether it has focus.
  property alias field: number.field

  signal modified(int value)

  width: fieldWidth
  spacing: Style.spacing.md

  Text {
    width: root.fieldWidth
    text: root.label
    elide: Text.ElideRight
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  NumberField {
    id: number
    label: ""
    from: root.from
    to: root.to
    stepSize: root.stepSize
    value: root.value
    fieldWidth: root.fieldWidth
    foreground: root.foreground
    fontFamily: root.fontFamily
    onModified: function(v) { root.modified(v) }
  }
}
