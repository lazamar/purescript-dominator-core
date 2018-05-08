/* eslint-disable no-use-before-define */

function F6(fn) {
    return function(a) {
        return function(b) {
            return function(c) {
                return function(d) {
                    return function(e) {
                        return function(f) {
                            return fn(a, b, c, d, e, f);
                        };
                    };
                };
            };
        };
    };
}

function runOnce(fn) {
    var called = false;
    return function() {
        if (called) {
            return;
        }
        called = true;
        return fn.apply(null, arguments);
    };
}

function dispatchCmds(cmds, enqueue) {
    var i;
    var length = cmds.length;
    for (i = 0; i < length; i++) {
        var f = cmds[i];
        var run = function() {
            f(runOnce(enqueue))();
        };

        setTimeout(run, 0);
    }
}

function program(maybeParentNode, scheduler, normalRenderer, init, update, view) {
    // -- create renderer --

    return function() {
        var parentNode =
            maybeParentNode.constructor.name === "Just" ? maybeParentNode.value0 : document.body;

        var initialModel = init.value0;
        var initialCmds = init.value1;

        var renderer = normalRenderer(parentNode, view);
        var updateView = renderer(enqueue, initialModel);
        // ---------------------
        var model = initialModel;

        function onMessage(msg) {
            var tup = update(msg)(model);
            model = tup.value0;
            var cmds = tup.value1;
            updateView(model);
            dispatchCmds(cmds, enqueue);
        }

        var mainProcess = scheduler.spawn(onMessage);
        dispatchCmds(initialCmds, enqueue);

        function enqueue(msg) {
            scheduler.send(mainProcess, msg);
            return function() {};
        }
    };
}

exports.program_ = F6(program);
