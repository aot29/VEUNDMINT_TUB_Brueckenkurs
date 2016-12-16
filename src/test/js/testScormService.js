var dataService = require('../../files/js/dataService.js');
var DjangoStorageService = require('../../files/js/storage/ScormStorageService.js').DjangoStorageService;
var LocalStorageService = require('../../files/js/storage/LocalStorageService.js').LocalStorageService;
var scormBridge = require('../../files/js/scormBridge.js');
var ScormStorageService = require('../../files/js/storage/ScormStorageService.js');
var api, scormLocal = require('scorm-local');

var assert = require('assert');
var sinon = require('sinon');
var log = require('loglevel');

var dataFixtures = require('./dataFixtures.js');

var Promise = require('bluebird');

var chai = require('chai');
var expect = chai.expect;
var should = chai.should();
var chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);
chai.use(require('chai-things'));

var request = require('request');

describe('ScormStorageService', function() {

  beforeEach(function() {
    api = scormLocal('some-sco');
    scormBridge.init(api);
    api.flush();
  });

  describe('#getDataTimestamp', function() {
    it('should return -1 promise', function() {
      return ScormStorageService.getDataTimestamp().should.be.fulfilled.then(function(data) {
        expect(data).to.equal(-1);
        })
    });
  });

  describe('#saveUserData', function() {
      //as there is a size limitation it should do nothing but return a string
      return ScormStorageService.saveUserData({}).should.be.fulfilled.then(function(data) {
       expect(data).to.equal('data theoretically saved in scorm');
    });
  }
)

//   describe('#saveUserData / #getUserData', function() {
//     it('should set / get arbitrary json user data correctly', function() {
//       var userData = dataFixtures.getComplexUserData();
//       console.log(userData.scores.length);
//       console.log(userData.sites.length);
//
//       return ScormStorageService.saveUserData(userData).should.be.fulfilled.then(function(data) {
//           console.log(data.scores.length);
//           console.log(data.sites.length);
//           expect(data).to.deep.equal(userData);
// //         return ScormStorageService.getUserData();
//       })
//     });
//   });

});
