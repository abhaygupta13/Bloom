var logsf = {
    info: (msg, ...args) => {
        if (console && console.info) {
            args.forEach(function (a, i) {
                try {
                    args[i] = JSON.stringify(a);
                }
                catch (e) { }
            });
            console.info("[" + new Date().toISOString() + "] cti-sfdc *** " + msg, ...args);
        }
    },
};
