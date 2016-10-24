(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['exports', 'IStorageService', 'veHelpers'], function (exports, IStorageService, veHelpers) {
      factory((root.DjangoStorageService = exports), IStorageService, veHelpers);
    });
  } else if (typeof exports === 'object' && typeof exports.nodeName !== 'string') {
    // CommonJS
    factory(exports, require('./IStorageService.js'), require('../veHelpers.js'));
  } else {
    // Browser globals
    factory((root.DjangoStorageService = {}), root.IStorageService, root.veHelpers);
  }
}(this, function (exports, IStorageService, veHelpers) {

  var DjangoStorageService = function () {
    var that = IStorageService.IStorageService();
    djUserData = {};
    newerTimeStamp = 159292929929290;

    that.name = 'DjangoStorageService';

    that.saveUserData = function (data) {
      console.log('djangoStorageService saveUserData called');
      var result = new Promise(function (resolve, reject) {
        setTimeout(function() {
          console.log('after 2 secs');
          djUserData = data;
          resolve(djUserData);
        }, 2000);
      });
      return result;
    }

    that.getUserData = function () {
      console.log('djangoStorageService getUserData called');
      var result = new Promise(function (resolve, reject) {
        setTimeout(function() {
          console.log('after 2 secs');
          djUserData.timestamp = newerTimeStamp;
          resolve(djUserData);
        }, 2000);
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
