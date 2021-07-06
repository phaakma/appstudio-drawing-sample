import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.10

import "../controls" as Controls


Item {
    id: root
    property real scaleFactor: AppFramework.displayScaleFactor

    MapView {
        id:mapView
        anchors.fill: parent

        property alias graphicsOverlay: graphicsOverlay

        Map{
            initUrl: "http://arcgis.com/sharing/rest/content/items/2fdeafe70afc48ac8629dc61d1351130" //nz web map: nztm
        }

        GraphicsOverlay {
            id: graphicsOverlay
        }
    }

    Controls.BookmarksView {
        id: bookmarksView
        visible: false
        Connections{
            target: app
            function onSomethingHappened(happening){
                bookmarksView.visible = !bookmarksView.visible;
            }
        }

        anchors{
            left: parent.left
            top: parent.top
        }

        width: 200 * scaleFactor
        height: 600 * scaleFactor

        model: mapView.map.bookmarks
        onBookmarkSelected: {
            mapView.setViewpointWithAnimationCurve(mapView.map.bookmarks.get(index).viewpoint, 2.0, Enums.AnimationCurveEaseInOutCubic)
        }
    }


    //::::::::::::::::::::: DRAWING WIDGET

    DrawingWidget{
        id: drawingWidget
        view: mapView

    }



}

