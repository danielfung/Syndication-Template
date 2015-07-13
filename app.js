var express = require('express');
var http = require('http');
var app = express();
var irb = require('./irb');//IRB
var crms = require('./crms');//CRMS
var iacuc = require('./iacuc');//IACUC
var dlar = require('./dlar'); //DLAR
var dlaraoi = require('./dlar-aolineitem');//dlar animal order line item
var dlaraot = require('./dlar-aotransfer');//dlar animal order transfer
var dlarcage = require('./dlar-cagecard');//dlar cage card
var rnumber = require('./rnumber');//My Studies
var test = require('./irb/test.js');
var winston = require('winston');
var bodyParser = require('body-parser');
var logger = require("./utils/logger.js");
var handlebars = require('handlebars');
var fs = require('fs');
var config = require('./config');

/*
* Pre-Compile Create Templates
*/
//DLAR Pre-Compile Create Template
var rawCreateDlarTemplate = fs.readFileSync(__dirname+'/dlar/templates/create.tpl', {encoding:'utf8'});
var dlarCompliedCreateTemplate = handlebars.compile(rawCreateDlarTemplate);

//IACUC Pre-Compile Create Template
var rawCreateIacucTemplate = fs.readFileSync(__dirname+'/iacuc/templates/create.tpl', {encoding:'utf8'});
var iacucCompliedCreateTemplate = handlebars.compile(rawCreateIacucTemplate);

//IRB Pre-Compile Create Template
var rawCreateIrbTemplate = fs.readFileSync(__dirname+'/irb/templates/create.tpl', {encoding:'utf8'});
var irbCompliedCreateTemplate = handlebars.compile(rawCreateIrbTemplate);

//CRMS Pre-Compile Create Template
var rawCreateCrmsTemplate = fs.readFileSync(__dirname+'/crms/templates/create.tpl', {encoding:'utf8'});
var crmsCompliedCreateTemplate = handlebars.compile(rawCreateCrmsTemplate);

//DLAR(Animal Order Line Item) Pre-Compile Create Template
var rawCreateDlarAoiTemplate = fs.readFileSync(__dirname+'/dlar-aolineitem/templates/create.tpl', {encoding:'utf8'});
var dlarAoiCompliedCreateTemplate = handlebars.compile(rawCreateDlarAoiTemplate);

//DLAR(Animal Order Transfer) Pre-Compile Create Template
var rawCreateDlarAotTemplate = fs.readFileSync(__dirname+'/dlar-aotransfer/templates/create.tpl', {encoding:'utf8'});
var dlarAotCompliedCreateTemplate = handlebars.compile(rawCreateDlarAotTemplate);

//DLAR(Cage Card) Pre-Compile Create Template
var rawCreateDlarCageTemplate = fs.readFileSync(__dirname+'/dlar-cagecard/templates/create.tpl', {encoding:'utf8'});
var dlarCageCompliedCreateTemplate = handlebars.compile(rawCreateDlarCageTemplate);

/*
* Pre-Compile Update Templates
*/
//RNUMBER Pre-Compile Update Template
var rawUpdateResearchNavigatorTemplate = fs.readFileSync(__dirname+'/rnumber/templates/update.tpl', {encoding:'utf8'});
var rnUpdateTemplate = handlebars.compile(rawUpdateResearchNavigatorTemplate);

//CRMS Pre-Compile Update Template
var rawUpdateCrmsTemplate = fs.readFileSync(__dirname+'/crms/templates/update.tpl', {encoding:'utf8'});
var crmsUpdateTemplate = handlebars.compile(rawUpdateCrmsTemplate);

//DLAR Pre-Compile Update Template
var rawUpdateDlarTemplate = fs.readFileSync(__dirname+'/dlar/templates/update.tpl', {encoding:'utf8'});
var dlarCompliedUpdateTemplate = handlebars.compile(rawUpdateDlarTemplate);

/*
  HandleBars partials
*/
var rawPartialCreateIacucOrigAmendTemplate = fs.readFileSync(__dirname+'/iacuc/templates/iacuc-orig-amend-datamigration-create.tpl', {encoding:'utf8'});
handlebars.registerPartial("dataMigrationIacucOrigAmendCreate", rawPartialCreateIacucOrigAmendTemplate);

