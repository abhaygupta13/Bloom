var logMessages, saveLog;
$(document).ready(function () {
    logMessages = [];
    saveLog = false;
    $(".version").text("Softphone WDE Connector - core version : " + iwscore.getVersion());
    logsf.info = function (log) {
        return function () {
            var args = Array.prototype.slice.call(arguments);
            $(".logs ul").append("<li><p>{0}</p></li>".format(args));
            if (saveLog) {
                logMessages.push(args);
            }
            log.apply(console, args);
        };
    }(logsf.info);
});
function clearLog() {
    $(".logs ul").empty();
    logMessages = [];
}
function updateSaveLog() {
    var c = $("#saveLogs").prop('checked');
    saveLog = c;
}
function download() {
    var element = document.createElement('a');
    var content = "";
    for (var i = 0; i < logMessages.length; i++) {
        content += logMessages[i];
        content += "\n";
    }
    element.setAttribute('href', 'data:text/plain;charset=utf-8,'
        + encodeURIComponent(content));
    element.setAttribute('download', "log");
    element.style.display = 'none';
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
}
function toggleExpand() {
    var h = $('.logs').height();
    var lh = h == 0 ? 300 : 0;
    $('.logs').height(lh);
    $('.buttons').toggle();
    var t = h == 0 ? '-' : '+';
    $('#expand').prop('value', t);
}
function getVersion() {
    return iwscore.getVersion();
}
