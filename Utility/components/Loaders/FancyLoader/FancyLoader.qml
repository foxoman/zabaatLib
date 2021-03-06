import QtQuick 2.4
//import "../Functions"
import Zabaat.Base 1.0
//Essentially loads the next thing async and then shows it when ready! Ability to block when loading

Item {
    id : rootObject
    property string transitionEffect   : "rotateRight"
    property int    transitionDuration : 500
    readonly property int status       : logic.nextLoader.Loading ? logic.nextLoader.status : logic.activeLoader.status
    readonly property var item         : logic.activeLoader.item
    readonly property real progress    : logic.nextLoader.Loading ? logic.nextLoader.progress : logic.activeLoader.progress

    property var args               : null
    property url source             : ""
    property var sourceComponent    : null

    signal loaded();

    onSourceChanged                 : {
        console.log(rootObject , "SOURCE CHANGED TO", source);
        blocker.visible = true;
        logic.nextLoader.source = source;
    }
    onSourceComponentChanged        : {
        blocker.visible = true;
        logic.nextLoader.sourceComponent = sourceComponent;
    }

//    Component.onCompleted: creationTime = +(new Date().getTime())
//    property var creationTime
    onLoaded : {
//        if(objectName === "NavMachine.FancyLoader") {
//            var time = +(new Date().getTime())
//            console.log("@@@@@@@@@@@@@@@",rootObject, time - creationTime, "ms taken to load")
//        }

        var newActive = logic.activeLoader === l1 ? l2 : l1
        var newNext   = newActive === l1 ? l2 : l1

        logic.activeLoader = newActive
        logic.nextLoader   = newNext

        logic.nextLoader.mutex = true;
        logic.nextLoader.source          = "";    //unload the thonger
        logic.nextLoader.sourceComponent = null;
        logic.nextLoader.mutex = false;

        l1.tempTrans = l2.tempTrans = "";

        blocker.visible = false;
    }

    function load(source, args, transition){
        logic.nextLoader.tempTrans = transition;

        rootObject.args = args;
        blocker.visible = true;
        if(typeof source === 'string'){
            logic.nextLoader.setSource(source);
        }
        else{
            logic.nextLoader.sourceComponent = source
        }
    }



    //Loader.Null - loader is inactive or no source is set
    //Loader.Ready - the qml source has been loaded
    //Loader.Loading - Is currently beign loaded
    //Loader.Error - an error occureed while loading the qml source

    QtObject {
        id : logic
        property var activeLoader  : l2
        property var nextLoader    : l1

        function statusStr(str) {
            if(str === Loader.Ready)            return "Loader.Ready"
            else if(str === Loader.Loading)     return "Loader.Loading"
            else if(str === Loader.Error)       return "Loader.error"
            else if(str === Loader.Null)        return "Loader.Null"
            else                                return str.toString();
        }

        function assignArgs(loader){
            var item = loader ? loader.item : null
            if(item && args){
                Lodash.each(args, function(v,k){
                    if(item.hasOwnProperty(k))   {
                        try {
                            item[k] = v;
                        }
                        catch(e) {
                            console.error(rootObject, "unable to assign", k, "to", v)
                        }
                    }
                })
                args = null;
                loader.finishedLoading();
            }
        }
        function doTransition(from,to,transName){
            var transition = transName === "" ? null : getTransition(transName)
            if(transition) {
//                console.log("TRANS FOUND",transition)
                transition.begin(from,to)
            }
            else
                loaded()
        }
        function getTransition(name){
            return transitions.map[name]
        }

        function isUndef(obj) {
            return obj === null || typeof obj === 'undefined'
        }

    }
    Loader {
        id : l1
        objectName : "loader1"
        width : parent.width
        height : parent.height
        asynchronous: true
        onLoaded         : if(!mutex)
                               logic.assignArgs(l1)
        onFinishedLoading: logic.doTransition(l2,l1,tempTrans)
        z                : logic.activeLoader === l1 ?  2 : 1

        signal finishedLoading()
        property string tempTrans;
        property bool mutex : false;
//        Component.onCompleted: console.log(this)
        onSourceChanged: console.log("l1 status = ", logic.statusStr(status), "source=",source);
        onStatusChanged: console.log("l1 status = ", logic.statusStr(status), "source=",source);
    }
    Loader {
        id : l2
        objectName : "loader2"
        width : parent.width
        height : parent.height
        asynchronous: true
        onLoaded         : if(!mutex)
                               logic.assignArgs(l2)
        onFinishedLoading: logic.doTransition(l1,l2,tempTrans)
        z : logic.activeLoader === l2 ?  2 : 1

        signal finishedLoading()
        property string tempTrans;
        property bool mutex : false;
//        Component.onCompleted: console.log(this)
        onSourceChanged: console.log("l2 status = ", logic.statusStr(status), "source=",source);
        onStatusChanged: console.log("l2 status = ", logic.statusStr(status), "source=",source);
    }


    Rectangle {
        id : blocker
        anchors.fill: parent
        color : 'black'
        opacity : 0.8
        visible : false
//        onVisibleChanged:  {
//            if(rootObject.objectName !== "LoginStateMachine.FancyLoader") {
//                console.log(rootObject, "blocker.visible=", visible)
//                console.trace()
//            }
//        }
        z : Number.MAX_VALUE
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    Item {
        id : transitions
        property var map : ({   fade       : fade       ,
                                slideRight : slideRight ,
                                slideLeft  : slideLeft  ,
                                slideUp    : slideUp    ,
                                slideDown  : slideDown  ,
                                scaleIn    : scaleIn    ,
                                rotateRight: rotateRight,
                                rotateLeft : rotateLeft
                            })


        //transitions controller
        ParallelAnimation {
            id: fade

            function begin(from,to){
                fade_n1.target = from;
                fade_n2.target = to;
                fade_n1.duration = fade_n2.duration = transitionDuration;
                start();
            }

            NumberAnimation {
                id : fade_n1
                property: "opacity"
                easing.type: Easing.InOutQuad
                from : 1
                to   : 0
            }
            NumberAnimation {
                id : fade_n2
                property: "opacity"
                easing.type: Easing.InOutQuad
                from : 0
                to   : 1
            }
            onStarted : {
//                console.log("fade",n1.target,"->", n2.target)
            }
            onStopped : loaded()
        }
        ParallelAnimation {
            id: slideRight

            function begin(from,to){
                slideRight_n1.target = from;
                slideRight_n2.target = to;
                slideRight_n1.duration = slideRight_n2.duration = transitionDuration;
                start();
            }

            NumberAnimation {
                id : slideRight_n1
                property: "x"
                easing.type: Easing.InOutQuad
                from : 0
                to   : rootObject.width
            }
            NumberAnimation {
                id : slideRight_n2
                property: "x"
                easing.type: Easing.InOutQuad
                from : -rootObject.width
                to   : 0
            }
            onStopped : loaded()
        }
        ParallelAnimation {
            id: slideLeft

            function begin(from,to){
                slideLeft_n1.target = from;
                slideLeft_n2.target = to;
                slideLeft_n1.duration = slideLeft_n2.duration = transitionDuration;
                start();
            }

            NumberAnimation {
                id : slideLeft_n1
                property: "x"
                easing.type: Easing.InOutQuad
                from : 0
                to   : -rootObject.width
            }
            NumberAnimation {
                id : slideLeft_n2
                property: "x"
                easing.type: Easing.InOutQuad
                from : rootObject.width
                to   : 0
            }
            onStopped : loaded()
        }
        ParallelAnimation {
            id: slideUp

            function begin(from,to){
                slideUp_n1.target = from;
                slideUp_n2.target = to;
                slideUp_n1.duration = slideUp_n2.duration = transitionDuration;
                start();
            }

            NumberAnimation {
                id : slideUp_n1
                property: "y"
                easing.type: Easing.InOutQuad
                from : 0
                to   : -rootObject.height
            }
            NumberAnimation {
                id : slideUp_n2
                property: "y"
                easing.type: Easing.InOutQuad
                from : rootObject.height
                to   : 0
            }
            onStopped : loaded()
        }
        ParallelAnimation {
            id: slideDown

            function begin(from,to){
                slideDown_n1.target = from;
                slideDown_n2.target = to;
                slideDown_n1.duration = slideDown_n2.duration = transitionDuration;
                start();
            }

            NumberAnimation {
                id : slideDown_n1
                property: "y"
                easing.type: Easing.InOutQuad
                from : 0
                to   : rootObject.height
            }
            NumberAnimation {
                id : slideDown_n2
                property: "y"
                easing.type: Easing.InOutQuad
                from : -rootObject.height
                to   : 0
            }
            onStopped : loaded()
        }
        SequentialAnimation{
            id : scaleIn

            function begin(from,to){
                scaleIn_n1.target = from;
                scaleIn_n2.target = to;
                scaleIn_n1.duration = transitionDuration/2;
                scaleIn_n2.duration = transitionDuration/2;
                start();
            }
            NumberAnimation {
                id : scaleIn_n1
                target     : null
                property   : "scale"
                easing.type: Easing.InOutQuad
                from       : 1
                to         : 0
            }
            NumberAnimation {
                id : scaleIn_n2
                target     : null
                property   : "scale"
                easing.type: Easing.InOutQuad
                from       : 0
                to         : 1
            }
            onStopped : loaded()
        }
        ParallelAnimation{
            id : rotateRight

            function begin(from,to){
                rotateRight_n1.target = from;
                rotateRight_n2.target = to;
                rotateRight_n1.duration = transitionDuration;
                rotateRight_n2.duration = transitionDuration;
                start();
            }

            ParallelAnimation {
                id : rotateRight_n1
                property var target : null
                property int duration: 1000

                NumberAnimation {
                    property   : "rotation"
                    easing.type: Easing.InOutQuad
                    from       : 0
                    to         : 90
                    target     : rotateRight_n1.target
                    duration   : rotateRight_n1.duration
                }
                NumberAnimation {
                    property   : "x"
                    easing.type: Easing.InOutQuad
                    from       : 0
                    to         : rootObject.width
                    target     : rotateRight_n1.target
                    duration   : rotateRight_n1.duration
                }

            }

            ParallelAnimation {
                id : rotateRight_n2
                property var target : null
                property int duration: 1000

                NumberAnimation {
                    property   : "rotation"
                    easing.type: Easing.InOutQuad
                    from       : 90
                    to         : 0
                    target     : rotateRight_n2.target
                    duration   : rotateRight_n2.duration
                }
                NumberAnimation {
                    property   : "x"
                    easing.type: Easing.InOutQuad
                    from       : -rootObject.width
                    to         : 0
                    target     : rotateRight_n2.target
                    duration   : rotateRight_n2.duration
                }
            }

            onStopped : loaded()
        }
        ParallelAnimation{
            id : rotateLeft

            function begin(from,to){
                rotateLeft_n1.target = from;
                rotateLeft_n2.target = to;
                rotateLeft_n1.duration = transitionDuration;
                rotateLeft_n2.duration = transitionDuration;
                start();
            }

            ParallelAnimation {
                id : rotateLeft_n1
                property var target : null
                property int duration: 1000

                NumberAnimation {
                    property   : "rotation"
                    easing.type: Easing.InOutQuad
                    from       : 0
                    to         : -90
                    target     : rotateLeft_n1.target
                    duration   : rotateLeft_n1.duration
                }
                NumberAnimation {
                    property   : "x"
                    easing.type: Easing.InOutQuad
                    from       : 0
                    to         : -rootObject.width
                    target     : rotateLeft_n1.target
                    duration   : rotateLeft_n1.duration
                }

            }

            ParallelAnimation {
                id : rotateLeft_n2
                property var target : null
                property int duration: 1000

                NumberAnimation {
                    property   : "rotation"
                    easing.type: Easing.InOutQuad
                    from       : -90
                    to         : 0
                    target     : rotateLeft_n2.target
                    duration   : rotateLeft_n2.duration
                }
                NumberAnimation {
                    property   : "x"
                    easing.type: Easing.InOutQuad
                    from       : rootObject.width
                    to         : 0
                    target     : rotateLeft_n2.target
                    duration   : rotateLeft_n2.duration
                }
            }

            onStopped : loaded()
        }


        //TODO, add more here!



    }



}
