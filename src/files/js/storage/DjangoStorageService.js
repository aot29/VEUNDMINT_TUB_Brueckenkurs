(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'IStorageService', 'DjangoAuthService', 'veHelpers', 'request', 'request-promise'], function (exports, IStorageService, DjangoAuthService, veHelpers, request, rp) {
      factory((root.DjangoStorageService = exports), IStorageService, DjangoAuthService, veHelpers, request, rp);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./IStorageService.js'), require('./DjangoAuthService.js'), require('../veHelpers.js'), require('request'), require('request-promise'));
  } else {
    // Browser globals
    factory((root.DjangoStorageService = {}), root.IStorageService, root.DjangoAuthService, root.veHelpers, root.request, root.rp);
  }
}(this, function (exports, IStorageService, DjangoAuthService, veHelpers, request, rp) {

  var DjangoStorageService = function (settings) {
    var that = IStorageService.IStorageService();
    djUserData = {};
    newerTimeStamp = 159292929929290;

    that.name = 'DjangoStorageService';

    that.saveUserData = function (data) {

    }

    that.getUserData = function () {
      console.log('djangoStorageService getUserData called');
    }

    that.getDataTimestamp = function () {
      return Promise.resolve(newerTimeStamp);
    }

    return that;
  }

  exports.DjangoStorageService = DjangoStorageService;

}));
