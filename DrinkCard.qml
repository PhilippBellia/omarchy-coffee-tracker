import QtQuick
import qs.Commons
import qs.Ui

// One tap-to-log drink: glyph, name, and what it costs you in millilitres
// and milligrams. Used by all three rosters — coffee, HOLY, cans — because
// from the panel's side they are the same gesture, and only the arithmetic
// behind the number differs.
BorderSurface {
  id: root

  property string iconText: ""
  property string title: ""
  property string subtitle: ""
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property bool hot: mouse.containsMouse

  signal clicked()

  implicitHeight: row.implicitHeight + Style.space(18)
  height: implicitHeight
  radius: Style.cornerRadius
  color: mouse.pressed
    ? Style.pressedFillFor(foreground, accent)
    : Style.controlFill(false, hot, foreground, accent)
  borderSpec: Border.flat(Style.controlBorder(false, hot, foreground, accent),
    Style.controlBorderWidth(false, hot))

  Behavior on color { ColorAnimation { duration: 120 } }

  Row {
    id: row
    anchors.left: parent.left
    anchors.leftMargin: Style.space(12)
    anchors.right: parent.right
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(10)

    Text {
      id: glyph
      anchors.verticalCenter: parent.verticalCenter
      text: root.iconText
      color: root.hot ? Style.selectedStateColor(root.foreground, root.accent) : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.iconLarge
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - glyph.width - parent.spacing
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: root.title
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: root.subtitle
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
