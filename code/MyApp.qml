/* Copyright 2021 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "controls" as Controls

App{
    id: app
    width: 414
    height: 736
    function units(value) {
        return AppFramework.displayScaleFactor * value
    }
    property real scaleFactor: AppFramework.displayScaleFactor
    property real fontScale: app.isDesktop? 0.8 : 1
    readonly property real baseFontSize: fontScale * app.getProperty("baseFontSize", Qt.platform.os === "windows" ? 6 : 14)
    property bool isSmallScreen: (width || height) < units(400)
    property url  qmlfile
    property string sampleName
    property string descriptionText

    readonly property real iconSize: 5 * app.baseUnit

    readonly property color primaryColor: app.isDebug ? app.randomColor("primary") : app.getProperty("brandColor", "#166DB2")
    readonly property color backgroundColor: app.isDebug ? app.randomColor("background") : "#EFEFEF"
    readonly property color foregroundColor: app.isDebug ? app.randomColor("foreground") : "#22000000"
    readonly property color separatorColor: Qt.darker(app.backgroundColor, 1.2)
    readonly property color accentColor: Qt.lighter(app.primaryColor)
    readonly property color titleTextColor: app.backgroundColor
    readonly property color subTitleTextColor: Qt.darker(app.backgroundColor)
    readonly property color baseTextColor: Qt.darker(app.subTitleTextColor)
    readonly property color iconMaskColor: "transparent"
    readonly property color black_87: "#DE000000"
    readonly property color white_100: "#FFFFFFFF"
    readonly property color warning_color:"#D54550"

    property alias baseFontFamily: baseFontFamily.name
    FontLoader {
        id: baseFontFamily

        source: app.folder.fileUrl(app.getProperty("regularFontTTF", "./assets/fonts/Roboto-Regular.ttf"))
    }

    property alias titleFontFamily: titleFontFamily.name
    FontLoader {
        id: titleFontFamily
        source:  app.folder.fileUrl(app.getProperty("mediumFontTTF", "./assets/fonts/Roboto-Medium.ttf"))
    }

    Page{
        anchors.fill: parent
        header: ToolBar{
            id:header
            width: parent.width
            height: 50 * scaleFactor
            Material.background: "#8f499c"
            Controls.HeaderBar{}
        }

        // Add a Loader to load different samples.
        // The sample Qml files can be found in the Samples folder
        contentItem: Rectangle{
            id: loader
            anchors.top:header.bottom
            Loader{
                height: app.height - header.height
                width: app.width
                source: qmlfile
            }
        }
    }

    Controls.FloatActionButton{
        id:switchBtn
    }

    Controls.PopUpPage{
        id:popUp
        visible:false
    }

    Controls.DescriptionPage{
        id:descPage
        visible: false
    }

    //--------------------------------------------------------------------------

    function getProperty (name, fallback) {
        if (!fallback && typeof fallback !== "boolean") fallback = ""
        return app.info.propertyValue(name, fallback) //|| fallback
    }
}






