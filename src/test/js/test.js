var dataService = require('dataService.js');

var assert = require('assert');
var sinon = require('sinon');
var log = require('loglevel');
var Promise = require("bluebird");

describe('dataService', function() {

  describe('#subscribe / #unsubscribe', function() {

    it('should add storageService to strorageServices', function(done) {
      var FailService = function () {
        return {
          saveUserData : function () {
            return new Promise(function (resolve, reject) {
              reject(new TypeError('some getUsererror'));
            });
          },
          getUserData : function () {
            return new Promise(function (resolve, reject) {
              reject(new TypeError('Failservice rejected: getUserData'));
            });
          },
          name: 'failService',
          getDataTimestamp: function () {
            return Promise.reject(new TypeError('Failservice rejected: getDataTimestamp'));
          }
        }
      }
      fs = new FailService();
      dataService.subscribe(fs);
      var sub = dataService.getSubscribers()[0];
      assert.equal(sub.name, 'failService');
      var spy = sinon.spy(fs, "getDataTimestamp");
      dataService.getAllDataTimestamps().then(function(data) {


      }).catch(function(error) {
        assert.equal(error.message, 'Requests to all registered sstorageServices failed in getAllDataTimestamps');
        done();
      });

    });
  });
  describe('#mergeRecursive()', function() {
    beforeEach(function() {
      obj1 = {
        simple: 'attribute',
        scores: [
          {
            "points":99,
            "siteuxid":"VBKM01_VariablenTerme",
            "state":1,
            "maxpoints":4,
            "section":1,
            "id":"id1",
            "uxid":"ERX12",
            "intest":false,
            "rawinput":
            "1/4*pi*x*x*x",
            "value":0
          },
          {
            "points":1,
            "siteuxid":"VBKM01_VariablenTerme",
            "state":1,
            "maxpoints":4,
            "section":1,
            "id":"id2",
            "uxid":"ERX12",
            "intest":false,
            "rawinput":
            "1/4*pi*x*x*x",
            "value":0
          }
        ],
        history: {
          commits: [{
            id: 1,
            value: 'value2'
          },
          {
            id: 2,
            value: 'value2'
          }]
        }
      }
    });


    it('should return empty object when merging empty objects', function() {
      assert.deepEqual(dataService.mergeRecursive({},{}), {});
    });
    it('should return obj1 when merging with obj1 with empty object', function() {
      assert.deepEqual(dataService.mergeRecursive(obj1, {}), obj1);
    });
    it('should return obj1 when merging empty object with obj1', function() {
      assert.deepEqual(dataService.mergeRecursive({}, obj1), obj1);
    });
    it('should return obj1 when merging empty object with obj1', function() {
      assert.deepEqual(dataService.mergeRecursive({}, obj1), obj1);
    });
    it('should return obj1 when merging empty object with obj1', function() {
      assert.deepEqual(dataService.mergeRecursive(obj1, obj1), obj1);
    });
    it('should add attribute to obj if merging with obj having that attribute (and obj1 does not)', function() {
      assert.equal(dataService.mergeRecursive(obj1, {'wow': 'cool'}).wow, 'cool');
    });
    it('should insert into obj1 array if obj2 contains item with new id in same array', function() {
      assert.deepEqual(dataService.mergeRecursive({scores:[{id:1,a:'a'}]}, {scores: [{id:2, b:'b'}]}), {scores:[{id:1, a:'a'},{id:2, b:'b'}]});
    });
    it('should update obj1 array object if obj2 contains item with same id in same array (and insert)', function() {
      assert.deepEqual(dataService.mergeRecursive({scores:[{id:1,a:'a'}]}, {scores: [{id:1, a:'b', b:'b'}]}),
      {scores:[{id:1, a:'b', b:'b'}]});
    });
    it('should merge complex objects successfully', function() {
      merger = {
        newAttribute: '',
        scores: [
          //update this
          {
            id: "id1",
            points: 33,
            rawinput: 'xxx'
          },
          //insert this
          {
            "points":12,
            "siteuxid":"VBKM01_VariablenTerme",
            "state":1,
            "maxpoints":4,
            "section":1,
            "id":"id3",
            "uxid":"ERX12",
            "intest":true,
            "rawinput": "hallo",
            "value":0
          }
        ],
        history: {
          commits: [{
            id: 1,
            value: 'value2new'
          },
          {
            id: 2,
            value: 'value2new'
          }]
        }
      };

      successfullyMerged = {
        simple: 'attribute',
        newAttribute: '',
        scores: [
          {
            "points":33,
            "siteuxid":"VBKM01_VariablenTerme",
            "state":1,
            "maxpoints":4,
            "section":1,
            "id":"id1",
            "uxid":"ERX12",
            "intest":false,
            "rawinput": "xxx",
            "value":0
          },
          {
            "points":1,
            "siteuxid":"VBKM01_VariablenTerme",
            "state":1,
            "maxpoints":4,
            "section":1,
            "id":"id2",
            "uxid":"ERX12",
            "intest":false,
            "rawinput":
            "1/4*pi*x*x*x",
            "value":0
          },
          {
            "points":12,
            "siteuxid":"VBKM01_VariablenTerme",
            "state":1,
            "maxpoints":4,
            "section":1,
            "id":"id3",
            "uxid":"ERX12",
            "intest":true,
            "rawinput": "hallo",
            "value":0
          }
        ],
        history: {
          commits: [{
            id: 1,
            value: 'value2new'
          },
          {
            id: 2,
            value: 'value2new'
          }]
        }
      };
      assert.deepEqual(dataService.mergeRecursive(obj1, merger), successfullyMerged);

    });
  });
});
