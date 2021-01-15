var express = require('express');
var router = express.Router();
// const path = require('path');

/* GET get listing. */

router.get('/', function(req, res, next) {
    var result = {};
    result['status'] = 200;
    result['query'] = req.query;
    console.log("body:" + JSON.stringify(req.query));
    res.json(result);
});

module.exports = router;