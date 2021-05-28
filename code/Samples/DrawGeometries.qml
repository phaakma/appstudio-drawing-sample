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

    Rectangle{
        id: controlIcons

        width: 100 * scaleFactor
        height: 200 * scaleFactor
        radius: 5 * scaleFactor

        anchors{
            right: parent.right
            top: parent.top
            rightMargin: 15 * scaleFactor
            topMargin:  15 * scaleFactor
        }

        Column{
            width: parent.width

            Switch{
                enabled: drawingWidget.viewReady
                width: parent.width
                text: "Draw"
                font {
                    pointSize: app.getProperty(app.baseFontSize * 0.4, 14)
                    family:"%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                }
                checked: drawingWidget.active
                onCheckedChanged: {
                    drawingWidget.active = checked;
                }
            }

            Button{
                enabled: drawingWidget.allSystemsGo
                width: 50 * scaleFactor
                anchors.horizontalCenter: parent.horizontalCenter
                text: "+"
                font {
                    pointSize: app.getProperty(app.baseFontSize * 0.4, 14)
                    family:"%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                }
                onClicked: {
                    drawingWidget.addPoint(drawingWidget.view.currentViewpointCenter.center) ;
                }
            }

            Button{
                enabled: drawingWidget.allSystemsGo
                width: 50 * scaleFactor
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Clear"
                font {
                    pointSize: app.getProperty(app.baseFontSize * 0.1, 5)
                    family:"%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                }
                onClicked: {
                    drawingWidget.resetGraphics() ;
                }
            }
        }
    }


    //::::::::::::::::::::: DRAWING WIDGET

    Item{
        id: drawingWidget

        property bool active: false
        property MapView view: mapView
        property bool viewReady: drawingWidget.view && drawingWidget.view.map && drawingWidget.view.map.loadStatus === Enums.LoadStatusLoaded
        property bool allSystemsGo: active && viewReady

        property int geometryType: Enums.GeometryTypePolygon

        onAllSystemsGoChanged: {
            console.log("All allSystemsGo changed to: ", allSystemsGo)
            if (allSystemsGo) resetGraphics();
        }

        onGeometryTypeChanged: {
            resetGraphics();
        }

        onActiveChanged: {
            if (active && allSystemsGo){
                console.log("active and all systems go...")
                resetGraphics();
            }
            else if (!active){ reset(); }
        }

        anchors.fill: viewReady ? view : undefined

        Connections{
            id: connection
            target: drawingWidget.allSystemsGo && drawingWidget.active ? drawingWidget.view : null

            //:: Here we capture all the mouse activity from the view and redirect it to custom functions

            function onMousePressed(mouse){
            }

            function onMouseClicked(mouse){
            }

            function onMouseDoubleClicked(mouse){
            }

            function onMousePositionChanged(mouse){
            }

            function onMousePressedAndHeld(mouse){
            }

            function onMouseReleased(mouse){
            }

            function onMouseWheelChanged(wheel){
            }

            function onVisibleAreaChanged(){
                drawingWidget.updateLiveGraphic();
            }
        }

        property GraphicsOverlay graphicsOverlay: mapView.graphicsOverlay
        property Graphic graphic
        property Graphic liveGraphic
        property GeometryBuilder builder
        property GeometryBuilder liveBuilder
        property int currentPartIndex
        property int currentVertexIndex

        function reset(){
            view.graphicsOverlay.graphics.clear();
        }

        function createBuilders(){

            console.log("Request to create builders...")

            if (!allSystemsGo) return

            console.log("All systems are go so we are creating the builders...")

            const props = {spatialReference: view.map.spatialReference};

            switch (geometryType){
            case Enums.GeometryTypePolygon:
                builder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", props);
                liveBuilder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", props);
                break;
            case Enums.GeometryTypePolyline:
                builder = ArcGISRuntimeEnvironment.createObject("PolylineBuilder", props);
                break;
            case Enums.GeometryTypePoint:
                builder = ArcGISRuntimeEnvironment.createObject("PointBuilder", props);
                break;
            case Enums.GeometryTypeMultipoint:
                builder = ArcGISRuntimeEnvironment.createObject("MultipointBuilder", props);
                break;
            case Enums.GeometryTypeEnvelope:
                builder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder", props);
                break;
            }

            currentPartIndex = 0;
            currentVertexIndex = 0;
        }

        property var polygonSymbol:
            SimpleFillSymbol {
            style: Enums.SimpleFillSymbolStyleNull
            color: "pink"
            SimpleLineSymbol {
                style: Enums.SimpleLineSymbolStyleDash
                color: "red"
                width: 1
                antiAlias: true
            }
        }

        property Symbol liveSymbol:
            SimpleFillSymbol {
            style: Enums.SimpleFillSymbolStyleNull
            color: "pink"
            SimpleLineSymbol {
                style: Enums.SimpleLineSymbolStyleDash
                color: "red"
                width: 1
                antiAlias: true
            }
        }

        property Symbol polylineSymbol:
            SimpleLineSymbol {
            width: 1
            color: "black"
        }

        property Symbol currentVertexSymbol:
            SimpleMarkerSymbol {
            color: "teal"
            size: 34.0
            style: Enums.SimpleMarkerSymbolStyleCircle

            // declare the symbol's outline
            SimpleLineSymbol {
                width: 1
                color: "black"
            }
        }

        function resetGraphics(){
            if (graphic && graphicsOverlay){
                console.log("removing the graphic")
                graphicsOverlay.graphics.removeOne(graphic);
            }
            if (liveGraphic && graphicsOverlay){
                console.log("removing the live graphic...")
                graphicsOverlay.graphics.removeOne(liveGraphic);
            }

            createBuilders();

            const customSymbolJson = app.folder.readJsonFile("./Samples/customSymbol.json")
            const sym = ArcGISRuntimeEnvironment.createObject("MultilayerPolygonSymbol", {json: customSymbolJson});

            graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: sym, geometry: builder.geometry});
            graphicsOverlay.graphics.append(graphic);

            liveGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: liveSymbol, geometry: builder.geometry, zIndex: 10});
            graphicsOverlay.graphics.append(liveGraphic);
        }

        function updateLiveGraphic(){
            if (!allSystemsGo || !liveGraphic || !liveGraphic.geometry || liveGraphic.geometry.empty) return;
            switch (geometryType){
            case Enums.GeometryTypePolygon:
                updatePointInPolygon(drawingWidget.view.currentViewpointCenter.center, liveGraphic, liveBuilder)
                break;
            }
        }

        function addPoint(_point){
            switch (geometryType){
            case Enums.GeometryTypePolygon:
                addPointToPolygon(_point, graphic, builder);

                if (liveBuilder.empty){
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                }
                else{
                    liveBuilder.geometry = builder.geometry;
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                    updatePointInPolygon(_point, liveGraphic, liveBuilder, 0, liveBuilder.parts.part(0).pointCount-2);
                }
                break;
            }

        }

        //:::::::::::::::POLYGON FUNCTIONS:::::::::::::::::::::::::::::

        function addPointToPolygon(_point, _graphic, _builder){
            let part;
            if (_builder.parts.empty){
                part = ArcGISRuntimeEnvironment.createObject("Part");
                part.spatialReference = _builder.spatialReference;
                _builder.parts.addPart(part);
            }
            else if (currentPartIndex > _builder.parts.size-1){
                currentPartIndex = _builder.parts.size-1;
                part = _builder.parts.part(currentPartIndex);
            }
            else{
                part = _builder.parts.part(currentPartIndex);
            }
            part.addPointXY(_point.x, _point.y);
            if (_builder.sketchValid) _graphic.geometry = _builder.geometry;
        }

        function updatePointInPolygon(_point, _graphic, _builder, _partIndex, _pointIndex){
            if (!_point || !_graphic || !_builder){
                console.error("Missing arguments to updatePointInPolygon function.")
                return
            }

            //default to the last part and point if not specified
            _partIndex = _partIndex || _builder.parts.size-1;
            _pointIndex = _pointIndex ||  _builder.parts.part(_partIndex).pointCount-1;

            _builder.parts.part(_partIndex).setPoint(_pointIndex, _point);
            _graphic.geometry = _builder.geometry;
        }


        //:::::::::::::::POLYLINE FUNCTIONS:::::::::::::::::::::::::::::

        function addPointToPolyline(_point, _graphic, _builder){
            _builder.addPoint(_point)
            if (_builder.sketchValid) _graphic.geometry = _builder.geometry;
        }

        Rectangle{
            id: crossHairs

            visible: parent.allSystemsGo
            anchors.centerIn: parent

            property real lineThickness: 2*scaleFactor

            color: "transparent"
            border.color: "white"
            border.width: lineThickness * 2
            width: (50 * scaleFactor) + (border.width / 2)
            height: width
            radius: width * 0.5
            opacity: 0.5

            Rectangle{
                anchors.centerIn: parent
                color: "transparent"
                border.color: "darkgrey"
                border.width: parent.lineThickness
                width: (50 * scaleFactor)
                height: width
                radius: width * 0.5
                opacity: 0.8

            }

            Rectangle{
                anchors.centerIn: parent
                width: parent.width * 1.25
                height: parent.lineThickness
                color: "lightgrey"
                opacity: 0.9
            }

            Rectangle{
                anchors.centerIn: parent
                width: parent.lineThickness
                height: parent.width * 1.4
                color: "lightgrey"
                opacity: 0.9
            }
        }
    }





}

