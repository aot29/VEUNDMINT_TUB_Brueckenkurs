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
      var result = new Promise(function(resolve, reject) {
        if (!DjangoAuthService.isAuthenticated()) {
          reject(new TypeError('not authenticated'));
        } else {
          resolve(DjangoAuthService.authAjaxPost('http://localhost:8000/user-data/', data));
        }
      });
      return result;
    }

    that.getUserData = function () {
      var result = new Promise(function(resolve, reject) {
        if (!DjangoAuthService.isAuthenticated()) {
          reject(new TypeError('not authenticated'));
        } else {
          resolve(DjangoAuthService.authAjaxGet('http://localhost:8000/user-data/'));
        }
      });
      return result;
    }

    that.getDataTimestamp = function () {
      return Promise.resolve(newerTimeStamp);
    }

    return that;
  }

  exports.DjangoStorageService = DjangoStorageService;

}));
