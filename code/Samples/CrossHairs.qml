import QtQuick 2.7

Rectangle{
    id: crossHairs

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


