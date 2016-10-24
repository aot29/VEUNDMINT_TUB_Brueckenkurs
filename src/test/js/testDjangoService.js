var dataService = require('../../files/js/dataService.js');
var DjangoStorageService = require('../../files/js/storage/DjangoStorageService.js').DjangoStorageService;

var assert = require('assert');
var sinon = require('sinon');
var log = require('loglevel');

var chai = require('chai');
var expect = chai.expect;
var should = chai.should();
var chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised);

describe('django storage service', function() {

  var ds;
  beforeEach(function() {

    //reset to init status before each test
    dataService.unsubscribeAll();
    dataService.emptyChangedData();

    //a service for django
    ds = DjangoStorageService();
  });



  describe('DjangoStorageService', function() {

  });

});
