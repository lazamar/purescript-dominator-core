/* eslint-disable no-use-before-define, complexity */

var scheduler = (function() {
    var working = false;
    var workQueue = [];
    var pid = 0;

    // Maximum number of times that we will run entire updates
    // consecutively. If we hit the max it means that we are
    // propbably in a loop
    var MAX_STEPS = 10000;

    // Create a process
    function spawn(onMessage) {
        var process = {
            id: ++pid,
            onMessage: onMessage,
            messageQueue: []
        };

        return process;
    }

    // Send a msg to a process
    function send(process, msg) {
        process.messageQueue.push(msg);
        enqueue(process);
    }

    function enqueue(msg) {
        workQueue.push(msg);

        if (!working) {
            setTimeout(work, 0);
            working = true;
        }
    }

    function work() {
        var process;
        var steps = 0;

        while (steps < MAX_STEPS && (process = workQueue.shift())) {
            var msg;
            if ((msg = process.messageQueue.shift())) {
                process.onMessage(msg);
            }
            steps = steps + 1;
        }

        if (!msg) {
            working = false;
            return;
        }
        setTimeout(work, 0);
    }

    return {
        spawn: spawn,
        send: send
    };
})();

exports.scheduler = scheduler;
