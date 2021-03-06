/*
    Copyright (C) 2015 Nile Group
    http://nilegroup.org

    Meikade is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Meikade is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtGraphicalEffects 1.0
import AsemanTools 1.0 as AT
import Meikade 1.0
import "."

AT.AsemanMain {
    id: main
    width: 500
    height: 680
    color: "#000000"
    mainFrame: main_scene

    property string mainTitle: qsTr("Meikade")

    property string globalPoemFontFamily: poem_texts_font.name
    property real globalZoomAnimDurations: animations? 500 : 0
    property real globalFontDensity: 0.9

    property alias headerHeight: header.height
    property bool backButton: !AT.Devices.isAndroid
    property bool flatDesign: true

    property alias catPage: cat_page
    property alias materialDesignButton: md_button

    property bool blockBack: false
    property bool fontsLoaded: false

    property bool animations: Meikade.animations
    property alias networkFeatures: network_features

    property variant areaFrame: area_frame
    property variant mainDialog

    property variant menuItem
    property variant init_wait

    onMenuItemChanged: {
        if( menuItem )
            AT.BackHandler.pushHandler( main, main.hideMenuItem )
        else
            AT.BackHandler.removeHandler(main)
    }

    QtObject {
        id: privates
        property bool animations: true
    }

    Timer {
        id: main_dialog_destroyer
        interval: 400
        repeat: false
        onTriggered: if(item) item.destroy()
        property variant item
    }

    Component.onCompleted: {
        if( !Database.initialized() ) {
            var initWaitComponent = Qt.createComponent("InitializeWait.qml")
            init_wait = initWaitComponent.createObject(main)
        }

        Meikade.runCount++
        if( Meikade.runCount == 2 )
            showFavoriteMessage()
    }

    Timer {
        interval: 4000
        onTriggered: loadFonts()
        Component.onCompleted: start()
    }

    XmlDownloaderModel {
        id: xml_model
    }

    NetworkFeatures {
        id: network_features
        activePush: Meikade.activePush
        onShowMessage: messageDialog.show(network_message_component, {"message":message, "destUrl":url})
    }

    Connections {
        target: Meikade
        onCloseRequest: AT.AsemanApp.back()
    }

    Connections {
        target: AT.AsemanApp
        onBackRequest: {
            if(timer_delayer.running)
                return

            timer_delayer.start()
            var res = AT.BackHandler.back()
            if( !res && !AT.Devices.isDesktop )
                Meikade.close()

            main.mainTitle = search_bar.hide? qsTr("Meikade") : ""
        }
    }

    Timer {
        id: timer_delayer
        interval: 300
        repeat: false
    }

    Keys.onEscapePressed: AT.AsemanApp.back()

    Connections {
        target: Database
        onCopyError: showCopyErrorMessage()
        onInitializeFinished: {
            if( init_wait ) {
                init_wait.visible = false
                init_wait.destroy()
            }

            if(AT.AsemanApp.applicationVersion == "3.1.1" && Meikade.runCount > 1)
                showNews(1)
            else
                Meikade.setMeikadeNews(1, true)
        }
    }

    Connections {
        target: Backuper
        onActiveChanged: {
            if( Backuper.active ) {
                showWaitDialog()
                UserData.disconnect()
                main.blockBack = true
            } else {
                hideMainDialog()
                UserData.reconnect()
                main.blockBack = false
            }
        }
    }

    FontLoader {
        id: poem_texts_font
        source: Meikade.resourcePath + "/fonts/" + Meikade.poemsFont + ".ttf"
        onStatusChanged: if(status == FontLoader.Ready) AT.AsemanApp.globalFont.family = name
    }

    Item {
        id: main_scene
        width: parent.width
        height: parent.height
        clip: true
        transformOrigin: Item.Center
        scale: search_bar.hide && !main.menuItem? 1 : 0.7

        Behavior on scale {
            NumberAnimation { easing.type: Easing.OutCubic; duration: 400 }
        }

        Item {
            id: frame
            y: 0
            x: 0
            width: main.width
            height: main.height
            clip: true

            property bool anim: false

            Behavior on y {
                NumberAnimation { easing.type: Easing.OutCubic; duration: frame.anim?animations*400:0 }
            }

            Item {
                id: area_item
                y: padY
                height: parent.height
                anchors.left: parent.left
                anchors.right: parent.right

                property real padY: 0

                Behavior on padY {
                    NumberAnimation { easing.type: Easing.OutCubic; duration: animations*400 }
                }

                Item {
                    id: area_frame
                    width: parent.width
                    height: parent.height

                    Behavior on scale {
                        NumberAnimation { easing.type: Easing.InOutCubic; duration: animations*globalZoomAnimDurations }
                    }
                    Behavior on x {
                        NumberAnimation { easing.type: Easing.InOutCubic; duration: animations*globalZoomAnimDurations }
                    }
                    Behavior on y {
                        NumberAnimation { easing.type: Easing.InOutCubic; duration: animations*globalZoomAnimDurations }
                    }

                    CategoryPage {
                        id: cat_page
                        anchors.fill: parent

                        MaterialDesignButton {
                            id: md_button
                            anchors.fill: parent
                            layoutDirection: Qt.RightToLeft
                            onHafezOmenRequest: cat_page.showHafezOmen()
                            onRandomPoemRequest: cat_page.showRandomCatPoem()
                            onSearchRequest: search_bar.show()
                        }
                    }
                }
            }

            Item {
                id: header_frame
                y: 0
                anchors.left: parent.left
                anchors.right: parent.right
                height: AT.Devices.standardTitleBarHeight+AT.View.statusBarHeight

                Behavior on y {
                    NumberAnimation { easing.type: Easing.OutCubic; duration: animations*400 }
                }

                Item {
                    id: header
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: AT.Devices.standardTitleBarHeight

                    AT.Button{
                        id: back_btn
                        anchors.left: parent.left
                        anchors.top: parent.top
                        height: parent.height
                        radius: 0
                        normalColor: "#00000000"
                        highlightColor: "#88666666"
                        textColor: "#ffffff"
                        icon: "icons/back_light_64.png"
                        iconHeight: 16*AT.Devices.density
                        fontSize: 11*globalFontDensity*AT.Devices.fontDensity
                        textFont.bold: false
                        visible: backButton && cat_page.count != 1
                        onClicked: {
                            AT.AsemanApp.back()
                            AT.Devices.hideKeyboard()
                        }
                    }
                }
            }
        }
    }

    FastBlur {
        anchors.fill: main_scene
        source: main_scene
        radius: 32*AT.Devices.density
        opacity: main_dialog_frame.opacity
        visible: main_dialog_frame.visible
    }

    Rectangle {
        id: main_dialog_frame
        anchors.fill: parent
        transformOrigin: Item.Center
        opacity: main.mainDialog? 1 : 0
        visible: opacity != 0
        color: "#aa000000"

        MouseArea {
            anchors.fill: parent
        }

        Behavior on opacity {
            NumberAnimation { easing.type: Easing.OutCubic; duration: animations*400 }
        }
    }

    Item {
        anchors.fill: parent

        SearchBar {
            id: search_bar
            width: parent.width
            y: hide? parent.height : 0
            height: parent.height
            headerRightMargin: menu_button.width

            Timer {
                id: search_bar_anim
                interval: 400
                onTriggered: inited = true
                Component.onCompleted: start()
                property bool inited: false
            }

            Behavior on y {
                NumberAnimation { easing.type: Easing.OutCubic; duration: search_bar_anim.inited? 400 : 0 }
            }

            onHideChanged: {
                if(hide) {
                    menu_item_frame.z = 1
                    search_bar.z = 0
                } else {
                    menu_item_frame.z = 0
                    search_bar.z = 1
                }

                if( !hide ) {
                    if( main.menuItem )
                        hideMenuItem()
                }
                if( !hide )
                    AT.BackHandler.pushHandler( search_bar_back, search_bar_back.hide )
                else
                    AT.BackHandler.removeHandler(search_bar_back)
            }

            QtObject {
                id: search_bar_back
                function hide(){
                    search_bar.hide = true
                }
            }
        }

        Item {
            id: menu_item_frame
            anchors.fill: parent
            clip: true
        }
    }

    AT.SideMenu {
        id: sidebar
        anchors.fill: parent
        layoutDirection: Qt.RightToLeft
        delegate: MouseArea {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "#f0f0f0"
            }

            MainMenu {
                anchors.fill: parent
                anchors.bottomMargin: AT.View.navigationBarHeight
                onSelected: {
                    if( main.menuItem ) {
                        if(fileName.length == 0)
                            main.menuItem.close()
                        else
                            main.menuItem.goOutAndClose()
                    }
                    if( !search_bar.hide ) {
                        if( search_bar.viewMode )
                            if( BackHandler )
                                AT.AsemanApp.back()

                        search_bar.hide = true
                    }

                    if( fileName.length == 0 ) {
                        cat_page.home()
                        menuItem = null
                    }
                    else
                    if( fileName.slice(0,4) == "cmd:" ) {
                        var cmd = fileName.slice(4)
                        if( cmd == "search" ) {
                            search_bar.show()//Meikade.timer(400,search_bar,"show")
                            networkFeatures.pushAction("Search (from menu)")
                        }
                    } else {
                        var item = main_menu_item_component.createObject(menu_item_frame)
                        item.anchors.fill = menu_item_frame
                        item.z = 1000

                        var ocomponent = Qt.createComponent(fileName)
                        var object = ocomponent.createObject(item)
                        item.item = object

                        menuItem = item
                    }

                    sidebar.discard()
                }
            }
        }
    }

    Item {
        id: menu_button
        height: AT.Devices.standardTitleBarHeight
        width: menu_img.width + menu_img.anchors.rightMargin + menu_text.width + menu_text.anchors.rightMargin + 12*AT.Devices.density
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: AT.View.statusBarHeight + main_scene.y

        AT.MenuIcon {
            id: menu_img
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: y
            height: 20*AT.Devices.density
            width: height
            ratio: sidebar.percent
            layoutDirection: Qt.RightToLeft
        }

        Text {
            id: menu_text
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: menu_img.left
            anchors.rightMargin: 8*AT.Devices.density
            font.family: AT.AsemanApp.globalFont.family
            font.pixelSize: 11*globalFontDensity*AT.Devices.fontDensity
            text: main.mainTitle
            color: "#ffffff"
            opacity: 1-sidebar.percent
        }

        Rectangle {
            anchors.fill: sidebar.showed? menu_img : parent
            anchors.margins: sidebar.showed? -menu_img.y+8*AT.Devices.density : 0
            radius: 3*AT.Devices.density
            color: "#33ffffff"
            visible: menu_area.pressed
        }

        MouseArea {
            id: menu_area
            anchors.fill: parent
            onClicked: {
                if(sidebar.showed)
                    sidebar.discard()
                else
                    sidebar.show()
            }
        }
    }

    Timer {
        id: start_report_timer
        interval: 2000
        repeat: false
        onTriggered: networkFeatures.pushDeviceModel(AT.Devices.deviceName, AT.Devices.lcdPhysicalSize, AT.Devices.density)
        Component.onCompleted: start()
    }

    function hideMenuItem() {
        if(!main.menuItem)
            return

        main.menuItem.close()
        main.menuItem = 0
    }

    function setCurrentChapter( id ){
        quran_frame.chapterAT.Viewer.chapter = id
    }

    function showMainDialog( item ){
        hideMainDialog()
        item.parent = main_dialog_frame
        mainDialog = item
    }

    function hideMainDialog(){
        if( !mainDialog )
            return
        if( main_dialog_destroyer.item )
            main_dialog_destroyer.item.destroy()

        main_dialog_destroyer.item = mainDialog
        main_dialog_destroyer.restart()
        mainDialog = 0
    }

    function showWaitDialog(){
        var component = Qt.createComponent("WaitDialog.qml")
        var item = component.createObject(main_dialog_frame)
        showMainDialog(item)
        return item
    }

    function showFavoriteMessage() {
        var component = Qt.createComponent("FavoriteMessage.qml")
        messageDialog.show(component)
    }

    function showNews(num) {
        if(Meikade.meikadeNews(num))
            return

        var component = Qt.createComponent("MeikadeNews" + num + ".qml")
        messageDialog.show(component)
        Meikade.setMeikadeNews(num, true)
    }

    function showCopyErrorMessage() {
        var component = Qt.createComponent("CopyErrorMessage.qml")
        messageDialog.show(component)
    }

    function back(){
        return AT.AsemanApp.back()
    }

    function loadFonts() {
        if(fontsLoaded)
            return

        var fonts = Meikade.availableFonts()
        for(var i=0; i<fonts.length; i++)
            if(fonts[i] != "DroidNaskh-Regular")
                font_loader_component.createObject(main, {"fontName": fonts[i]})

        fontsLoaded = true
    }

    Component {
        id: font_loader_component
        FontLoader{
            source: Meikade.resourcePath + "/fonts/" + fontName + ".ttf"
            property string fontName
        }
    }

    Component {
        id: network_message_component
        AT.MessageDialogOkCancelWarning {
            property string destUrl
            onOk: {
                Qt.openUrlExternally(destUrl)
                AT.AsemanApp.back()
            }
        }
    }

    Component {
        id: main_menu_item_component
        MainMenuItem {}
    }
}
