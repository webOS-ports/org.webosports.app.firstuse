import QtQuick 2.6

/*
 * LunaService for tst_wifi_page.qml: it remembers the calls and lets the test
 * answer them. Like the real LuneOS.Service plugin, a reply always goes to the
 * first callback, returnValue false included; the second one is only for a
 * call that could not be sent at all, and gets a string.
 */
QtObject {
    property string name
    property bool usePrivateBus: false

    property var calls: []
    // Subscriptions other than findnetworks, apart from calls: {uri, args, onReply, onCallFailed, cancelled}.
    property var subscriptions: []
    property var findNetworksReply

    function call(uri, args, onReply, onCallFailed) {
        calls.push({ uri: uri, args: JSON.parse(args), onReply: onReply, onCallFailed: onCallFailed });
    }

    function subscribe(uri, args, onReply, onCallFailed) {
        if (uri === "luna://com.palm.wifi/findnetworks") {
            findNetworksReply = onReply;
            return null;
        }
        var sub = { uri: uri, args: JSON.parse(args), onReply: onReply, onCallFailed: onCallFailed, cancelled: false };
        sub.cancel = function() { sub.cancelled = true; };
        subscriptions.push(sub);
        return sub;
    }

    function callsTo(uri) {
        return calls.filter(function(c) { return c.uri === uri; });
    }

    function reply(call, payload) {
        call.onReply({ payload: typeof payload === "string" ? payload : JSON.stringify(payload) });
    }

    function networks(list) {
        findNetworksReply({ payload: JSON.stringify({ returnValue: true, foundNetworks: list }) });
    }
}
