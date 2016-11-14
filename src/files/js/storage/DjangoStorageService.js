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
    newerTimeStamp = 2929929290;

    that.name = 'DjangoStorageService';

    that.saveUserData = function (data, async) {
      console.log('saving django user data', data);
      return DjangoAuthService.authAjaxPost('http://localhost:8000/user-data/', data, async);
    }

    that.getUserData = function () {
      return DjangoAuthService.authAjaxGet('http://localhost:8000/user-data/');
    }

    that.getDataTimestamp = function () {
      return DjangoAuthService.authAjaxGet('http://localhost:8000/user-data-timestamp/');
      // return Promise.resolve(newerTimeStamp);
    }

    that.sendUserFeedback = function (data) {
      return DjangoAuthService.authAjaxPost('http://localhost:8000/user-feedback/', {rawfeedback: JSON.stringify(data)});
    }

    that.usernameAvailable = DjangoAuthService.usernameAvailable;
    that.registerUser = DjangoAuthService.registerUser;

    return that;
  }

  exports.DjangoStorageService = DjangoStorageService;

}));
