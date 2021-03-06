import Zabaat.Material 1.0
import QtQuick 2.4
import QtGraphicalEffects 1.0
//Default button, flat style
ZSkin {
    id : rootObject

    //aliases so stateHandler can see it
//    property alias graphical     : graphical
    property alias textContainer : textContainer
    property alias font          : text.font
    property alias textItem      : text

    focus : true
    activeFocusOnTab: true
//    onActiveFocusChanged: console.log(rootObject, "focus=", activeFocus)
    color : graphical["fill_" + graphicalState]
    transparency: graphical.fill_Opacity





    border.color    : graphical.borderColor
    anchors.centerIn: parent
    onLogicChanged  : if(logic) {
                          logic.containsMouse = Qt.binding(function() { return inkArea.containsMouse })

                      }

    property string graphicalState : activeFocus ?  "Focus"  : "Default"

    Keys.onPressed:  {
        if(event.key == Qt.Key_Enter || event.key == Qt.Key_Return || event.key == Qt.Key_Space){
            inkArea.simulatePress();
            event.accepted = true;
        }
    }
    Keys.onReleased: {
        if(event.key == Qt.Key_Enter || event.key == Qt.Key_Return || event.key == Qt.Key_Space){
            inkArea.simulateRelease(true);
            event.accepted = true;
        }
    }


    skinFunc : function(name, params) { //the logic may call this!!
        var fn = guiLogic[name]
        if(typeof fn === 'function')
            return fn(params);
        console.log(rootObject, 'has no skin function called', name)
        return null;
    }
    QtObject {
        id : guiLogic
        function paintedWidth()  {  return text.paintedWidth; }
        function paintedHeight() {  return text.paintedHeight; }
        function getTextStartPos() {
            var pt = Qt.point(0,0);
            var margins = text.anchors.margins;

            if(text.horizontalAlignment === Text.AlignHCenter) {
                pt.x = margins + (text.width - text.paintedWidth)/2
            }
            else if(text.horizontalAlignment === Text.AlignLeft) {
                pt.x = margins;
            }
            else {
                pt.x = text.width - text.paintedWidth - margins;
            }

            if(text.verticalAlignment === Text.AlignVCenter) {
                pt.y = margins + (text.width - text.paintedHeight)/2;
            }
            else if(text.verticalAlignment === Text.AlignTop) {
                pt.y = margins;
            }
            else {
                pt.y = text.height - text.paintedHeight - margins;
            }

            return pt;
        }
    }




    ZInkArea {
        id : inkArea
        anchors.fill: parent
        color   : graphical.inkColor
        enabled : logic ? true : false;
        allowDoubleClicks: logic ? logic.allowDoubleClicks : false
        acceptedButtons: logic && logic.acceptedButtons !== -1 ? logic.acceptedButtons : Qt.AllButtons
        onPressed       : if(logic) logic.pressed(logic, x,y,buttons)
        onClicked       : if(logic) logic.singleClicked(logic, x,y,buttons)
        onDoubleClicked : if(logic) logic.doubleClicked(logic, x,y,buttons)
        opacity : graphical.inkOpacity
        onContainsMouseChanged : {
//            if(graphical.state !== 'press')
//                graphical.state = containsMouse ? "focus" : ""
        }
    }
    Item {
        id :  textContainer
        anchors.fill: parent
//        clip : true
//        Text  {
//            anchors.right: parent.left
//            text : text.font.pixelSize + "/" + text.scale + " " + logic.state
//        }
        Text {
            id : text
            anchors.fill       : parent
            anchors.margins    : parent.height * 1/10
            horizontalAlignment: graphical.text_hAlignment
            verticalAlignment  : graphical.text_vAlignment
            font.family        : Fonts.font1
            text               : logic.text
            color              : graphical["text_" + graphicalState]
            textFormat         : Text.RichText
//            scale              : paintedWidth > width ? width / paintedWidth : 1
        }

//        Text {
//            anchors.right: parent.right
//            anchors.top: parent.top
//            text : text.font.pixelSize
//        }

    }




    states : ({
        "default" : { "rootObject": { "border" :{ width : 0 },
                                    "radius"       : 0,
                                    "@width"       : [parent,"width"],
                                    "@height"      : [parent,"height"],
                                    rotation       : 0
                                   } ,
                    textContainer : { rotation : 0 },
        },
       "diamond" : { rootObject: { "border": { width :  1 } ,
                                   "radius": 5,
                                    rotation : 45
                                 },
                     textContainer : { rotation : -45 }
       },
       "circle" : { rootObject: { "border": { width :  1 } ,
                                   "@radius": [rootObject,"height", 0.5],
                                   "@width" : [rootObject,"height"],
                                   clip: true
                  }
        },
        "raised" : { rootObject: {  "border": { width :  1 } ,
                                    radius: 5,
                   }
        },
        "singleclickonly" : { logic : { allowDoubleClicks : false } },
        "fit" : { textItem : { "@scale" : function() {
                                            var sx = textItem.paintedWidth  > textItem.width  ? width /textItem.paintedWidth - 0.1 : 1;
                                            var sy = textItem.paintedHeight > textItem.height ? height/textItem.paintedHeight - 0.1 : 1;
                                            return Math.min(sx,sy);
                                          }
                              }
                },
        //cannot be used with richText apparently
        "elideright"    : { textItem : { scale : 1, elide : Text.ElideRight      }},
        "elideleft"     : { textItem : { scale : 1, elide : Text.ElideLeft       }},
        "elidemiddle"   : { textItem : { scale : 1, elide : Text.ElideMiddle     }}

    })


}
