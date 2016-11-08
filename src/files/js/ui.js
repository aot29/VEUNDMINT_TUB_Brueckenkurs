(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['exports', 'loglevel'], function (exports, log) {
            factory((root.commonJsStrictGlobal = exports), log);
        });
    } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
        // CommonJS
        factory(exports, require('loglevel'));
    } else {
        // Browser globals
        factory((root.commonJsStrictGlobal = {}), root.log);
    }
}(this, function (exports, log) {

    log.debug('ui.js: loaded');
    //use b in some fashion.

    // attach properties to the exports object to define
    // the exported module properties.
    exports.action = function () {};
}));
