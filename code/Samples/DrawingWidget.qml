import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.10


Item{
    id: drawingWidget

    property bool active: false
    property MapView view
    property bool viewReady: drawingWidget.view && drawingWidget.view.map && drawingWidget.view.map.loadStatus === Enums.LoadStatusLoaded
    property bool allSystemsGo: active && viewReady

    property int geometryType: Enums.GeometryTypePolygon

    //to customize the UI of the drawing controls, either either the default component
    //in this file or override this property with a custom controls object.
    property var drawingControls: defaultControls.createObject(view)

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

    onDrawingControlsChanged: {
        //position the controls
        drawingControls.anchors.right = drawingWidget.view.right;
        drawingControls.anchors.top = drawingWidget.view.top;
        drawingControls.anchors.rightMargin = 15 * scaleFactor
        drawingControls.anchors.topMargin = 15 * scaleFactor
    }

    anchors.fill: viewReady ? view : undefined

    Connections{
        id: connection
        target: drawingWidget.allSystemsGo && drawingWidget.active ? drawingWidget.view : null

        //:: Here we capture all the mouse activity from the view and redirect it to custom functions

        function onMousePressed(mouse){
        }

        function onMouseClicked(mouse){
            drawingWidget.setCurrentVertex(mouse)
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
            drawingWidget.setNextPointLineGeometry(drawingWidget.view.currentViewpointCenter.center);
        }
    }

    property GraphicsOverlay graphicsOverlay: mapView.graphicsOverlay
    property Graphic graphic
    property Graphic nextPointLineGraphic
    property Graphic currentVertexGraphic
    property Graphic verticesGraphic
    property int currentPartIndex
    property int currentPointIndex

    property var polygonSymbol:
        SimpleFillSymbol {
        style: Enums.SimpleFillSymbolStyleSolid
        color: Qt.rgba(200,200,200,0.2)
        SimpleLineSymbol {
            style: Enums.SimpleLineSymbolStyleSolid
            color: "darkgrey"
            width: 3
            antiAlias: true
        }
    }

    property Symbol nextPointLineSymbol:
        SimpleLineSymbol {
        style: Enums.SimpleLineSymbolStyleShortDash
        color: "lightgrey"
        width: 3
        antiAlias: true
    }

    property Symbol polylineSymbol:
        SimpleLineSymbol {
        width: 1
        color: "black"
    }

    property Symbol verticesSymbol:
        SimpleMarkerSymbol {
        color: "darkgrey"
        size: 5 * scaleFactor
        style: Enums.SimpleMarkerSymbolStyleCircle

        SimpleLineSymbol {
            width: 1
            color: "white"
        }
    }

    property Symbol currentVertexSymbol:
        SimpleMarkerSymbol {
        color: "white"
        size: 5 * scaleFactor
        style: Enums.SimpleMarkerSymbolStyleCircle

        // declare the symbol's outline
        SimpleLineSymbol {
            width: 1
            color: "darkgrey"
        }
    }

    function reset(){
        resetGraphics();
        undoList = [];
        undoMarker = 0;
    }

    function createBuilder(sourceGeometry, geomType, sr){
        geomType = sourceGeometry && sourceGeometry.geometryType ? sourceGeometry.geometryType : geomType;

        if (!geomType >""){
            console.error("Unable to create builder, couldn't establish the geometry type.")
            console.log("Start trace stack..........................")
            console.trace();
            console.log("::::::::::::::::::::::::::: finish trace..........")
            return
        }

        sr = sourceGeometry && sourceGeometry.spatialReference ? sourceGeometry.spatialReference : view.map.spatialReference;

        let builderString = "";

        switch (geomType){
        case Enums.GeometryTypePolygon:
            builderString = "PolygonBuilder";
            break;
        case Enums.GeometryTypePolyline:
            builderString = "PolylineBuilder";
            break;
        case Enums.GeometryTypePoint:
            builderString = "PointBuilder";
            break;
        case Enums.GeometryTypeMultipoint:
            builderString = "MultipointBuilder";
            break;
        case Enums.GeometryTypeEnvelope:
            builderString = "EnvelopeBuilder";
            break;
        }

        //NOTE: setting the geometry in the createObject doesn't seem to work, hence the need to first
        //create the builder then assign the geometry to it.
        const _builder = ArcGISRuntimeEnvironment.createObject(builderString, {spatialReference: sr});
        if (sourceGeometry) _builder.geometry = sourceGeometry;
        if ( (_builder.geometryBuilderType === Enums.GeometryBuilderTypePolygonBuilder || _builder.geometryBuilderType === Enums.GeometryBuilderTypePolylineBuilder)
                && _builder.parts.empty){
            const part = ArcGISRuntimeEnvironment.createObject("Part");
            part.spatialReference = _builder.spatialReference;
            _builder.parts.addPart(part);
        }
        return _builder;
    }

    function resetGraphics(){
        graphicsOverlay.graphics.clear();

        graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: polygonSymbol, zIndex: 0});
        graphicsOverlay.graphics.append(graphic);

        nextPointLineGraphic= ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: nextPointLineSymbol, zIndex: 10});
        graphicsOverlay.graphics.append(nextPointLineGraphic);

        verticesGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: verticesSymbol, zIndex: 20});
        graphicsOverlay.graphics.append(verticesGraphic);

        currentVertexGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: currentVertexSymbol, zIndex: 30});
        graphicsOverlay.graphics.append(currentVertexGraphic);

        currentPartIndex = 0;
        currentPointIndex = -1;
    }

    function addPoint(_point){
        switch (geometryType){
        case Enums.GeometryTypePolygon:

            // console.log("adding Point, currentPartIndex: ", currentPartIndex, "currentPointIndex: ", currentPointIndex)

            //this is the graphic for the actual feature being edited
            addPointToPolygon(_point, graphic, currentPartIndex, currentPointIndex);

            //this is the graphic for the multipoint that symbolizes each vertex (except the current one).
            //add a point
            addPointToMultiPoint(_point, verticesGraphic)

            //this is the graphic for the current vertex
            //replace the current vertex geometry with this point
            currentVertexGraphic.geometry = _point;

            currentPointIndex += 1;

            //this is for the line that tracks as the map pans.
            setNextPointLineGeometry(_point);
            break;
        }
        addToUndoList();

    }

    function deleteCurrentPoint(){
        switch(geometryType){
        case Enums.GeometryTypePolygon:
            //delete the point from the main graphic
            const pointIndexes = getNextAndPreviousPointIndexes(graphic.geometry, currentPointIndex, currentPartIndex);
            deletePointInPolygon(graphic, currentPartIndex, currentPointIndex);
            //update the vertex multipoint graphic
            deletePointInMultiPoint(currentPointIndex, verticesGraphic);

            currentPointIndex = pointIndexes.previousPointIndex;
            //update the current vertex geometry to the new current vertex
            currentVertexGraphic.geometry = graphic.geometry.parts.part(currentPartIndex).point(currentPointIndex);
            //update the live tracking graphic
            setNextPointLineGeometry(drawingWidget.view.currentViewpointCenter.center)

            break;
        }
        addToUndoList();
    }

    function setNextPointLineGeometry(_point){

        if (!_point || !graphic.geometry || graphic.geometry.empty) return;

        const _builder = createBuilder(undefined, Enums.GeometryTypePolyline);

        if (!nextPointLineGraphic.geometry || nextPointLineGraphic.geometry.empty){
            _builder.addPoint(_point);
            _builder.addPoint(_point);
            _builder.addPoint(_point);
        }
        else{
            const pointIndexes = getNextAndPreviousPointIndexes(graphic.geometry, currentPointIndex, currentPartIndex);
            if (pointIndexes) {

                //NOTE:
                //For some reason, under certain circumstances, trying to use
                //graphic.geometry.parts.part(currentPartIndex).point(pointIndexes.currentPointIndex)
                //here to set the start of the line to the current vertex location actually returns the previous vertex.
                //Originally I was assigning the line geom back to the builder and using setPoint
                //To replicate, start a new polygon drawing, add 3 points, then select vertex #1, add a point, then select the last vertex
                //and pan the map.
                //The workaround is to use the geometry of the currentVertexGraphic which seems to work.
                //I couldn't figure out why it would work the other way, as it works otherwise.

                _builder.addPoint(currentVertexGraphic.geometry);
                _builder.addPoint(_point);
                _builder.addPoint(graphic.geometry.parts.part(currentPartIndex).point(pointIndexes.nextPointIndex));
            }
        }

        nextPointLineGraphic.geometry =  _builder.geometry;
    }

    function getNextAndPreviousPointIndexes(_geometry, _currentPointIndex, _currentPartIndex){
        if (!_geometry || _geometry.empty || !String(_currentPointIndex) || !String(_currentPartIndex) || _currentPartIndex < 0 || _currentPointIndex < 0){
            return;
        }

        let nextPointIndex = _currentPointIndex + 1;
        const part = _geometry.parts.part(_currentPartIndex);
        if (nextPointIndex >= part.pointCount){
            nextPointIndex = 0;
        }
        let previousPointIndex = currentPointIndex -1;
        if (previousPointIndex < 0 && part.pointCount > 1){
            previousPointIndex = part.pointCount-1
        }
        else if (previousPointIndex < 0){
            previousPointIndex = 0;
        }

        const pointIndexes = {currentPointIndex: currentPointIndex, nextPointIndex: nextPointIndex, previousPointIndex: previousPointIndex};
        return pointIndexes
    }



    //:::::::::::::::POLYGON FUNCTIONS:::::::::::::::::::::::::::::

    function addPointToPolygon(_point, _graphic, _partIndex, _pointIndex){
        let _builder = createBuilder(_graphic.geometry, Enums.GeometryTypePolygon);
        const part = _builder.parts.part(_partIndex);
        if (!_builder.sketchValid){
            part.addPoint(_point)
        }else{
            part.insertPoint(_pointIndex+1, _point);
        }
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

    function deletePointInPolygon(_graphic, _partIndex, _pointIndex){
        const _builder = createBuilder(_graphic.geometry, Enums.GeometryTypePolygon);
        _builder.parts.part(_partIndex).removePoint(_pointIndex);
        _graphic.geometry = _builder.geometry;
    }


    //:::::::::::::::POLYLINE FUNCTIONS:::::::::::::::::::::::::::::

    function addPointToPolyline(_point, _graphic, _builder){
        _builder.addPoint(_point)
        if (_builder.sketchValid) _graphic.geometry = _builder.geometry;
    }



    //:::::::::::::::MULTIPOINT FUNCTIONS:::::::::::::::::::::::::::::

    function addPointToMultiPoint(_point, _graphic){
        const _builder = createBuilder(_graphic.geometry, Enums.GeometryTypeMultipoint);
        _builder.points.addPoint(_point);
        _graphic.geometry = _builder.geometry;
    }

    function deletePointInMultiPoint(_pointIndex, _graphic){
        const _builder = createBuilder(_graphic.geometry, Enums.GeometryTypeMultipoint);
        _builder.points.removePoint(_pointIndex);
        _graphic.geometry = _builder.geometry;
    }


    //::::::::::::::::::UNDO FUNCTIONS:::::::::::::::::::::::::::::::::::::::::::

    property var undoList: []
    property int undoMarker: 0

    function undo(){
        if (undoMarker <= 1){
            return;
        }
        undoMarker -= 1;
        const snapshot = undoList[undoMarker-1];

        let mainGeometry, verticesGeometry, currentVertexGeometry;
        switch (drawingWidget.geometryType){
        case Enums.GeometryTypePolygon:
            graphic.geometry = snapshot.geometry;
            verticesGraphic.geometry  = snapshot.verticesGeometry;
            currentVertexGraphic.geometry = snapshot.currentVertexGeometry;
            currentPartIndex = snapshot.currentPartIndex;
            currentPointIndex = snapshot.currentPointIndex;
            setNextPointLineGeometry(drawingWidget.view.currentViewpointCenter.center);
            break;
        }
    }

    function redo(){
        if (undoMarker >= undoList.length){
            return;
        }
        const snapshot = undoList[undoMarker];
        undoMarker += 1;

        let mainGeometry, verticesGeometry, currentVertexGeometry;
        switch (drawingWidget.geometryType){
        case Enums.GeometryTypePolygon:
            graphic.geometry = snapshot.geometry;
            verticesGraphic.geometry  = snapshot.verticesGeometry;
            currentVertexGraphic.geometry = snapshot.currentVertexGeometry;
            currentPartIndex = snapshot.currentPartIndex;
            currentPointIndex = snapshot.currentPointIndex;
            setNextPointLineGeometry(drawingWidget.view.currentViewpointCenter.center);
            break;
        }
    }

    function addToUndoList(){
        const snapshot = {
            geometry: graphic.geometry,
            verticesGeometry: verticesGraphic.geometry,
            currentVertexGeometry: currentVertexGraphic.geometry,
            currentPartIndex: currentPartIndex,
            currentPointIndex: currentPointIndex
        }
        undoList = undoList.slice(0, undoMarker);
        undoMarker += 1;
        undoList.push(snapshot);
    }

    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    function setCurrentVertex(mouse){
        const nearestVertex = GeometryEngine.nearestVertex(graphic.geometry, mouse.mapPoint);
        if (!nearestVertex) return

        const tolerance = 50;

        if (nearestVertex.pointIndex >= 0 && nearestVertex.distance < tolerance){
            currentPointIndex = nearestVertex.pointIndex;
            currentVertexGraphic.geometry = nearestVertex.coordinate;
            setNextPointLineGeometry(drawingWidget.view.currentViewpointCenter.center);
        }
    }



    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

    Rectangle{
        id: crossHairs

        parent: drawingWidget.view ? drawingWidget.view : drawingWidget

        visible: drawingWidget.allSystemsGo
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

    Component{
        id: defaultControls

        Rectangle{
            width: 100 * scaleFactor
            height: 200 * scaleFactor
            radius: 5 * scaleFactor

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
                    text: "-"
                    font {
                        pointSize: app.getProperty(app.baseFontSize * 0.4, 14)
                        family:"%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    }
                    onClicked: {
                        drawingWidget.deleteCurrentPoint() ;
                    }
                }

                Button{
                    enabled: drawingWidget.allSystemsGo
                    width: 50 * scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "UNDO"
                    font {
                        pointSize: app.baseFontSize * 0.2
                        family:"%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    }
                    onClicked: {
                        drawingWidget.undo() ;
                    }
                }

                Button{
                    enabled: drawingWidget.allSystemsGo
                    width: 50 * scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "REDO"
                    font {
                        pointSize: app.baseFontSize * 0.2
                        family:"%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    }
                    onClicked: {
                        drawingWidget.redo() ;
                    }
                }

                Button{
                    enabled: drawingWidget.allSystemsGo
                    width: 50 * scaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Clear"
                    font {
                        pointSize: app.baseFontSize * 0.2
                        family:"%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    }
                    onClicked: {
                        drawingWidget.reset() ;
                    }
                }
            }
        }


    }

    function log(message, level){
        let trace = false;

        console.log("MESSAGE:::::::::::::::::::")
        switch (level.toLowerCase()){
        case "info":
            console.info(message)
            break;
        case "warning":
        case "warn":
            console.warn(message)
            break;
        case "error":
            console.error(message)
            trace = true;
            break;
        }
        if (trace){
            console.trace();
        }
        console.log("FINISH MESSAGE:::::::::::::::::::::::::::")
        return;
    }

}




