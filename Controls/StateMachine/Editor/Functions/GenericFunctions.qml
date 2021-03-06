import QtQuick 2.0
import "."
import Zabaat.Base 1.0
pragma Singleton
QtObject {
    id : genericFunctions


    function cleanPath(path){
        if(path){
            path = path.toString();
            path = path.replace("file://","")
            path = path.replace("qrc://","")
            if(path.indexOf("/") === 0)
                path = path.slice(1);
            return path;
        }
        return ""
    }

    function or(val){
        if(arguments.length > 1){
            for(var i = 1 ; i < arguments.length; ++i){
                if(val === arguments[i])
                    return true;
            }
        }
        return false
    }


    function toArray(lm){
        var arr = []
        if(!lm)
            return 0;

        for(var i = 0; i < lm.count; ++i){
            var item = lm.get(i)
            var type = typeof item
            if(type === 'string' || type === 'number' || type === 'date')
                arr.push(item)
            else {
                var obj = {};
                for(var k in item){
                    //exclude objectname
                    var ex = k.toLowerCase()
                    if(or(ex, "objectname","objectnamechanged") || ex.indexOf("__") === 0 )
                        continue

                    var val     = item[k]
                    if(Lodash.isUndefined(val)){
                        console.log(k, "is", val)
                        continue
                    }

                    type        = typeof val
                    var typeStr = val.toString().toLowerCase()
//                    console.log(k, val ,type,typeStr)
                    if(or(type,"string","number","date","bool","boolean"))
                        obj[k] = val;
                    else if(typeStr.indexOf("listmodel") !== -1)    //if it is a listemodel
                        obj[k] = toArray(val)
//                    }
                    else
                        obj[k] = Lodash.clone(val)
//                    }

                }
                arr.push(obj)
            }
        }
        return arr;
    }

    function colorhashFunc(name){
        function hashFunc(str){
            var hash = 0, i, chr, len;
              if (str.length === 0)
                  return hash;
              for (i = 0; i < str.length; i++) {
                chr   = str.charCodeAt(i);
                hash  = ((hash << 5) - hash) + chr;
//                    hash |= 0; // Convert to 32bit integer
              }
              return hash;
        }
        var h = Math.abs(hashFunc(name)).toString()
        if(h.length > 9){
            h = h.slice(0,-1)
        }
        else while(h.length < 9){
            h += "0"
        }

        //now subdivide the string in 3 sections
        var r = (+h.substr(0,3))/1000
        var g = (+h.substr(3,3))/1000
        var b = (+h.substr(6,3))/1000
        return Qt.rgba(r,g,b,1)
    }





}
