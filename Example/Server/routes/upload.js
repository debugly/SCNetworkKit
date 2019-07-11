var express = require('express');
var router = express.Router();
var query = require("querystring");
var multiparty = require('multiparty');
var util = require('util');
var fs = require('fs');
const uploadDir = 'public/upload/';
const tmpDir = 'public/tmp';

router.post('/', function(req, res, next) {

    var form = new multiparty.Form();
    form.uploadDir = tmpDir;

    form.parse(req, function(err, fields, files) {
      // console.log(util.inspect(fields, true));
      // console.log(util.inspect(files, true));
      
      ///将移除，移动文件封装成 promise.
      function rename(f){
        return new Promise(function(resolve,reject){
          if(f.size > 0){
            const fName = f.originalFilename;
            const newPath = uploadDir + fName;
            ///目标文件已经存在的话会被覆盖！
            fs.rename(f.path,newPath,function(err){
                if(err){
                  reject(err);
                  console.log('save file:' + newPath + ';err:' + err.toString());
                }else{
                  console.log('save file:' + newPath);
                  resolve(fName);
                }
            });
          }else{
            fs.unlink(f.path,function(err){
              if(err){
                reject(err);
                console.log('delete empty file:' + f.path + ';err:' + err.toString());
              }else{
                console.log('delete empty file:' + f.path);
                resolve('');
              }
            });
          }
        });
      }

      ///处理参数值，拿到的值包裹在数组里了，给去掉；
      Object.keys(fields).forEach(function(name) {
        const arr = fields[name];
        value = arr.length > 0 ? arr[0] : '';
        fields[name] = value;
      });

      ///处理文件，所有文件都放在一起；
      const fileList = [];
      Object.keys(files).forEach(function(name) {
        const arr = files[name];
        arr.forEach(function(v){
          fileList.push(v);  
        });
      });

      function noneFileResp(){
        ///构建响应结构体
        const result = {};
        result['status'] = 200;
        result['msg'] = 'received none files!';
        result['ps'] = fields;
        res.json(result);
      }

      if(fileList.length == 0){
        noneFileResp();
      }else{
        ///将文件数组映射为promise任务；
        const tasks = fileList.map(function(v){
          return rename(v);
        });

        ///任务全部完成后，给客户端响应；
        Promise.all(tasks).then(function(value){
          console.log('all:' + value.toString());
          // public/upload/Icon-24@2x.png,public/upload/Icon-29@3x.png,public/upload/Icon-40.png
          
          ///处理文件名，字符串转成数组，去掉空串，空串意味着客户端表单里没文件
          let fileNameArr = value.toString().split(',');
          // for(var i = fileNameArr.length-1; i >= 0 ; i --){
          //   const e = fileNameArr[i];
          //   if(e.length == 0){
          //     fileNameArr.splice(i,1);
          //   }
          // }
          
          fileNameArr = fileNameArr.filter(function(f){
            return f.length > 0;
          });

          if(fileNameArr.length == 0){
            noneFileResp();
          }else{
            ///构建响应结构体
            const result = {};
            result['status'] = 200;
            result['msg'] = 'received ' + fileNameArr.length + ' files!';
            result['ps'] = fields;
            result['files'] = fileNameArr;
            res.json(result);
            // res.writeHead(200, {'content-type': 'application/json'});
            // res.write(JSON.stringify(result));
            // res.end();
          }
        }).catch(function(err){
          ///构建异常结构体
          const result = {};
          result['status'] = 5000;
          result['msg'] = err.toString();
          res.json(result);
        });
      }

    });
  });

module.exports = router;

/*
"status": 200,
"ps": {
  "title": [
    "ff"
  ]
},
"files": {
  "f1": [
    {
      "fieldName": "f1",
      "originalFilename": "Icon-24@2x.png",
      "path": "public/tmp/xaBpbqzDzKcY1aiYnWZqBzz2.png",
      "headers": {
        "content-disposition": "form-data; name=\"f1\"; filename=\"Icon-24@2x.png\"",
        "content-type": "image/png"
      },
      "size": 6407
    },
    {
      "fieldName": "f1",
      "originalFilename": "Icon-29@3x.png",
      "path": "public/tmp/g2Yq7RU-fdXYaVm2I2qEPkyQ.png",
      "headers": {
        "content-disposition": "form-data; name=\"f1\"; filename=\"Icon-29@3x.png\"",
        "content-type": "image/png"
      },
      "size": 10719
    }
  ],
  "f2": [
    {
      "fieldName": "f2",
      "originalFilename": "Icon-40.png",
      "path": "public/tmp/g51NVH6wECS0t9xLSKcPICIS.png",
      "headers": {
        "content-disposition": "form-data; name=\"f2\"; filename=\"Icon-40.png\"",
        "content-type": "image/png"
      },
      "size": 5659
    }
  ]
}
}
*/