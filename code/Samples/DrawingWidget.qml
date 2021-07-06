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
            //drawingWidget.updateLiveGraphic();
            //     drawingWidget.updateNextPointLineGraphic(drawingWidget.view.currentViewpointCenter.center);

            drawingWidget.setNextPointLineGeometry(drawingWidget.view.currentViewpointCenter.center);
        }
    }

    property GraphicsOverlay graphicsOverlay: mapView.graphicsOverlay
    property Graphic graphic
 //   property Graphic liveGraphic
    property Graphic nextPointLineGraphic
    property Graphic currentVertexGraphic
    property Graphic verticesGraphic
//    property GeometryBuilder builder
//    property GeometryBuilder liveBuilder
//    property GeometryBuilder nextPointLineBuilder
    property int currentPartIndex
    property int currentPointIndex

    Connections{
        target: parent.graphic ? parent.graphic : null
        function onGeometryChanged(){
            //  updateCurrentVertexGraphic();
        }
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

    property Symbol nextPointLineSymbol:
        SimpleLineSymbol {
        style: Enums.SimpleLineSymbolStyleDash
        color: "steelblue"
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
        color: "blue"
        size: 8 * scaleFactor
        style: Enums.SimpleMarkerSymbolStyleCircle

        // declare the symbol's outline
        SimpleLineSymbol {
            width: 1
            color: "red"
        }
    }

    property Symbol currentVertexSymbol:
        SimpleMarkerSymbol {
        color: "red"
        size: 8 * scaleFactor
        style: Enums.SimpleMarkerSymbolStyleCircle

        // declare the symbol's outline
        SimpleLineSymbol {
            width: 1
            color: "red"
        }
    }

    function reset(){
        view.graphicsOverlay.graphics.clear();
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
        return _builder;
    }

//    function createBuilders(){

//        console.log("Request to create builders...")

//        if (!allSystemsGo) return

//        console.log("All systems are go so we are creating the builders...")

//        const emptyGeometryProperties = {spatialReference: view.map.spatialReference};

//        switch (geometryType){
//        case Enums.GeometryTypePolygon:
//            builder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", emptyGeometryProperties);
//            liveBuilder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", emptyGeometryProperties);
//            nextPointLineBuilder = ArcGISRuntimeEnvironment.createObject("PolylineBuilder", emptyGeometryProperties);
//            break;
//        case Enums.GeometryTypePolyline:
//            builder = ArcGISRuntimeEnvironment.createObject("PolylineBuilder", emptyGeometryProperties);
//            break;
//        case Enums.GeometryTypePoint:
//            builder = ArcGISRuntimeEnvironment.createObject("PointBuilder", emptyGeometryProperties);
//            break;
//        case Enums.GeometryTypeMultipoint:
//            builder = ArcGISRuntimeEnvironment.createObject("MultipointBuilder", emptyGeometryProperties);
//            break;
//        case Enums.GeometryTypeEnvelope:
//            builder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder", emptyGeometryProperties);
//            break;
//        }

//        currentPartIndex = 0;
//        currentPointIndex = -1;
//    }

    function resetGraphics(){
        graphicsOverlay.graphics.clear();

    //    const customSymbolJson = app.folder.readJsonFile("./Samples/customSymbol.json")
    //    const sym = ArcGISRuntimeEnvironment.createObject("MultilayerPolygonSymbol", {json: customSymbolJson});

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

//    function updateLiveGraphic(){
//        if (!allSystemsGo || !liveGraphic || !liveGraphic.geometry || liveGraphic.geometry.empty) return;
//        switch (geometryType){
//        case Enums.GeometryTypePolygon:
//            updatePointInPolygon(drawingWidget.view.currentViewpointCenter.center, liveGraphic, liveBuilder);
//            break;
//        }
//    }

//    function updateNextPointLineGraphic(_point){
//        if (!allSystemsGo) return;
//        //  if (!allSystemsGo || !nextPointLineGraphic || !nextPointLineGraphic.geometry || nextPointLineGraphic.geometry.empty) return;
//        switch (geometryType){
//        case Enums.GeometryTypePolygon:
//            console.log("100 BANANS")
//            //console.log("builder point Count: ", builder.parts.part(currentPartIndex).pointCount)


//            if (builder.sketchValid){
//                nextPointLineBuilder.geometry = null;
//                console.log("Sketch is valid:::> ",  builder.parts.part(currentPartIndex).pointCount, currentPointIndex  )
//                nextPointLineBuilder.addPointXY(builder.parts.part(currentPartIndex).point(currentPointIndex).x, builder.parts.part(currentPartIndex).point(currentPointIndex).y);
//                nextPointLineBuilder.addPointXY(_point.x, _point.y);

//                if (builder.parts.part(currentPartIndex).pointCount-1 > currentPointIndex){
//                    nextPointLineBuilder.addPointXY(builder.parts.part(currentPartIndex).point(currentPointIndex+1).x, builder.parts.part(currentPartIndex).point(currentPointIndex+1).y);
//                }
//                else{
//                    //go back to zero - the first point...
//                    nextPointLineBuilder.addPointXY(builder.parts.part(currentPartIndex).point(0).x, builder.parts.part(currentPartIndex).point(0).y);
//                }
//            }
//            else {
//                if (!nextPointLineBuilder.sketchValid){
//                    console.log("!nextPointLineBuilder.sketchValid")
//                    nextPointLineBuilder.addPointXY(_point.x, _point.y);
//                }
//                else if (builder.parts.part(currentPartIndex).pointCount === 1){
//                    nextPointLineBuilder.parts.part(0).setPoint(nextPointLineBuilder.parts.part(0).pointCount-1, _point  )
//                }
//                else if (builder.parts.part(currentPartIndex).pointCount === 2 && nextPointLineBuilder.parts.part(0).pointCount === 2){
//                    nextPointLineBuilder.addPointXY(_point.x, _point.y);
//                }
//                else{
//                    nextPointLineBuilder.parts.part(0).setPoint(2, _point  )
//                }
//            }

//            nextPointLineGraphic.geometry = nextPointLineBuilder.geometry;

//            console.log(nextPointLineBuilder.parts.part(0).pointCount)

//            //  console.log("nextPointLineBuilder.geometry", JSON.stringify(nextPointLineBuilder.geometry.json))
//            break;
//        }
//    }

    //    function updateCurrentVertexGraphic(_point){
    //        currentVertexGraphic.geometry = _point;
    //    }

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

            //currentVertexGraphic.geometry = _point;
            currentPointIndex += 1;

            //this is for the line that tracks as the map pans.
            setNextPointLineGeometry(_point);
            //  updateNextPointLineGraphic(_point)
            break;
        }

    }

    function setNextPointLineGeometry(_point){

        const _builder = createBuilder(undefined, Enums.GeometryTypePolyline);
        if (nextPointLineGraphic.geometry) _builder.geometry = nextPointLineGraphic.geometry;

        if (!nextPointLineGraphic.geometry || nextPointLineGraphic.geometry.empty){
            console.log("the nextPointLineGraphic is nothing")
            //add the point 3 times

            _builder.addPoint(_point);
            _builder.addPoint(_point);
            _builder.addPoint(_point);
            nextPointLineGraphic.geometry = _builder.geometry;
        }
        else{
            const pointIndexes = getNextAndPreviousPointIndexes(graphic.geometry, currentPointIndex, currentPartIndex);
            _builder.parts.part(0).setPoint(0, graphic.geometry.parts.part(currentPartIndex).point(pointIndexes.currentPointIndex));
            _builder.parts.part(0).setPoint(1, _point);
            _builder.parts.part(0).setPoint(2, graphic.geometry.parts.part(currentPartIndex).point(pointIndexes.nextPointIndex));
        }

        _builder.parts.part(0).setPoint(1, _point);
        nextPointLineGraphic.geometry =  _builder.geometry;
    }

    function getNextAndPreviousPointIndexes(_geometry, _currentPointIndex, _currentPartIndex){
        let nextPointIndex = _currentPointIndex + 1;
        const part = _geometry.parts.part(_currentPartIndex);
        if (nextPointIndex >= part.pointCount){
            nextPointIndex = 0;
        }
        let previousPointIndex = currentPointIndex -1;
        if (previousPointIndex < 0 && part.pointCount > 1){
            previousPointIndex = part.pointCount-1
        }
        else{
            previousPointIndex = 0;
        }

        return {currentPointIndex: currentPointIndex, nextPointIndex: nextPointIndex, previousPointIndex: previousPointIndex};
    }



    //:::::::::::::::POLYGON FUNCTIONS:::::::::::::::::::::::::::::

    function addPointToPolygon(_point, _graphic, _partIndex, _pointIndex){

        let _builder = createBuilder(_graphic.geometry, Enums.GeometryTypePolygon)

        let part;
        if (_builder.parts.empty){
            part = ArcGISRuntimeEnvironment.createObject("Part");
            part.spatialReference = _builder.spatialReference;
            _builder.parts.addPart(part);
        }
        else if (!_partIndex || _partIndex > _builder.parts.size-1){
            _partIndex = _builder.parts.size-1;
            part = _builder.parts.part(_partIndex);
        }
        else{
            part = _builder.parts.part(_partIndex);
        }

        if (!part.sketchValid){
            part.addPoint(_point)
        }else{
            part.insertPoint(_pointIndex+1, _point);
        }

        console.log("_builder.sketchValid", _builder.sketchValid)

        // if (_builder.sketchValid) _graphic.geometry = _builder.geometry;
        _graphic.geometry = _builder.geometry;
    }

