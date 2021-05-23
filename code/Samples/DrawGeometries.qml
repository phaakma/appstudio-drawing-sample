import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.10


Item {
    property real scaleFactor: AppFramework.displayScaleFactor

    MapView {
        id:mapView
        anchors.fill: parent

        property alias graphicsOverlay: graphicsOverlay

        Map{
            initUrl: "http://arcgis.com/sharing/rest/content/items/e25c55a23a574b2da421154259b569ae"
        }

        GraphicsOverlay {
            id: graphicsOverlay
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
                onClicked: {
                    console.log("take point")
                    drawingWidget.addPoint(drawingWidget.view.currentViewpointCenter.center)
                }
            }
        }





    }




    //::::::::::::::::::::: DRAWING WIDGET

    Item{
        id: drawingWidget


        property bool active: true
        property MapView view: mapView
        property bool viewReady: drawingWidget.view && drawingWidget.view.map && drawingWidget.view.map.loadStatus === Enums.LoadStatusLoaded
        property bool allSystemsGo: active && viewReady



        property int geometryType: Enums.GeometryTypePolygon

        onAllSystemsGoChanged: {
            if (allSystemsGo) resetGraphic();
        }

        onGeometryTypeChanged: {
            resetGraphic();
        }

        onActiveChanged: {
            if (active) resetGraphic();
        }

        anchors.fill: viewReady ? view : undefined

        Connections{
            id: connection
            target: drawingWidget.allSystemsGo && drawingWidget.active ? drawingWidget.view : null

            //:: Here we capture all the mouse activity from the view and redirect it to custom functions

            function onMousePressed(mouse){
                console.log("Mouse pressed: ", mouse)
            }

            function onMouseClicked(mouse){
                console.log(" mouse clicked...")
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

        function createBuilders(){

            if (!allSystemsGo) return

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

        property Symbol polygonSymbol:
            SimpleFillSymbol {
            style: Enums.SimpleFillSymbolStyleDiagonalCross
            color: Qt.rgba(0.0, 0.31, 0.0, 1)
            SimpleLineSymbol {
                style: Enums.SimpleLineSymbolStyleDash
                color: Qt.rgba(0.0, 0.0, 0.5, 1)
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

        property Symbol polylineSymbol

        property Symbol currentVertexSymbol


        function resetGraphic(){
            if (graphic && graphicsOverlay){
                graphicsOverlay.graphics.removeOne(graphic);
            }
            if (liveGraphic && graphicsOverlay){
                graphicsOverlay.graphics.removeOne(liveGraphic);
            }

            createBuilders();
            const geom = ArcGISRuntimeEnvironment.createObject("Polygon", {spatialReference: view.map.spatialReference});
            graphic = ArcGISRuntimeEnvironment.createObject("Graphic",{symbol: polygonSymbol, geometry: geom});
            graphicsOverlay.graphics.append(graphic);

            const geom2 = ArcGISRuntimeEnvironment.createObject("Polygon", {spatialReference: view.map.spatialReference});
            liveGraphic = ArcGISRuntimeEnvironment.createObject("Graphic",{symbol: liveSymbol, geometry: geom2});
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
            console.log("adding a point...", _point.x, _point.y)
            switch (geometryType){
            case Enums.GeometryTypePolygon:
                addPointToPolygon(_point, graphic, builder)

                if (liveBuilder.empty){
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                }
                else if(liveBuilder.parts.part(0).pointCount===1){
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                    updatePointInPolygon(_point, liveGraphic, liveBuilder, 0, 0);
                }
                else{
                    addPointToPolygon(_point, liveGraphic, liveBuilder);
                    updatePointInPolygon(_point, liveGraphic, liveBuilder, 0, liveBuilder.parts.part(0).pointCount-2);
                }



                break;
            }

        }

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
            part.addPoint(_point);
            _graphic.geometry = _builder.geometry;
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

        CrossHairs{
            visible: parent.allSystemsGo
            anchors.centerIn: parent
        }


    }








}

