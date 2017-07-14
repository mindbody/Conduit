var express = require('express'),
    bodyParser = require('body-parser'),
    oauthserver = require('oauth2-server'),
    memorystore = require('./model.js');
 
var app = express();
 
app.use(bodyParser.urlencoded({ extended: true }));
 
app.use(bodyParser.json());
 
app.oauth = oauthserver({
  model: memorystore,
  grants: ['password', 'refresh_token', 'client_credentials']
});
 
app.all('/oauth2/issue/token', app.oauth.grant());
 
app.use(app.oauth.errorHandler());
 
app.listen(5000);