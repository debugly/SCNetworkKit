var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', function(req, res, next) {
    
    var fs = require("fs");
    var util = require('util');

    console.log("req.query:" + util.inspect(req.query,true));

    const path = req.query["path"] ? req.query["path"] : 'upload';
    const json = req.query["json"];

    console.log("查看 "+ path +" 目录");
    ///只能查看public文件夹下的
    fs.readdir("public/" + path,function(err, files){

        files = files.filter(function(path){
            return path != ".DS_Store";
        });

        if(json){
            if (err) {
                console.error(err);
                var result = {};
                result['status'] = 404;
                result['msg'] = err.toString();
                res.json(result);
            }else{
                var result = {};
                result['status'] = 200;
                result['files'] = files;
                result['path'] = path;
    
                res.json(result);
            }
        }else{
            res.render('peek', { title: 'Peek',path: path,files: files });
        }
    });

    // var result = {};
    // result['status'] = 200;
    // res.write(JSON.stringify(result));
    // res.end();
});

module.exports = router;
