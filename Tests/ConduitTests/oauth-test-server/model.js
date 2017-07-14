// Nabbed and tweaked from https://github.com/oauthjs/node-oauth2-server/tree/b36a06b445ad0a676e6175d68a8bd0b2f3353dbf/examples/memory

var model = module.exports;

var oauthAccessTokens = [],
  oauthRefreshTokens = [],
  oauthClients = [
    {
      clientId : 'test_client',
      clientSecret : 'test_secret',
      redirectUri : 'https://derp.com'
    }
  ],
  authorizedClientIds = {
    password: [
      'test_client'
    ],
    refresh_token: [
      'test_client'
    ],
    client_credentials: [
      'test_client'
    ]
  },
  users = [
    {
      id : '123',
      username: 'test_user',
      password: 'hunter2'
    }
  ];

// Debug function to dump the state of the data stores
model.dump = function() {
  console.log('oauthAccessTokens', oauthAccessTokens);
  console.log('oauthClients', oauthClients);
  console.log('authorizedClientIds', authorizedClientIds);
  console.log('oauthRefreshTokens', oauthRefreshTokens);
  console.log('users', users);
};

/*
 * Required
 */

model.getAccessToken = function (bearerToken, callback) {
  for(var i = 0, len = oauthAccessTokens.length; i < len; i++) {
    var elem = oauthAccessTokens[i];
    if(elem.accessToken === bearerToken) {
      return callback(false, elem);
    }
  }
  callback(false, false);
};

model.getRefreshToken = function (bearerToken, callback) {
  for(var i = 0, len = oauthRefreshTokens.length; i < len; i++) {
    var elem = oauthRefreshTokens[i];
    if(elem.refreshToken === bearerToken) {
      oauthRefreshTokens.splice(i, 1);
      return callback(false, elem);
    }
  }
  callback(false, false);
};

model.getClient = function (clientId, clientSecret, callback) {
  for(var i = 0, len = oauthClients.length; i < len; i++) {
    var elem = oauthClients[i];
    if(elem.clientId === clientId &&
      (clientSecret === null || elem.clientSecret === clientSecret)) {
      return callback(false, elem);
    }
  }
  callback(false, false);
};

model.grantTypeAllowed = function (clientId, grantType, callback) {
  callback(false, authorizedClientIds[grantType] &&
    authorizedClientIds[grantType].indexOf(clientId.toLowerCase()) >= 0);
};

model.saveAccessToken = function (accessToken, clientId, expires, userId, callback) {
  oauthAccessTokens.unshift({
    accessToken: accessToken,
    clientId: clientId,
    userId: userId,
    expires: expires
  });

  callback(false);
};

model.saveRefreshToken = function (refreshToken, clientId, expires, userId, callback) {
  oauthRefreshTokens.unshift({
    refreshToken: refreshToken,
    clientId: clientId,
    userId: userId,
    expires: expires
  });

  callback(false);
};

/*
 * Required to support password grant type
 */
model.getUser = function (username, password, callback) {
  for(var i = 0, len = users.length; i < len; i++) {
    var elem = users[i];
    if(elem.username === username && elem.password === password) {
      return callback(false, elem);
    }
  }
  callback(false, false);
};

model.getUserFromClient = function(clientId, clientSecret, callback) {
  for (var i = 0; i < oauthClients.length; i++) {
    if (oauthClients[i].clientId == clientId && oauthClients[i].clientSecret == clientSecret) {
      callback(false, { "id" : clientId });
      return;
    }
  }
  callback(false, false);
}
