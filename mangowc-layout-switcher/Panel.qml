import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen currentScreen
  readonly property var geometryPlaceholder: panelContainer

  // ===== DATA & MAPPING =====

  readonly property string panelMonitor: {
    if (currentScreen && currentScreen.name) return currentScreen.name
    if (pluginApi && pluginApi.currentScreen && pluginApi.currentScreen.name) return pluginApi.currentScreen.name
    if (pluginApi && pluginApi.mainInstance && pluginApi.mainInstance.availableMonitors.length > 0) {
      return pluginApi.mainInstance.availableMonitors[0]
    }
    return ""
  }
  
  readonly property var layouts: pluginApi?.mainInstance?.availableLayouts || []
  readonly property string activeLayout: (pluginApi?.mainInstance?.monitorLayouts ?? {})[root.selectedMonitor || root.panelMonitor] || ""

  // Matches BarWidget mapping and grouping
  readonly property var iconMap: ({
    "T":  "layout-sidebar",
    "M":  "rectangle",
    "S":  "carousel-horizontal",
    "G":  "layout-grid",
    "K":  "versions",
    "RT": "layout-sidebar-right",
    "CT": "layout-distribute-vertical",
    "TG": "layout-dashboard",
    "VT": "layout-rows",
    "VS": "carousel-vertical",
    "VG": "grid-dots",
    "VK": "chart-funnel"
  })

  property bool applyToAll: false
  property var selectedMonitors: []
  property real contentPreferredWidth: 500 * Style.uiScaleRatio 
  property real contentPreferredHeight: 420 * Style.uiScaleRatio

  function toggleMonitor(monitorName) {
    var idx = root.selectedMonitors.indexOf(monitorName)
    if (idx >= 0) {
      root.selectedMonitors = root.selectedMonitors.filter(m => m !== monitorName)
    } else {
      root.selectedMonitors = root.selectedMonitors.concat([monitorName])
    }
  }

  Component.onCompleted: {
    if (pluginApi?.mainInstance) {
      pluginApi.mainInstance.refresh()
    }
  }

  // ===== UI =====

  MouseArea {
    anchors.fill: parent
    onClicked: pluginApi.closePanel()

    Rectangle {
      id: panelContainer
      anchors.centerIn: parent
      width: root.contentPreferredWidth
      height: root.contentPreferredHeight
      
      color: Color.mSurface
      radius: Style.radiusL
      border.width: 1
      border.color: Color.mOutline
      
      MouseArea { anchors.fill: parent; onClicked: {} }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        // Header
        NText {
          text: "Switch Layout"
          pointSize: Style.fontSizeL
          font.weight: Font.Medium
          color: Color.mOnSurface
        }

        // Options
        RowLayout {
          Layout.fillWidth: true
          NText {
            text: "Apply to all monitors"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }
          Item { Layout.fillWidth: true }
          NToggle {
            checked: root.applyToAll
            onToggled: (checked) => { 
              root.applyToAll = checked 
              if (!checked && root.selectedMonitors.length === 0) {
                root.selectedMonitors = [root.panelMonitor]
              }
            }
          }
        }

        // Monitor Selector (shown when not applying to all)
        ColumnLayout {
          visible: !root.applyToAll
          Layout.fillWidth: true
          spacing: Style.marginS

          NText {
            text: "Select monitors"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            Repeater {
              model: pluginApi?.mainInstance?.availableMonitors || []
              
              delegate: Rectangle {
                id: monitorBtn
                Layout.preferredWidth: 100 * Style.uiScaleRatio
                Layout.preferredHeight: 50 * Style.uiScaleRatio
                
                property bool isSelected: root.selectedMonitors.indexOf(modelData) >= 0
                property string currentLayout: (pluginApi?.mainInstance?.monitorLayouts ?? {})[modelData] || ""
                
                color: isSelected ? Color.mPrimary : Color.mSurfaceVariant
                radius: Style.radiusM
                
                border.width: 2
                border.color: !isSelected ? Color.mOutline : Color.mPrimary
                
                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 2

                  NText {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData
                    color: isSelected ? Color.mOnPrimary : Color.mOnSurface
                    font.weight: Font.Medium
                    pointSize: Style.fontSizeXS
                    elide: Text.ElideRight
                  }

                  NText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.iconMap[currentLayout] ? "" : (currentLayout || "-")
                    color: isSelected ? Color.mOnPrimary : Color.mOnSurfaceVariant
                    opacity: 0.7
                    pointSize: Style.fontSizeXXS
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleMonitor(modelData)
                }
              }
            }
          }
        }

        NDivider { Layout.fillWidth: true }

        // Layout Grid
        GridLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          columns: 3
          rowSpacing: Style.marginS
          columnSpacing: Style.marginS

          Repeater {
            model: root.layouts
            
            delegate: Rectangle {
              id: layoutBtn
              Layout.fillWidth: true
              Layout.preferredHeight: 60 * Style.uiScaleRatio
              
              property bool isActive: {
                if (root.selectedMonitors.length === 0) {
                  return modelData.code === root.activeLayout
                } else if (root.selectedMonitors.length === 1) {
                  var mon = root.selectedMonitors[0]
                  var monLayout = (pluginApi?.mainInstance?.monitorLayouts ?? {})[mon] || ""
                  return modelData.code === monLayout
                }
                return false
              }
              property bool isHovered: false

              color: isActive ? Color.mPrimary : Color.mSurfaceVariant
              radius: Style.radiusM
              
              border.width: 2
              border.color: !isActive && isHovered ? Color.mPrimary : "transparent"
              
              Behavior on border.color { ColorAnimation { duration: 150 } }
              Behavior on color { ColorAnimation { duration: 150 } }

              ColumnLayout {
                anchors.centerIn: parent
                spacing: Style.marginXS
                width: parent.width - (Style.marginS * 2)

                // Icon
                NIcon {
                  Layout.alignment: Qt.AlignHCenter
                  icon: root.iconMap[modelData.code] || "layout-board"
                  pointSize: Style.fontSizeXL
                  color: layoutBtn.isActive ? Color.mOnPrimary : Color.mOnSurface
                }

                // Name
                NText {
                  Layout.alignment: Qt.AlignHCenter
                  Layout.fillWidth: true
                  horizontalAlignment: Text.AlignHCenter
                  
                  text: modelData.name
                  color: layoutBtn.isActive ? Color.mOnPrimary : Color.mOnSurface
                  opacity: layoutBtn.isActive ? 1.0 : 0.7
                  
                  font.weight: Font.Medium
                  pointSize: Style.fontSizeXS
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onEntered: layoutBtn.isHovered = true
                onExited: layoutBtn.isHovered = false
                
                onClicked: {
                  if (root.applyToAll) {
                    pluginApi.mainInstance.setLayoutGlobally(modelData.code)
                  } else if (root.selectedMonitors.length > 0) {
                    root.selectedMonitors.forEach(m => {
                      pluginApi.mainInstance.setLayout(m, modelData.code)
                    })
                  } else {
                    pluginApi.mainInstance.setLayout(root.panelMonitor, modelData.code)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
