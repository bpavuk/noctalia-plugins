import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    property var pluginApi: null

    // Local state
    property string editUrl: pluginApi?.pluginSettings?.haUrl ?? ""
    property string editToken: pluginApi?.pluginSettings?.haToken ?? ""

    spacing: Style.marginM

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.url_label") ?? "Home Assistant URL"
        placeholderText: pluginApi?.tr("settings.url_placeholder") ?? "http://homeassistant.local:8123"
        text: root.editUrl
        onTextChanged: root.editUrl = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.token_label") ?? "Long-Lived Access Token"
        placeholderText: pluginApi?.tr("settings.token_placeholder") ?? "Paste your token here"
        text: root.editToken
        onTextChanged: root.editToken = text
    }

    function saveSettings() {
        pluginApi.pluginSettings.haUrl = root.editUrl;
        pluginApi.pluginSettings.haToken = root.editToken;
        pluginApi.saveSettings();
    }
}
