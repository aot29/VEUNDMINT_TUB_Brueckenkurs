var dataService = require('../../files/js/dataService.js');

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
  beforeEach(function() {

    dataService.mockLocalStorage();
    dataService.unsubscribeAll();
    dataService.emptyChangedData();

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
    ls = new dataService.localStorageService();
  });

  describe('#subscribe / #unsubscribe', function() {
    it('should add/remove when subscribe/unsubscribe service', function() {
      dataService.subscribe(fs);

      var subs = dataService.getSubscribers();
      assert.equal(subs.length, 1);
      assert.equal(subs[0].name, 'failService');

      dataService.subscribe(ls);
      subs = dataService.getSubscribers();
      assert.equal(subs.length, 2);
      assert.equal(subs[1].name, 'localStorageService');;

      dataService.unsubscribe(fs);

      subs = dataService.getSubscribers();
      assert.equal(subs.length, 1);
      assert.equal(subs[0].name, 'localStorageService');;

      dataService.unsubscribe(ls);
      subs = dataService.getSubscribers();
      assert.equal(subs.length, 0);

    });
  });

  describe('#getAllDataTimestamps', function() {

    it('should call subscribed services and not unsubscribed services', function() {
      dataService.subscribe(fs);
      //dataService.subscribe(ls);

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

    it('should reject if all registered services reject', function() {
      dataService.subscribe(fs);
      dataService.subscribe(ls);

      var service = dataService.getAllDataTimestamps();

      //service rejects, because all registered services reject
      return expect(service).to.be.rejectedWith(TypeError);
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
        expect(data).to.have.deep.property('[0].serviceName', 'localStorageService');
        expect(data).to.have.deep.property('[0].status', 'success');
        expect(data).to.have.deep.property('[0].timestamp').to.be.below(new Date().getTime());
        expect(data).to.have.deep.property('[1].serviceName', 'failService');
        expect(data).to.have.deep.property('[1].status', 'error');
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
        data.should.have.deep.property(ls.name + '.data.test', 'test');
      });
    });

  });

});
