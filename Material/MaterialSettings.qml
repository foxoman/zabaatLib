import QtQuick 2.4
import Zabaat.Material 1.0
import QtQuick.Window 2.2

pragma Singleton
Item {
    property bool  editMode      : false
    property alias font          : settings_Font
    property alias style         : settings_Style
    property alias units         : settings_Units
    readonly property bool loaded: Fonts.loaded && Colors.loaded && Toasts.loaded && WindowManager.loaded && Units.loaded

    function init(mainWindow, mainItem){
//        console.log("MaterialSettings.init")
        if(!__privates.hasInit && mainWindow){
            units.mainWindowWidth  = Qt.binding(function() { return mainWindow.width });    //this is auto gonna change our units one
            units.mainWindowHeight = Qt.binding(function() { return mainWindow.height});    //this is auto gonna change our units one

            Units.pixelDensity = units.pixelDensity = Screen.pixelDensity
            Units.multiplier   = units.scaleMulti
//            Units.dpi          = units.dpi;

            console.log("SCALE MULTI IS", units.scaleMulti)

            Fonts.font1        = font.font1
            Fonts.font2        = font.font2
            Fonts.dir          = font.dir
            Colors.dir         = style.colorsPath
            Colors.defaultColorTheme = style.defaultColors


            WindowManager.mainItem = mainItem;
            WindowManager.init(mainWindow)
            Toasts.init(WindowManager);

            Units.loaded = true;
//            console.log("UNITS LOADED")
            __privates.hasInit = true
        }
    }

    QtObject {
        id : settings_Font
        property string dir  : Qt.resolvedUrl("./fonts")
        property string font1: "FontAwesome"
        property string font2: "Arial"
        onDirChanged         : Fonts.dir = font.dir
    }

    QtObject {
        id : settings_Style
        property string skinsPath    : Qt.resolvedUrl("./components/skins/")
        property string colorsPath   : Qt.resolvedUrl("./components/colors/")
        property string defaultColors: "default"
        property string defaultSkin  : "default"

        onColorsPathChanged   : Colors.dir = colorsPath
        onDefaultColorsChanged: Colors.defaultColorTheme = defaultColors
    }

    QtObject {
        id : settings_Units
        property real pixelDensity : 4.4
        property real scaleMulti   : 1
        property real defaultWidth : 1920   //Pages are inited to this
        property real defaultHeight: 1080   //Pages are inited to this
        property real mainWindowWidth : 1920
        property real mainWindowHeight : 1080

        onPixelDensityChanged : Units.pixelDensity  = pixelDensity
        onScaleMultiChanged   : Units.multiplier    = scaleMulti
        onDefaultWidthChanged : Units.defaultWidth  = defaultWidth
        onDefaultHeightChanged: Units.defaultHeight = defaultHeight
        onMainWindowWidthChanged : Units.mainWindowWidth = mainWindowWidth
        onMainWindowHeightChanged : Units.mainWindowHeight = mainWindowHeight
    }

    QtObject {
        id : __privates
        property bool hasInit : false
    }


    Component.onCompleted: init()


}
