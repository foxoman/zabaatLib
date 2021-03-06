import QtQuick 2.5
Item {
    id : rootObject
    property var model
    property var filterFunc
    readonly property var lv    : loader.item ? loader.item.lv    : null
    readonly property var currentItem : lv ? lv.currentItem : null;
    readonly property int currentIndex         : lv ? lv.currentIndex : -1;
    readonly property var logic : loader.item ? loader.item.logic : null
    readonly property var gui   : loader.item ? loader.item.gui   : null

    readonly property var indexList : loader.item ? loader.item.indexList : null
    readonly property var indexListFiltered : loader.item ? loader.item.indexListFiltered : null

    function undo           ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function redo           ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function deselect       (idx)         { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function select         (idx)         { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function selectAll      ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function deselectAll    ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function moveToTopAbsolute()          { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function moveToTop      ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function moveToBottom   ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function moveToBottomAbsolute()       { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function moveSelectedTo (idx,destIdx) { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function resetState     ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function undos          ()            { return (loader.item && loader.item.logic) ? loader.item.logic[arguments.callee.name].apply({},arguments) : []}
    function redos          ()            { return (loader.item && loader.item.logic) ? loader.item.logic[arguments.callee.name].apply({},arguments) : []}
    function runFilterFunc  ()            { if(loader.item) loader.item[arguments.callee.name].apply({},arguments) }
    function get(idx)                     { return (loader.item) ? loader.item[arguments.callee.name].apply({},arguments) : undefined }
    function refreshDelegate(opt_iteratee){ return (loader.item) ? loader.item[arguments.callee.name].apply({},arguments) : undefined }
    function getSelected() {
        var arr = []
        if(selectedLen > 0 && selected) {
            for(var s in selected) {
                arr.push(model[selected[s]])
            }
        }
        return arr;
    }
    function isSelected(idx) {
        return selected && selected[idx] !== undefined && selected[idx] !== null ? true : false
    }
    function setCurrentIdx(idx) {
        if(lv)
            lv.currentIndex = idx;
    }
    function getDelegateInstance(idx) {
        if(!lv)
            return null;

        var items = lv.contentItem.children;
        for(var i = 0; i < items.length; ++i) {
            var item = items[i]
            if(item.imADelegate && item._index === idx)
                return item;
        }
        return false;
    }

    property var   selectionDelegate             : selectionDelegate
    property color selectionDelegateDefaultColor : "green"
    property var   highlightDelegate             : rootObject.selectionDelegate //will normally just change by changing selectionDelegate!
    property var   delegate                      : simpleDelegate
    property real  delegateCellHeight            : height * 0.1
    property var   blankDelegate                 : blankDelegate

    readonly property var selected : loader.item ? loader.item.logic.selected : {}
    readonly property int selectedLen : loader.item ? loader.item.logic.selectedLen : 0
    readonly property int count : lv ? lv.count : 0


    Loader {
        id : loader
        anchors.fill: parent
        Connections{
            target         : rootObject ? rootObject : null
            onModelChanged : {
                loader.updateLoader()
            }
        }

        Component.onCompleted: {
            loader.updateLoader();
        }

        function updateLoader() {
            if(!model){
                return loader.source = ""
            }
            var type = toString.call(model)
            console.log("gonna call", type)
            loader.source = type === '[object Array]' ?  "ArrangableListArray.qml": "ArrangableListModel.qml"
        }


        onLoaded : {
            item.model                          = Qt.binding(function() { return rootObject.model                         } )
            item.filterFunc                     = Qt.binding(function() { return rootObject.filterFunc                    } )
            item.selectionDelegate              = Qt.binding(function() { return rootObject.selectionDelegate             } )
            item.selectionDelegateDefaultColor  = Qt.binding(function() { return rootObject.selectionDelegateDefaultColor } )
            item.highlightDelegate              = Qt.binding(function() { return rootObject.highlightDelegate             } )
            item.delegate                       = Qt.binding(function() { return rootObject.delegate                      } )
            item.delegateCellHeight             = Qt.binding(function() { return rootObject.delegateCellHeight            } )
            item.blankDelegate                  = Qt.binding(function() { return rootObject.blankDelegate                 } )
        }


    }



    Component {
        id : blankDelegate
        Rectangle {
            border.width: 1
            color : 'transparent'
        }
    }
    Component {
        id : simpleDelegate
        Rectangle {
            border.width: 1
            property int index
            property var model
            Text {
                anchors.fill: parent
                font.pixelSize: height * 1/3
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
//                    text             : parent.model ? JSON.stringify(parent.model) : "N/A"
                text : typeof parent.model === 'string' ? parent.model : "x_x"
//                onTextChanged: console.log(text)
            }
        }
    }
    Component {
        id : selectionDelegate
        Rectangle {
            color : selectionDelegateDefaultColor
            opacity : 0.5
        }
    }
}
