import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

ListView {
    id: bookmarksView

    signal bookmarkSelected (int index)

    clip: true
    footer:Rectangle{
        height:100 * scaleFactor
        width:bookmarksView.width
        color:"transparent"
    }

    delegate:  PanelItem {
        clickable: true
        imageSource: "../images/bookmark.png"
        txt: name
        imageColor: Qt.lighter(app.subTitleTextColor)

        onClicked: {
            bookmarkSelected(index)
        }
    }

    BaseText {
        id: message

        visible: model.count <= 0 && text > ""
        maximumLineCount: 5
        elide: Text.ElideRight
        width: parent.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("There are no bookmarks.")
    }
}
