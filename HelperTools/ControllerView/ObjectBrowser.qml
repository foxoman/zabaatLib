import QtQuick 2.5
import QtQuick.Controls 1.4
import Zabaat.Base 1.0
Item {
    id : rootObject
    property var obj
    property real cellHeight : 0.06
    property real cellHeightAbsolute : -1
    property alias contentHeight : lv.contentHeight
    property font font;

    QtObject {
        id: logic
        property ListFunctions list     : ListFunctions   { id : fnList }
        property ObjectFunctions object : ObjectFunctions { id : fnObj  }
        property ListModel lm: ListModel { id : lm; dynamicRoles : true }
        property var excludeList : ['objectName', 'undefined', 'null', 'objectNameChanged','hasOwnProperty']
        property var  rootType : fnObj.getType(obj)
//        property var rootTypeStr : rootType === null ? "null" : rootType === undefined ? "undefined" : rootType


        function addObj(){
            for(var p in obj){
                if(excludeList.indexOf(p) !== -1 || p.indexOf("__") === 0)
                    continue

                var key  = p
                if(!existsInLm(lm, function(i){ return i && i.key === key ? true : false }))
                    lm.append({ key     : key ,
                                type  : fnObj.getType(obj[key])
                              })
//                        console.log("Added items", lm.count)
            }
        }

        function addArr(){
            for(var i = 0; i < obj.length ; ++i){
                var key = i
                var type = fnObj.getType(obj[key])
//                console.log('addArr', key, type, JSON.stringify(obj[key]))
                lm.append({ key     : key ,
                            type    : type
                           })
            }
        }

        function addLm(){
            for(var i = 0; i < obj.count ; ++i){
//                var item = obj.get(i)
                var type = fnObj.getType(obj.get(i))
//                console.log(i, 'adding', type, JSON.stringify(obj.get(i),null,2))
                lm.append({ key     : i ,
                            type    : type
                          })
            }
        }

        function addProperties(){
            if(obj){
                var n = obj.toString().toLowerCase()
                if(n.indexOf("modelnode") !== -1 || n.indexOf('modelobject') !== -1){
//                    console.log(rootObject.objectName , 'adding obj')
                    addObj()
                }
                else if(toString.call(obj) === '[object Array]'){
//                    console.log(rootObject.objectName, "adding array at", obj.length)
                    addArr()
                }
                else if(n.indexOf("model") !== -1){
//                    console.log(rootObject.objectName, 'adding model')
                    addLm()
                }
                else if(typeof obj === 'object'){
//                    console.log(rootObject.objectName, "adding object last")
                    addObj()
                }
                else {
//                    console.log(rootObject.objectName, 'adding nothing!!!!!!!', obj, typeof obj)
                }
            }
            else if(rootObject.objectName !== ""){   //not an empty thing but still null!
//                console.error(rootObject.objectName , "obj is null or undefined!!")
            }
        }
        function existsInLm(lm, func) {
            if(lm){
                for(var i = 0; i < lm.count; ++i){
                    var item = lm.get(i)
                    if(func(item))
                        return true;
                }
            }
            return false;
        }

        function isStdJsType(obj){
            var t = typeof obj
            if(obj === null || t === 'undefined' || t === 'boolean' || t === 'number' || t === 'string' || toString.call(obj) === '[object Date]' )
                return true;
            return false;
        }

        property QtObject colors : QtObject{
            id: colors
            property color stdType     : 'darkblue'
            property color notStdStype : 'darkorange'
            property color undefOrNull : 'darkred'
        }
    }

    onObjChanged: {
        lm.clear()
        logic.addProperties()
    }


    ScrollView {
        anchors.fill: parent
        ListView {
            id: lv
            anchors.fill: parent
            model : lm
            property real ch : cellHeightAbsolute !== -1 ? cellHeightAbsolute : lv.height * cellHeight

            delegate : Row {
                id : del
                width : lv.width
                height : valueLoader.expanded ? lv.ch + valueLoader.contentHeight : lv.ch
                property bool ready  : obj && type !== null && type !== undefined && key !== null && key !== undefined ? true : false
                property var stdType : ready ? logic.isStdJsType(value) : null
                property var value   : {
                    if(!ready || !logic.rootType || logic.rootType === 'undefined')
                        return null;

//                    console.log(rootObject.name , key)
                    var r = logic.rootType.toLowerCase()
                    if(r.indexOf('modelnode') !== -1 || r.indexOf("modelobject") !== -1){
//                        console.log("\tmNode")
                        return obj[key]
                    }
                    else if(r.indexOf('model') !== -1){
//                        console.log('\tm')
                        return obj.get(key)
                    }
                    else {
//                        console.log('\telse')
                        return obj[key]
                    }

                }
//                onValueChanged: console.log(rootType, rootObject.objectName, key, type, JSON.stringify(value), '\t\t', stdType  )
                property string typeText : {
                    if(value === null)
                        return "null"
                    if(value === undefined)
                        return "undefined"
                    if(typeof value === 'string')
                        return "string (" + value.length + ")"
                    if(toString.call(value) === "[object Date]")
                        return "date"
                    if(stdType)
                        return type;

                    var typestr = value.toString().toLowerCase()
                    if(typestr.indexOf('modelnode') !== -1 || typestr.indexOf("modelobject") !== -1) {
                        return type + " (" + fnObj.getProperties(value, logic.excludeList, "__").length + ")"
                    }

                    if(typestr.indexOf('model') !== -1) {
//                        console.log("m")
                        return type + " (" + value.count +  ")"
                    }

                    else if(toString.call(value) === "[object Array]") {
//                        console.log("arr")
                        return type + " (" + value.length  + ")"
                    }

//                    console.log("final")
                    return type + " (" + fnObj.getProperties(value, logic.excludeList, "__").length + ")"
                }


                SimpleButton {
                    width  : parent.width * 0.15
                    height : parent.height
                    text : key
                    font : rootObject.font
                    clip : true
                }
                Column {
                    width  : parent.width * 0.85
                    height : parent.height
                    SimpleButton {
                        width  : parent.width
                        height : del.stdType !== false ? parent.height * 0.4 : 0
                        text   : del.typeText
                        visible: del.stdType !== false
                        color : value === null || typeof value === 'undefined' ? colors.undefOrNull : colors.stdType
                        textColor : 'white'
                        clip : true
                    }
                    Loader {
                        id : valueLoader
                        width : parent.width
                        height : del.stdType !== false ? parent.height * 0.6 : parent.height
                        property bool expanded : false
                        property real contentHeight : item && item.contentHeight ? item.contentHeight : 0
                        clip : true
                        source : del.stdType || !del.ready ? "SimpleButton.qml" : "ExpanderButton.qml"
                        onLoaded: doLoad()

                        function doLoad() {
                            if(item){
                                item.anchors.fill = valueLoader
                                item.font = rootObject.font
                                if(del.stdType === false){
                                    if(item.hasOwnProperty('obj')){
                                        item.objectName = rootObject.objectName + "_" + key
                                        item.cellHeightAbsolute = lv.ch
                                        item.textColor = 'white'
                                        item.color = colors.notStdStype

                                        item.text = del.typeText
                                        item.obj = Qt.binding(function() { return del.value } );
//                                        if(item.obj.length)
//                                            console.log('nestage', item.objectName, item.obj, fnObj.getType(item.obj))
                                        valueLoader.expanded = item.expanded;
                                        item.onExpandedChanged.connect(function(){ valueLoader.expanded = item.expanded })
                                    }
                                    else{
                                        console.error("No obj @", rootObject.objectName + "_" + key, del.stdType, del.value)
                                    }
                                }
                                else {
                                    item.text = Qt.binding(function() { return del.value === null ?     "null" :
                                                                                 del.value === undefined ? 'undefined' : del.value.toString() } );
                                }
                            }
                        }
                        function reload(){
                            source = ""
                            source = del.stdType ? "SimpleButton.qml" : "ExpanderButton.qml"
                            doLoad()
                        }
                    }


                }

            }
        }

    }



}
