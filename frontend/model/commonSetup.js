const compression = require('compression');
const bodyParser = require('body-parser');
var session = require('express-session')
var cookieParser = require('cookie-parser')
const fileUpload = require('express-fileupload');
var MemoryStore = require('session-memory-store')(session);
const Guid = require('guid');

module.exports.init = (app) => {
  const guidName = Guid.create().value;
  console.log(`SESSION SECRET IS: ${guidSecret}`);
  app.use(compression({ threshold: 0 }));
  app.use(bodyParser.json({limit: '50mb'}));
  app.use(bodyParser.urlencoded({extended: false}));
  app.use(
  	session({
      name: guidName,
    	secret: 'majority.heritage.wink.mind',
  		store: new MemoryStore(),
    	resave: false,
    	saveUninitialized: false,
  	})
  );
  app.use(cookieParser());
  app.use(fileUpload());
}
