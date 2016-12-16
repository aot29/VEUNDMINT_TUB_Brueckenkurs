var dataService = require('../../files/js/dataService.js');
var DjangoStorageService = require('../../files/js/storage/DjangoStorageService.js').DjangoStorageService;
var DjangoAuthService = require('../../files/js/storage/DjangoAuthService.js');
var LocalStorageService = require('../../files/js/storage/LocalStorageService.js').LocalStorageService;

var assert = require('assert');
var sinon = require('sinon');
var log = require('loglevel');

var Promise = require('bluebird');

var chai = require('chai');
var expect = chai.expect;
var should = chai.should();
var chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);
chai.use(require('chai-things'));

var request = require('request');

var dataFixtures = require('./dataFixtures.js');

describe('DjangoServices', function() {
	var $ = {};
	var skipTests;

	//we fake jquery ajax here, it will use node methods for requests
	before(function () {
		$.ajax = require('najax');
		DjangoAuthService.initJquery($);
		var that = this;

		request('http://localhost:8000', function (error, response, body) {
			if (error) {
				skipTests = true;
			}
		});

	});

	beforeEach(function() {
		if (skipTests) {
			this.skip();
		}
	});

	describe('DjangoAuthService', function() {

		it('#authenticate - should authenticate users and store token', function() {
			return DjangoAuthService.authenticate({
				username: 'testrunner',
				password:'<>87c`}X&c8)2]Ja6E2cLDyr]*A$^3E'
			}).then(function(data) {
				expect(DjangoAuthService.isAuthenticated()).to.equal(true);
				expect(DjangoAuthService.getToken()).to.not.equal(null);
			});
		});


		it('#authAjaxGet - should add auth header and make successful request', function() {
			return DjangoAuthService.authenticate({
				username: 'testrunner',
				password:'<>87c`}X&c8)2]Ja6E2cLDyr]*A$^3E'
			}).should.be.fulfilled.then(function(data) {
				return DjangoAuthService.authAjaxGet('http://localhost:8000/user-data/').should.be.fulfilled;
			});
		});

	});

	describe('DjangoStorageService', function() {

		var ds;
		beforeEach(function() {

			ds = DjangoStorageService();
			DjangoAuthService.logout();

		});

		describe('#saveUserData', function() {

			it('should reject if not authenticated', function() {
				return ds.saveUserData().should.be.rejectedWith('not authenticated');
			});

			it('should successfully store data in django and return it whilst the data structure stays the same', function() {
				return auth().should.be.fulfilled.then(function(data) {
					return ds.saveUserData(dataFixtures.getNewUserData()).should.be.fulfilled;
				}).then(function(userData) {
					return ds.getUserData();
				}).then(function(userData2) {
					userData2.should.deep.equal(dataFixtures.getNewUserData());
				});
			}).timeout(5000);
		});

		describe('#getDataTimeStamp', function() {
			it('should get the timestamp of the data', function() {
				return auth().should.be.fulfilled.then(function(data) {
					return ds.getDataTimestamp().should.be.fulfilled;
				});
			});
		})

		describe('#getUserData', function() {

			it('should reject if not authenticated', function() {
				return ds.getUserData().should.be.rejectedWith('not authenticated');
			});

			it('should get user data if authenticated', function() {
				return auth().should.be.fulfilled.then(function(data) {
					return ds.getUserData().should.be.fulfilled;
				});
			});

		})

	});

});

function auth() {
	return DjangoAuthService.authenticate({
		username: 'testrunner',
		password:'<>87c`}X&c8)2]Ja6E2cLDyr]*A$^3E'
	});
}
