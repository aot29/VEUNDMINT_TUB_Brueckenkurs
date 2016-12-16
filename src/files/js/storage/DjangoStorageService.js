(function (root, factory) {
  /* istanbul ignore next */
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'veSettings', 'IStorageService', 'DjangoAuthService', 'veHelpers', 'request', 'request-promise'], function (exports, IStorageService, DjangoAuthService, veHelpers, request, rp) {
      factory((root.DjangoStorageService = exports), veSettings, IStorageService, DjangoAuthService, veHelpers, request, rp);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('../veSettings.js'), require('./IStorageService.js'), require('./DjangoAuthService.js'), require('../veHelpers.js'), require('request'), require('request-promise'));
  } else {
    // Browser globals
    factory((root.DjangoStorageService = {}), root.veSettings, root.IStorageService, root.DjangoAuthService, root.veHelpers, root.request, root.rp);
  }
}(this, function (exports, veSettings, IStorageService, DjangoAuthService, veHelpers, request, rp) {

  var DjangoStorageService = function (settings) {

    var settings = {
        'URL_USER_DATA': veSettings.DJANGO_SERVER_URL + '/user-data/',
        'URL_TIMESTAMP': veSettings.DJANGO_SERVER_URL + '/user-data-timestamp/',
        'URL_USER_FEEDBACK' : veSettings.DJANGO_SERVER_URL + '/user-feedback/'
    }

    var that = IStorageService.IStorageService();

    that.name = 'DjangoStorageService';

    that.saveUserData = function (data, async) {
      return DjangoAuthService.authAjaxPost(settings.URL_USER_DATA, data, async);
    }

    that.getUserData = function () {
      return DjangoAuthService.authAjaxGet(settings.URL_USER_DATA);
    }

    that.getDataTimestamp = function () {
      return DjangoAuthService.authAjaxGet(settings.URL_TIMESTAMP);
    }

    that.sendUserFeedback = function (data) {
      return DjangoAuthService.authAjaxPost(settings.URL_USER_FEEDBACK, {rawfeedback: JSON.stringify(data)});
    }

    //TODO to be unneeded when refactoring again the service
    that.usernameAvailable = DjangoAuthService.usernameAvailable;
    that.registerUser = DjangoAuthService.registerUser;
    that.authenticate = DjangoAuthService.authenticate;
    that.isAuthenticated = DjangoAuthService.isAuthenticated;
    that.logout = DjangoAuthService.logout;
    that.getUserCredentials = DjangoAuthService.getUserCredentials;
    that.changeUserData = DjangoAuthService.changeUserData;

    return that;
  }

  exports.DjangoStorageService = DjangoStorageService;

}));
