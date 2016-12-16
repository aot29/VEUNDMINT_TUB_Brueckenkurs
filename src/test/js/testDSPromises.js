var dataService = require('../../files/js/dataService.js');
var LocalStorageService = require('../../files/js/storage/LocalStorageService.js').LocalStorageService;

var assert = require('assert');
var sinon = require('sinon');
var log = require('loglevel');

var chai = require('chai');
var expect = chai.expect;
var should = chai.should();
var chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);

describe('dataService', function() {

  var FailService, ls, fs, localStorage;

  var oldUserData = {"active":true,
  "layout":{"fontadd":0,"menuactive":true},"configuration":{"stylecolor":"0","CF_LOCAL":"1","CF_USAGE":"1","CF_TESTS":"1"},"scores":[{"uxid":"ER1","maxpoints":4,"points":4,"siteuxid":"VBKM01_VariablenTerme","section":1,
  "id":"QFELD_1.1.3.QF1","intest":false,"value":0,"rawinput":"5","state":1},{"uxid":"ER2","maxpoints":4,"points":4,"siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF2","intest":false,"value":0,"rawinput":"2",
  "state":1},{"uxid":"ER3","maxpoints":4,"points":4,"siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF3","intest":false,"value":0,"rawinput":"21","state":1},{"uxid":"LSFF1","maxpoints":4,"points":0,
  "siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF4","intest":false,"value":0,"rawinput":"","state":3},{"uxid":"LSFF2","maxpoints":4,"points":0,"siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF5","intest":false,
  "value":0,"rawinput":"","state":3},{"uxid":"ERX1","maxpoints":4,"points":0,"siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF6","intest":false,"value":0,"rawinput":"","state":3},{"uxid":"ERX2",
  "maxpoints":4,"points":0,"siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF7","intest":false,"value":0,"rawinput":"","state":3},{"uxid":"ERX3","maxpoints":4,"points":0,"siteuxid":"VBKM01_VariablenTerme","section":1,
  "id":"QFELD_1.1.3.QF8","intest":false,"value":0,"rawinput":"","state":3},{"uxid":"ERX11","maxpoints":4,"points":0,"siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF9","intest":false,"value":0,"rawinput":"",
  "state":3},{"uxid":"ERX12","maxpoints":4,"points":0,"siteuxid":"VBKM01_VariablenTerme","section":1,"id":"QFELD_1.1.3.QF10","intest":false,"value":0,"rawinput":"","state":3},{"uxid":"ERX13","maxpoints":4,"points":0,"siteuxid":"VBKM01_VariablenTerme",
  "section":1,"id":"QFELD_1.1.3.QF11","intest":false,"value":0,"rawinput":"","state":3}],"sites":[{"uxid":"SITE_VBKM_FIRSTPAGE","millis":14000,"maxpoints":1,"points":1,"id":"","intest":false,"section":""},
  {"uxid":"SITE_VBKM01_START","millis":3750,"maxpoints":1,"points":1,"id":"","intest":false,"section":""},{"uxid":"SITE_VBKM01_VariablenTerme","millis":13250,"maxpoints":1,"points":1,"id":"","intest":false,"section":""}],
  "favorites":[{"type":"Tipp","color":"00FF00","text":"Eingangstest probieren","pid":"html/sectionx2.1.0.html","icon":"test01.png"}],"history":{"globalmillis":31000,"commits":[["CHEX:13d0be76bf7aeafffd97da9cf1b2c4956d0aca8a_CID:(MFR-TUB;;10000;;DE-MINT)",
  1477582854737,1479127976366]]},"login":{"type":0,"vname":"","sname":"","username":"","password":"","email":"","variant":"std","sgang":"","uni":""},"signature":{"main":"MFR-TUB","version":"10000","localization":"DE-MINT"},
  "startertitle":"3.1 Willkommen","scrollTop":0};


  beforeEach(function() {

    //in the test environment there is no localstorage, we have to mock it
    localStorage = dataService.mockLocalStorage();

    //reset to init status before each test
    dataService.unsubscribeAll();
    dataService.emptyChangedData();

    //a service that will reject all requests
    FailService = function () {
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
    ls = new LocalStorageService();
  });

  describe('#subscribe / #unsubscribe', function() {
    it('should add/remove when subscribing/unsubscribing a storage service', function() {
      dataService.subscribe(fs);

      var subs = dataService.getSubscribers();
      assert.equal(subs.length, 1);
      assert.equal(subs[0].name, 'failService');

      dataService.subscribe(ls);
      subs = dataService.getSubscribers();
      assert.equal(subs.length, 2);
      assert.equal(subs[1].name, 'LocalStorageService');;

      dataService.unsubscribe(fs);

      subs = dataService.getSubscribers();
      assert.equal(subs.length, 1);
      assert.equal(subs[0].name, 'LocalStorageService');;

      dataService.unsubscribe(ls);
      subs = dataService.getSubscribers();
      assert.equal(subs.length, 0);

      dataService.subscribe(ls);
      dataService.subscribe(fs);
      dataService.getAllDataTimestamps();
      dataService.unsubscribeAll();

      subs = dataService.getSubscribers();
      assert.equal(subs.length, 0);

    });
  });

  describe('#getAllDataTimestamps', function() {

    it('should call subscribed services and not unsubscribed services', function() {

      dataService.subscribe(fs);
      assert.equal(dataService.getSubscribers().length, 1);

      var spyFsTimestamp = sinon.spy(fs, "getDataTimestamp");
      var spyLsTimestamp = sinon.spy(ls, "getDataTimestamp");

      dataService.getAllDataTimestamps();

      //failService getDataTimestamp was called once (by getAllDataTimestamps)
      expect(fs.getDataTimestamp.calledOnce).to.equal(true);
      expect(ls.getDataTimestamp.called).to.equal(false);

      dataService.subscribe(ls);
      dataService.getAllDataTimestamps();

      expect(fs.getDataTimestamp.calledTwice).to.equal(true);
      expect(ls.getDataTimestamp.calledOnce).to.equal(true);
    });

    it('should resolve if all registered services reject', function() {
      dataService.subscribe(fs);
      dataService.subscribe(ls);

      var service = dataService.getAllDataTimestamps();

      //service rejects, because all registered services reject
      return expect(service).to.be.fulfilled.then(function(data) {
            expect(data.length).to.equal(2);
             expect(data).to.have.deep.property('[0].status', 'rejected');
             expect(data).to.have.deep.property('[1].status', 'rejected');
             expect(data).to.have.deep.property('[0].error');
             expect(data).to.have.deep.property('[0].error');
      });
    });

    it('should resolve getAllDataTimestamps with correct timestamps', function() {
      dataService.subscribe(ls);
      dataService.subscribe(fs);

      //var spy = sinon.spy(ls, "getDataTimestamp");

      dataService.updateUserData({
        'name': 'test'
      });


      return dataService.syncUp().then(function(data) {
        return dataService.getAllDataTimestamps();
      }).then(function(data) {
        expect(data).to.have.deep.property('[0].serviceName', 'LocalStorageService');
        expect(data).to.have.deep.property('[0].status', 'resolved');
        expect(data).to.have.deep.property('[0].data').to.be.below(new Date().getTime());
        expect(data).to.have.deep.property('[1].serviceName', 'failService');
        expect(data).to.have.deep.property('[1].status', 'rejected');
      });
    });

  });

  describe('#syncUp', function() {

    it('should do nothing if no local changes to user data', function() {
      //resolve with message if no local Changes
      return dataService.syncUp().should.become('dataService: syncUp called without local changes, will do nothing.');
    });

    it('should do nothing if no subscribers registered', function() {
      //make local changes
      dataService.updateUserData({
        'name': 'test'
      });
      return dataService.syncUp().should.become('dataService: synUp called withot subscribers, will do nothing.');
    });

    it('should call saveUserData on all registered subscribers and resolve all statuses correctly', function() {
      dataService.subscribe(fs);
      dataService.subscribe(ls);

      dataService.updateUserData({
        test:'test'
      });

      var spyFsTimestamp = sinon.spy(fs, "saveUserData");
      var spyLsTimestamp = sinon.spy(ls, "saveUserData");

      return dataService.syncUp().should.be.fulfilled.then(function(data) {
        //registered services saveUserData was actually called
        expect(fs.saveUserData.calledOnce).to.be.true;
        expect(ls.saveUserData.calledOnce).to.be.true;

        data.should.have.deep.property(fs.name + '.status', 'error');
        data.should.have.deep.property(ls.name + '.status', 'success');
        //should have the user data we set above
        data.should.have.deep.property(ls.name + '.data.test', 'test');
      });
    });

  });

  describe('#syncDown', function() {
    it('should do nothing if no storageServices registered', function() {
      dataService.syncDown().should.become('dataService: synDown called without subscribers, will do nothing.');
    });
    it('should set objCache with most recent data from all registered services', function() {
      dataService.subscribe(fs);
      dataService.subscribe(ls);

      //construct a service that will hold the latest timestamp (until year 2270)
      function LsServiceClone() {};
      LsServiceClone.prototype = ls;

      var lsLater = new LsServiceClone();

      lsLater.getDataTimestamp = function () {return Promise.resolve(9477301997261)};
      lsLater.name = 'latestStorageService';

      dataService.subscribe(lsLater);

      //put some data into localstorage to get a timestamp
      return ls.saveUserData({test:'test'}).then(function(data) {
        return lsLater.saveUserData({test:'later'});
      }).then(function(data) {
        return dataService.syncDown();
      }).then(function(data) {
        //syncDown should return the data from lsLater
        data.should.have.property('test', 'later');
        //and objCache should be set to it
        dataService.getObjCache().should.have.property('test', 'later');
      });

    });
  });

  describe('chain promises', function() {
    it('should add requests to a "queue", when other request is pending', function() {
      //the nicest behaviour would be to alter changedData always even if objCache is not yet
      //resolved. then after resolving merging changed data in.

      //and syncup should not be called with empty obj cache
    });
  });

  describe('#importUserData', function() {
    it('should do nothing if no userdata was found', function() {
      importWithoutUserData = dataService.importUserData();
      expect(importWithoutUserData).to.have.property('status', 'success');
      expect(importWithoutUserData).to.have.property('message', 'no obj found for import');
    });
    it('should find userdata and import it', function() {

      var keys = ['', 'isobj_MFR-TUB'];

      for (var i = 0; i < keys.length; i++) {
        localStorage.setItem(keys[i], oldUserData);
        expect(dataService.importUserData()).to.have.property('status', 'success');

        //was imported
        expect(dataService.getChangedData()).to.have.deep.property('scores[0].uxid',"ER1");
        expect(dataService.getChangedData()).to.have.deep.property('scores[0].rawinput',"5");

        //old data was deleted
        expect(localStorage.getItem(keys[i])).to.equal(null);
      }
    });
  })

});