var rawPartialUpdateIacucOrigAmendTemplate = fs.readFileSync(__dirname+'/iacuc/templates/iacuc-orig-amend-datamigration-update.tpl', {encoding:'utf8'});
handlebars.registerPartial("dataMigrationIacucOrigAmendUpdate", rawPartialUpdateIacucOrigAmendTemplate);

var rawPartialCreateIacucOrigTemplate = fs.readFileSync(__dirname+'/iacuc/templates/iacuc-orig-datamigration-create.tpl', {encoding:'utf8'});
handlebars.registerPartial("dataMigrationIacucOrigCreate", rawPartialCreateIacucOrigTemplate);

var rawPartialUpdateIacucOrigTemplate = fs.readFileSync(__dirname+'/iacuc/templates/iacuc-orig-datamigration-update.tpl', {encoding:'utf8'});
handlebars.registerPartial("dataMigrationIacucOrigUpdate", rawPartialUpdateIacucOrigTemplate);

var rawPartialIacucOrigTemplate = fs.readFileSync(__dirname+'/iacuc/templates/iacuc-orig-integration-create.tpl', {encoding:'utf8'});
handlebars.registerPartial("integrationIacucOrigCreate", rawPartialIacucOrigTemplate);

var rawPartialIacucOrigCopyTemplate = fs.readFileSync(__dirname+'/iacuc/templates/iacuc-orig-integration-create-existing.tpl', {encoding:'utf8'});
handlebars.registerPartial("integrationIacucOrigCreateExisting", rawPartialIacucOrigCopyTemplate);

var rawPartialDlarOrigCreateTemplate = fs.readFileSync(__dirname+'/dlar/templates/dlar-orig-integration-create.tpl', {encoding:'utf8'});
handlebars.registerPartial("integrationDlarOrigCreate", rawPartialDlarOrigCreateTemplate);



/*
  https://www.npmjs.com/package/body-parser --> Added limit because of Error: request entity too large
*/
logger.debug("Overriding 'Express' logger");
app.use(require('express')({ "stream": logger.stream }));
app.use(bodyParser.json({limit: '5mb'}));
app.use(bodyParser.urlencoded({limit:'5mb', extended:true}));

var port = process.env.Port || 4441; //set port
var env = process.env.NODE_ENV || 'development';
var router = express.Router();

//middleware that will happen on every requests
router.use(function(req,res,next){
  //logging requests
  logger.log('info', req.method +' '+req.url );
  next();
});

router.post('/', function(req,res){
  //console.log(req.body);
  var j = 'test, received';
  res.send(j);
});

/*
* stepCreateOne => used for createTemplates
*               => based on store -> example: irb/crms/iacuc/dlar 
*/
var stepCreateOne = function (req, res, next) {
    var store = req.params.store;
    if(store == 'irb'){
      req.preTemp = irbCompliedCreateTemplate;
    }
    if(store == 'crms'){
      req.preTemp = crmsCompliedCreateTemplate;
    }
    if(store == 'iacuc'){
      req.preTemp = iacucCompliedCreateTemplate;
    } 
    if(store == 'dlar'){
      req.preTemp = dlarCompliedCreateTemplate;
    }
    if(store == 'dlaraolineitem'){
      req.preTemp = dlarAoiCompliedCreateTemplate;
    }
    if(store == 'dlaraotransfer'){
      req.preTemp = dlarAotCompliedCreateTemplate;
    }
    if(store == 'dlarcagecard'){
      req.preTemp = dlarCageCompliedCreateTemplate;
    }
    next();
  };

