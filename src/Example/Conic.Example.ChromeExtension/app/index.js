(function(window, document, chrome) {

    var hostName = "default.conic.host";
    var port = chrome.runtime.connectNative(hostName);
    var logItem = document.getElementById("log");
    var messageItem = document.getElementById("message");
    var buttonItem = document.getElementById("button");


    function appendLog(txt) {
        logItem.value += txt + "\n";
    }

    function sendMessage() {
        var msg = messageItem.value;
        if (port && port.postMessage) {
            appendLog("Me: " + msg);
            port.postMessage({ text: msg });
            messageItem.value = "";
        } else {
            appendLog("Error: Port is not active");
        }
    }

    buttonItem.addEventListener("click",
        function(event) {
            sendMessage();
        });

    messageItem.addEventListener("keyup",
        function(event) {
            event.preventDefault();
            if (event.keyCode === 13) {
                buttonItem.click();
            }
        });

    port.onMessage.addListener(function(msg) {
        appendLog("Winform: " + msg.Text);
    });
    port.onDisconnect.addListener(function() {
        console.log("Disconnected");
    });

})(window, document, chrome);