//    function addPointToPolygon_old(_point, _graphic, _builder, _partIndex, _pointIndex){
//        let part;
//        if (_builder.parts.empty){
//            part = ArcGISRuntimeEnvironment.createObject("Part");
//            part.spatialReference = _builder.spatialReference;
//            _builder.parts.addPart(part);
//        }
//        else if (!_partIndex || _partIndex > _builder.parts.size-1){
//            _partIndex = _builder.parts.size-1;
//            part = _builder.parts.part(_partIndex);
//        }
//        else{
//            part = _builder.parts.part(_partIndex);
//        }

//        if (!part.sketchValid){
//            part.addPoint(_point)
//        }else{
//            part.insertPoint(_pointIndex+1, _point);
//        }

//        if (_builder.sketchValid) _graphic.geometry = _builder.geometry;
//    }

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



    //:::::::::::::::MULTIPOINT FUNCTIONS:::::::::::::::::::::::::::::

    function addPointToMultiPoint(_point, _graphic){
        const _builder = createBuilder(_graphic.geometry, Enums.GeometryTypeMultipoint);
        _builder.points.addPoint(_point);
        _graphic.geometry = _builder.geometry;
    }


    //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

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

    Component{
        id: defaultControls

        Rectangle{
            width: 100 * scaleFactor
            height: 200 * scaleFactor
            radius: 5 * scaleFactor

            //            anchors{
            //                right: parent.right
            //                top: parent.top
            //                rightMargin: 15 * scaleFactor
            //                topMargin:  15 * scaleFactor
            //            }

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


    }
}




