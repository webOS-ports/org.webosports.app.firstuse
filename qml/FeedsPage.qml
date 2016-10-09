/*
 * Copyright (C) 2015-2016 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import LunaNext.Common 0.1
import LuneOS.Service 1.0

BasePage {
    title: "Preware Feeds"
    forwardButtonSourceComponent: forwardButton
    property bool acceptedWarning: false

    Rectangle {
        id: overlayRect
        color: "#000000"
        opacity: 0.9
        anchors.fill: parent
        visible: false
        z: 1

        property Item originDelegate

        function show(delegate) {
            overlayRect.originDelegate = delegate;
            overlayRect.visible=true;
        }

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id: messageRect
            width: window.width * 0.8 
            radius: Units.gu(0.8)
            color: "#4c4c4c"
            anchors.centerIn: parent
            height: title.height + body.contentHeight + Units.gu(8)
            z: 2
            Text {
                id: title
                text: "Non-webos-ports Feed"
                font.bold: true
                color: "white"
                anchors.top: parent.top
                anchors.topMargin: Units.gu(1)
                anchors.left: parent.left
                anchors.leftMargin: Units.gu(1)
                font.pixelSize: FontUtils.sizeToPixels("16pt")
                font.family: "Prelude"
            }

            Text {
                id: body
                text: "<p>By adding a non-webos-ports feed, you're trusting both the package developers and feed maintainer, and that their sites haven't been hacked.</p><br><p>You take full responsibility for any and all potential outcomes that may occur as a result of doing so, including (but not limited to): loss of warranty, loss of all data, loss of all privacy, security vulnerabilities and device damage.</p>"
                color: "white"
                anchors.top: title.bottom
                anchors.topMargin: Units.gu(1)
                anchors.left: parent.left
                anchors.leftMargin: Units.gu(1)
                font.pixelSize: FontUtils.sizeToPixels("16pt")
                font.family: "Prelude"
                wrapMode: Text.WordWrap
                width: parent.width - Units.gu(2)
            }



            StackButton {
                id: okButton
                    text: "OK"
                    width: messageRect.width / 2 - Units.gu(1)
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        leftMargin: Units.gu(1)
                        bottomMargin: Units.gu(1)
                    }
                    onClicked: {
                        acceptedWarning = true
                        if(overlayRect.originDelegate)
                        {
                            overlayRect.originDelegate.warningAccepted()
                        }
                        overlayRect.visible = false
                    }
                }


            StackButton {
                id: backButton
                width: messageRect.width / 2 - Units.gu(1)
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: Units.gu(1)
                    bottomMargin: Units.gu(1)
                }
                text: "Cancel"
                backArrow: true

                onClicked:
                {
                    overlayRect.visible = false
                }
            }
        }
    }


    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component.onCompleted: {
        service.call("luna://org.webosinternals.ipkgservice/getConfigs", JSON.stringify({}), getFeedsSuccess,
                           getFeedsFailure)
    }

    function getFeedsSuccess(message) {

        var response = JSON.parse(message.payload)
        feedModel.clear()

        if (response.configs && response.configs.length > 0) {
            for (var n = 0; n < response.configs.length; n++) {
                var config = response.configs[n]
                var configTmp = config.contents.split(' ')

                feedModel.append({
                                       configConfig: config.config,
                                       configName: configTmp[1],
                                       configEnabled: config.enabled,
                                       configURL: configTmp[2]
                                   })
            }
        }
    }

    function getFeedsFailure(message) {
        console.log("Unable to get Preware feeds")
    }

    ListModel {
        id: feedModel
    }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        Text {
            id: label1
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "Select Preware (LuneOS App Catalog) feeds to enable"
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        ListView {
            id: feedList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing

            clip: true

            model: feedModel

            delegate: Rectangle {

                function warningAccepted() {
                    setFeedStatus (configConfig, !configEnabled);
                }

                id: delegate
                anchors.right: parent.right
                anchors.left: parent.left
                height: Units.gu(6)
                color: "transparent"

                Text {
                    id: config
                    anchors.top: parent.top
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    text: configConfig.substring(0, configConfig.length-5)
                    font.bold: true
                }

                Text {
                    id: configContents
                    anchors.top: config.bottom
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("11pt")
                    text: configURL
                }

                Switch {
                    id: feedToggle
                    anchors.right: parent.right
                    checked: configEnabled
                    style: SwitchStyle {
                        groove: Image {
                            id: grooveImage
                            source: feedToggle.checked ? "images/toggle-button-on.png" : "images/toggle-button-off.png"
                            width: Units.gu(8)
                            height: Units.gu(4)

                            Text {
                                color: "white"
                                text: "ON"
                                font.bold: true
                                font.family: "Prelude"
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                visible: feedToggle.checked
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: Units.gu(1.25)
                            }
                            Text {
                                color: "white"
                                text: "OFF"
                                font.bold: true
                                font.family: "Prelude"
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                visible: !feedToggle.checked
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Units.gu(1)
                            }

                        }
                        handle: Rectangle {
                            color: "transparent"
                        }
                    }
                    onClicked:
                    {
                        //revert check
                        checked = Qt.binding( function () { return configEnabled; } );
                        if (configConfig !== "webos-ports.conf" && !acceptedWarning) {
                            overlayRect.show(delegate)
                        } else {
                            setFeedStatus (configConfig, !configEnabled)
                        }
                    }
                }

                function setFeedStatus (config, enabled) {
                    var params =
                    {
                        config: config,
                        enabled: enabled
                    }

                    service.call("luna://org.webosinternals.ipkgservice/setConfigState", JSON.stringify(params), function () {setConfigSuccess(params);},
                                       setConfigFailure)
                }

                function setConfigSuccess(params) {
                    console.log("Successfully set feed config");
                    for (var i=0; i<feedModel.count; i++) {
                        var feed = feedModel.get(i);
                        if (feed.configConfig === params.config) {
                            feedModel.setProperty(i, "configEnabled", params.enabled);
                        }
                    }
                }

                function setConfigFailure(message) {
                    var response = JSON.parse(message.payload)
                    console.log("Failed to set feed config: "+response.errorText)
                }
            }
        }

        Item { // spacer
            height: Units.gu(2)
            width: Units.gu(1) // needed else it will be ignored
        }
    }

    Component {
        id: forwardButton
        StackButton {
            text: "Continue"
            onClicked: {
                pageStack.next();
            }
        }
    }
}
