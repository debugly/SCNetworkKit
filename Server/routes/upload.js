var express = require('express');
var router = express.Router();
var query = require("querystring");
var multiparty = require('multiparty');
var util = require('util');
var fs = require('fs');

router.post('/', function(req, res, next) {

    var form = new multiparty.Form();
    var path = require('path');
    var p = 'public/upload';
    form.uploadDir = p;
    form.parse(req, function(err, fields, files) {
    res.writeHead(200, {'content-type': 'application/json'});
    var result = {};
    result['status'] = 200;
    result['ps'] = fields;
    result['files'] = files;
    res.write(JSON.stringify(result));
    res.end();

    console.log(util.inspect(fields, true));
    console.log(util.inspect(files, true));

    return;
    //   res.write('received fields:\n\n');
      
    //   Object.keys(fields).forEach(function(name) {
    //     // res.write('name:' + name + ',value:' + fields[name] + '\n\n');
    //   });
     
    //   res.write('\n\nreceived files:\n\n');

    

    //   Object.keys(files).forEach(function(name) {
    //     const element = fields[name];
    //     res.write(util.inspect(element, true));
    //     // res.write('fieldName:' + element.fieldName + ',originalFilename:' + element.originalFilename + ',path:' + element.path + ',size:' + element.size + '\n\n');
    //   });

      res.end();

    //   // 获得文件的临时路径
    //  var tmp_path = files.path;
    //  // 指定文件上传后的目录 - 示例为"images"目录。 
    //  var target_path = './public/images/' + req.files.thumbnail.name;
    //  // 移动文件
    //  fs.rename(tmp_path, target_path, function(err) {
    //    if (err) throw err;
    //    // 删除临时文件夹文件, 
    //    fs.unlink(tmp_path, function() {
    //       if (err) throw err;
    //       res.send('File uploaded to: ' + target_path + ' - ' + req.files.thumbnail.size + ' bytes');
    //    });
    //  });

    });

    // console.log(req.body);
    // console.log(req.files);

    // var shuju = "";
    // req.addListener("data", function (postchunkk) {
    //     shuju += postchunkk;
    // });

    // req.addListener("end", function () {
    //     var ss = query.parse(shuju);
    //     console.log(ss);     // { username: 'xuhaitao', pwd: '8855123' }
    //     console.log(ss.username);   //取到用户名的内容
    //     console.log(ss.password);        //取到密码框中的内容
    //     res.end(JSON.stringify(ss));  //json字符串的形式返回给客户端  {"username":"xuhaitao","pwd":"8855123"}
    // });

  });

module.exports = router;