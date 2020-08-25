var express = require('express');
var router = express.Router();
const path = require('path');

/* GET users listing. */
router.get('/', function(req, res, next) {
    var result = {};
    result['status'] = 200;
    res.json(result);
});

router.post('/', function(req, res, next) {
    var result = {};
    result['status'] = 200;
    result['body'] = req.body;
    result['query'] = req.query;
    console.log("body:" + JSON.stringify(req.body));
    res.json(result);
});

router.get('/download', function(req, res, next) {
    const file = path.join(__dirname, '../public/images/node.jpg')
    res.sendFile(file);
});

router.post('/download', function(req, res, next) {
    const file = path.join(__dirname, '../public/images/node.jpg')
    res.sendFile(file);
});

module.exports = router;
