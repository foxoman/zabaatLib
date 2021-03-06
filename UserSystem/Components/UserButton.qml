import QtQuick 2.5
import Zabaat.UserSystem 1.0
import Zabaat.Base 1.0
Item {
    id : rootObject
    property var m

    property string textDisp    : !m ? "Not Logged In" : first || last  ? first + " " + last : username;
    property string avatar      : !m ? Qt.resolvedUrl(ri.def) : getSafe(m, UserSystem.config.keyName_avatar, Qt.resolvedUrl(ri.def));
    property string username    : !m ? "" : Lodash.isString(m) ? m :
                                                                getSafe(m, UserSystem.config.keyName_username, "");
    property string uid         : !m ? "" : getSafe(m, UserSystem.config.keyName_id, "");
    property string first       : !m ? "" : getSafe(m, UserSystem.config.keyName_firstName, "");
    property string last        : !m ? "" : getSafe(m, UserSystem.config.keyName_lastName, "");
    property bool   female      : !m ? false : getSafe(m, UserSystem.config.keyName_gender, false);
    property alias  btn         : btn

    function getSafe(obj,prop,defaultVal){
        if(typeof obj !== 'object' || !obj.hasOwnProperty(prop))
            return defaultVal;
        return obj[prop]
    }

    signal clicked(string id, string username);


    RoundedImage {
        id : ri
        width  : height
        height : parent.height
        source : parent.avatar
        property string def : female ? 'blank_female.png' : 'blank.png'
        MouseArea {
            anchors.fill: parent
            onClicked: rootObject.clicked(uid, username);
        }
    }

    FlexibleComponent {
        id : btn
        //width : parent.width - parent.height
        height : parent.height
        value : parent.textDisp
        anchors.left: ri.right
        anchors.right: parent.right
        clip: true
        src : UserSystem.componentsConfig.button_user
        onEvent: if(name === 'clicked')
                     rootObject.clicked(uid, username);
    }
}
