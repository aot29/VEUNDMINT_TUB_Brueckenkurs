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

describe('localStorageService', function() {

  var ls;
  beforeEach(function() {
    ls = LocalStorageService();
    dataService.mockLocalStorage();
  });

      it('should #saveUserData correctly to localStorage and add a timestamp', function() {

        //var spy = sinon.spy(ls, "saveUserData");

        var service = ls.saveUserData({test: 'data', scores: [{id:1, points:10}, {id:2, points: 42}]});

        var millis = new Date().getTime();

        //all of these must be true
        return Promise.all([
          service.should.eventually.have.property("test", "data"),
          service.should.eventually.have.deep.property("scores[0].id", 1),
          service.should.eventually.have.deep.property("scores[1].points", 42),
          //the timestamp should be within a 10 seconds range (because it was just set before)
          service.should.eventually.have.property("timestamp").to.be.within(millis - 5000, millis + 5000)
        ]);
      });

      it('should resolve #getDataTimestamp if data is available and reject otherwise', function() {
        var service = ls.getDataTimestamp();
        //there was no userData so it should be rejected as there is no data Timestamp as well
        return service.should.be.rejectedWith('Can not get data Timestamp').then(function() {
          return ls.saveUserData({});
        }).then(function(data) {
          return data.should.have.property("timestamp");
        });
      });

      it('should #getUserData successfully', function() {
        var userData = {a: {b:'c'}};
        return ls.saveUserData(userData).then(function() {
          return ls.getUserData();
        }).then(function(data) {
          data.should.have.deep.property('a.b', 'c');
        });
      });

      it('should merge #saveUserData successfully', function() {
        var userData = {a: {b:'c'}, arr:[{id:1, p:42}]};
        var userData2 = {a: {b:'d',x:'y'}, arr:[{id:1, p:43}, {id:2, p:2}]};
        return ls.saveUserData(userData).then(function() {
          return ls.saveUserData(userData2);
        }).then(function() {
          return ls.getUserData();
        }).then(function(finalData) {
          finalData.should.have.deep.property('a.b', 'd');
          finalData.should.have.deep.property('a.x', 'y');
          finalData.should.have.deep.property('arr[0].id', 1);
          finalData.should.have.deep.property('arr[0].p', 43);
          finalData.should.have.deep.property('arr[1].id', 2);
          finalData.should.have.deep.property('arr[1].p', 2);
        });
      });
});
