const compression = require('compression');
const bodyParser = require('body-parser');
var session = require('express-session')
var cookieParser = require('cookie-parser')
const fileUpload = require('express-fileupload');
var MemoryStore = require('session-memory-store')(session);
const Guid = require('guid');

module.exports.init = (app) => {
  const guidSecret = Guid.create().value;
  app.use(compression({ threshold: 0 }));
  app.use(bodyParser.json({limit: '50mb'}))
  app.use(bodyParser.urlencoded({extended: false}))
  app.use(
  	session({
    	secret: guidSecret,
  		store: new MemoryStore(),
    	resave: false,
    	saveUninitialized: false,
  	})
  );
  app.use(cookieParser());
  app.use(fileUpload());
}