/*
* stepCreateTwo => create scripts(create) for debug console
*               => action -> create, send json with correct template to compile based on store
*/
var stepCreateTwo = function (req, res, next) {
  var store = req.params.store;
  store = store.toLowerCase();
  logger.info("Store: "+store +" Action: Create");
  logger.info(req.body);
  if(store == 'irb'){
    var i = irb.compiledHandleBars(req.body, req.preTemp);
    var buf = new Buffer(i);
    var compiledScript = buf.toString('base64');
    i = '{"script":"'+compiledScript+'"}'
    res.send(i);
  }
  if(store == 'crms'){
    var i = crms.compiledHandleBars(req.body, req.preTemp);
    var buf = new Buffer(i);
    var compiledScript = buf.toString('base64');
    i = '{"script":"'+compiledScript+'"}'
    res.send(i);
  }
  if(store == 'iacuc'){
      var i = iacuc.compiledHandleBars(req.body, req.preTemp);
      var buf = new Buffer(i);
      var compiledScript = buf.toString('base64');
      i = '{"script":"'+compiledScript+'"}'
      res.send(i);
  }
  if(store == 'dlar'){
      var i = dlar.compiledHandleBars(req.body, req.preTemp);
      var buf = new Buffer(i);
      var compiledScript = buf.toString('base64');
      i = '{"script":"'+compiledScript+'"}'
      res.send(i);

  }
  if(store == 'dlaraolineitem'){
      var i = dlaraoi.compiledHandleBars(req.body, req.preTemp);
      var buf = new Buffer(i);
      var compiledScript = buf.toString('base64');
      i = '{"script":"'+compiledScript+'"}'
      res.send(i);

  }
  if(store == 'dlaraotransfer'){
      var i = dlaraot.compiledHandleBars(req.body, req.preTemp);
      var buf = new Buffer(i);
      var compiledScript = buf.toString('base64');
      i = '{"script":"'+compiledScript+'"}'
      res.send(i);

  }
  if(store == 'dlarcagecard'){
      var i = dlarcage.compiledHandleBars(req.body, req.preTemp);
      var buf = new Buffer(i);
      var compiledScript = buf.toString('base64');
      i = '{"script":"'+compiledScript+'"}'
      res.send(i);

  }

  next();
};

/*
* stepUpdateOne => used for updateTemplates
*               => based on store -> example: irb/crms/iacuc/dlar 
*/
var stepUpdateOne = function (req, res, next) {
  var store = req.params.store;
  if(store == 'rnumber'){
    req.preTemp = rnUpdateTemplate;
  }
  if(store == 'crms'){
    req.preTemp = crmsUpdateTemplate;
  }
  if(store == 'dlar'){
    req.preTemp = dlarCompliedUpdateTemplate;
  }
  next();
};

/*
* stepCreateTwo => create scripts(update) for debug console
*               => action -> update, send json with correct template to compile based on store
*/
var stepUpdateTwo = function (req, res, next) {
  var store = req.params.store;
  store = store.toLowerCase();
  logger.info("Store: "+store +" Action: Update");
  logger.info(req.body);
  if(store == 'rnumber'){
      var i = rnumber.compiledHandleBars(req.body, req.preTemp);
      var buf = new Buffer(i);
      var compiledScript = buf.toString('base64');
      i = '{"script":"'+compiledScript+'"}'
      res.send(i);
  }
  if(store == 'crms'){
    var i = crms.compiledHandleBars(req.body, req.preTemp);
    var buf = new Buffer(i);
    var compiledScript = buf.toString('base64');
    i = '{"script":"'+compiledScript+'"}'
    res.send(i);
  }
  if(store == 'dlar'){
      var i = dlar.compiledHandleBars(req.body, req.preTemp);
      var buf = new Buffer(i);
      var compiledScript = buf.toString('base64');
      i = '{"script":"'+compiledScript+'"}'
      res.send(i);
  }
  next();
};

/*
* Use a specific template depending on store: /:store/templates/create.tpl => example: /irb/templates/create.tpl
* Return compiled template using Handlebars
*/
router.post('/:store', [
    stepCreateOne,
    stepCreateTwo
]);

/*
* Use a specific template depending on store: /:store/templates/create/create.tpl => example: /irb/templates/create.tpl
* Return compiled template using Handlebars
*/
router.post('/:store/create', [
    stepCreateOne,
    stepCreateTwo
]);

/*
* Use a specific template depending on store: /:store/templates/update/update.tpl => example: /rnumber/templates/update.tpl
* Return compiled template using Handlebars
*/
router.post('/:store/update', [
  stepUpdateOne,
  stepUpdateTwo
]);

app.use('/', router);

var server = app.listen(port, function () {
  var host = server.address().address;
  logger.info('app listening at http://%s:%s', host, port, env);
});
