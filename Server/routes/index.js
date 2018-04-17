var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  // res.render('index', { title: 'Express' });
  // show a file upload form 
  res.writeHead(200, {'content-type': 'text/html'});
  res.end(
    '<form action="/upload-file" enctype="multipart/form-data" method="post">'+
    '<label for="title">title:</label><input type="text" name="title"><br>'+
    '<label for="f1">file1:</label><input type="file" name="f1" multiple="multiple"><br>'+
    '<label for="f2">file2:</label><input type="file" name="f2" multiple="multiple"><br>'+
    '<input type="submit" value="Upload">'+
    '</form>'
  );
});

module.exports = router;
