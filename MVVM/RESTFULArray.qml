import QtQuick 2.5
import "Lodash"

//COMMANDMENTS
//1) If key doesn't exist, create it. default assumption is object!
//2) If value type of update is different than original value type, error!
//3) All arrays should have ids. Otherwise they are replaced on update
//4) Partial updates all teh way thru (deep)
//5) DELETE req only occurs on arrays with ids (root level or elsewhere)
//6) PUT updates, POST adds
//7) All server REST commands should be prepended by a version number. Each model should have versions.
Item {
    id : rootObject

    signal updated(string path, var data, var oldData);
    signal created(string path, var data);
    signal deleted(string path);

    readonly property alias length : priv.length
    readonly property alias arr    : priv.arr
    property alias priv : priv

    function reset(){
        //emit deleted signals for existing items!
        if(priv.arr){
            _.each(priv.arr, function(v,k){
                deleted(v.id,k)
            })
        }

        priv.length = 0;
        priv.idMap  = {};
        priv.arr    = undefined;
    }


    function runUpdate(data) {
        var type = toString.call(data);
        var isArr = type === '[object Array]'
        var isObj = type === '[object Object]'

        if(!isArr && !isObj)
            return false;

        //if our array isn't even initialized, then let's
        //init it!
        if(!priv.arr) {
            var d = isArr ? data : [data]
            priv.arr = _.filter(d, function(v){
                return priv.isDef(v.id)
            })

            //emit created messages!!!
            _.each(priv.arr, function(v,k){
//                console.log('iterating over array', priv.arr.length)
                priv.addId(v.id, v);
                created(v.id, v);
            })
            priv.length = priv.arr.length;
        }

        if(isArr){
            _.each(data, function(v){
                set(v.id, v);
            })
            return true;
        }
        else if(isObj) {
            return set(data.id, data);
        }

        return false;

    }





    function set(path, data) {
        var propArr = priv.getPathArray(path);
        if(!propArr || propArr.length === 0)
            return runUpdate(data);



        var ret =  priv.deepSet(priv.arr, propArr, data);
        if(ret && ret.type){
            if(ret.type === 'create') {
                priv.emitCreatedRecursive(path,data);
                return true;
            }
            else if(ret.type === 'createRoot'){
                var id = propArr[0]
                if(id) {
                    var item = priv.findById(priv.arr, id)
                    priv.addId(id, item )
                    created(id,item )   //emit created at root level!

                }
                priv.emitCreatedRecursive(path,data);
                priv.length++
                return true;
            }
            else if(ret.type === 'update') {
                if(ret.createdKeys) {
//                    console.log("ret.createdKeys" , JSON.stringify(ret.createdKeys,null,2))
                    _.each(ret.createdKeys, function(v,k){
                        var p = path + "/" + k;
//                        console.log("EMITTING CREATED", p, v)
                        created(p,v)
                    })
                }

                if(ret.updatedKeys) {
//                    console.log("ELK", JSON.stringify(ret.updatedKeys, null,2))
                    _.each(ret.updatedKeys, function(v,k){
                        var p = path + "/" + k;
                        updated(p,v.value, v.oldValue)
                    })
                }

                updated(path, data, ret.oldVal)
                return true;
            }
        }

        return false;
    }


    //If we are on an array, we should first look on the key 'id', then on index!
    function get(path) {
        if(!priv.arr)
            return undefined;

        var propArr = priv.getPathArray(path);
        return !propArr ?  priv.arr : priv.deepGet(priv.arr, propArr);
    }


    function del(path) {
//        console.log("DEL", path)
        var propArr = priv.getPathArray(path)
        if(!propArr || propArr.length === 0)
            return false;

        if(propArr.length === 1) {  //is on da root level!
            var id  = propArr[0]
            var idx = priv.findById(priv.arr, id, true)
            if(idx !== -1) {
                priv.arr.splice(idx,1);
                delete priv.idMap[id];
                deleted(id);
                priv.length--;
                return true;
            }
            return false;
        }
        else {
            var res = priv.deepDel(priv.arr, propArr);
            if(res) {
                deleted(path);
                return true;
            }
        }
        return false;
    }




    QtObject {
        id : priv
        property var idMap : ({})
        property var arr
        property int length : 0


        function writeCompatible(obj1, obj2){
            if(!obj1 || !obj2)
                return false;

            var t1 = toString.call(obj1)
            var t2 = toString.call(obj2)
            var t1Complex = t1 === '[object Array]' || t1 === '[object Object]'
            var t2Complex = t2 === '[object Array]' || t2 === '[object Object]'

            return t1 !== t2 && (t1Complex || t2Complex) ? false : true
        }

        function emitCreatedRecursive(path,data) {
            if(typeof data === 'object') {
                _.each(data, function(v,k) {
                    var p = path + "/" + k
                    created(p,v)

                    if(typeof v === 'object'){
                        emitCreatedRecursive(p,v);
                    }
                })
            }
            else {
                created(path,data);
            }
        }



        function newPtrObject(target){

            var ptr = target
            var prevPtr = null
            var o = {
                ptr : ptr,
                prevPtr : prevPtr,
                advance : function (key) {
                    var keyStr = key.toString()
                    var keyInt = parseInt(key)
                    keyInt     = isNaN(keyInt) ? null : keyInt

                    function adv(key){
                        o.prevPtr = o.ptr;
                        o.ptr     = o.ptr[key];
                        return o.ptr;
                    }

                    var ptrType = toString.call(o.ptr)
                    var isArr = ptrType === '[object Array]'
                    var isObj = ptrType === '[object Object]'

                    //special case for array
                    //basically, if things have id, always look at the id. ignore the index!
                    if(isArr) {
                        var idx = findByIdSoft(o.ptr, key, true)
//                        console.log("ADVANCE TO" ,key, "IN", JSON.stringify(ptr), idx)
                        return idx !== -1 ? adv(idx) : false;
                    }
                    else if(isObj) {
                        if(keyStr && isDef(o.ptr[key]))
                            return adv(keyStr)
                        else if(keyInt !== null && isDef(o.ptr[keyInt]))
                            return adv(key)
                    }

                    return false;
                },
                set : function(key,value){
                    var keyStr = key.toString()
                    var keyInt = parseInt(key)
                    keyInt     = isNaN(keyInt) ? null : keyInt
                    var ptrType = toString.call(o.ptr)
                    var item

                    function __set(obj,newObj){
                        var updatedKeys
                        var createdKeys
                        _.each(newObj,function(v,k){
                            var existing = obj[k]
                            if(!existing){
                                if(!createdKeys)
                                    createdKeys = {}
                                createdKeys[k] = v
                                obj[k] = v
                            }
                            else if(existing != v) {
                                var existingType = toString.call(existing)
                                var newType      = toString.call(value)
                                var existingIsComplex = existing ==='[object Array]' || existing === '[object Object]'
                                var newIsComplex      = value    ==='[object Array]' || value    === '[object Object]'

                                existing = existingIsComplex ? clone(existing) : existing
                                var bad = existingType !== newType && (existingIsComplex || newIsComplex)
                                if(!bad) {
                                    if(!updatedKeys)
                                        updatedKeys = {}

                                    updatedKeys[k] = { value : v , oldValue : existing };
                                    obj[k] = v;
                                }
                            }
                        })
                        return {created : createdKeys, updated: updatedKeys };
                    }


                    if(ptrType ===  '[object Array]') {
                        var idx = findByIdSoft(o.ptr, key, true)
                        if(idx === -1) {
                            o.ptr.push(value)
                            return { type : 'create', item : o.ptr[o.ptr.length-1] }
                        }
                        else {
//                            console.log("PTR SET", key, JSON.stringify(value))
                            item = o.ptr[idx]
                            if(writeCompatible(item,value)) {
                                var retObj = { type : 'update', item : o.ptr[idx] }
                                if(typeof item === 'object') {
                                    var res =  __set(item,value);
                                    retObj.createdKeys = res.created;
                                    retObj.updatedKeys = res.updated;
                                }
                                else
                                    o.ptr[idx] = value;
                                return retObj
                            }
                            else {
                                console.log(item, "is not compatible with", value)
                            }

                            return false;
                        }
                    }
                    else if(ptrType === '[object Object]') {
                        var k = isDef(o.ptr[keyStr]) ? keyStr :
                                                       keyInt !== null && isDef(o.ptr[keyInt]) ? keyInt :
                                                                                                 null

                        if(!k){ //is a totally new key!
//                            console.log("EYYY, we should have made new key", k)
                            o.ptr[key] = value;
                            return { type : "create", item : o.ptr[key] }
                        }
                        else {
                            item = o.ptr[k]
                            var retObj = { type : 'update', item : o.ptr[k] }
                            if(writeCompatible(item, value)) {
                                if(typeof item === 'object') {
                                    var res = __set(item,value);
                                    retObj.createdKeys = res.created;
                                    retObj.updatedKeys = res.updated;
                                }
                                else
                                    o.ptr[k] = value;
                                return retObj
                            }
                            else {
                                console.log(item, "is not compatible with", value)
                            }
                        }

                    }
                    return false;
                },
                del : function(key) {
//                    console.log("@@@ SPLICER FUNCTIOn")
                    var ptrType = toString.call(o.ptr);

                    //as per our commandments, we can only delete on arrays!
                    //and more often than not, only if they have ids!!
                    if(ptrType !== '[object Array]')
                        return false;

                    var idx = findByIdSoft(o.ptr, key, true);
                    if(idx === -1) {
                        return false;
                    }

                    o.ptr.splice(idx,1);
                    return true;
                }
            }

            return o
        }

        //helpers!
        function clone(obj){
            return JSON.parse(JSON.stringify(obj))
        }
        function addId(id,value){
            if(!idMap)
                idMap = {}
            idMap[id] = value;
        }
        function isComplexObject(obj) {
            var t = toString.call(obj)
            return t === '[object Array]' || t === '[object Object]'
        }
        function isSimpleObject(obj) {
            return !isComplexObject(obj);
        }
        function isUndef(){
            if(arguments.length === 0)
                return true

            for(var i = 0; i < arguments.length ; i++){
                var item = arguments[i]
                if(item === null || typeof item === 'undefined')
                    return true
            }
            return false
        }
        function isDef(){
            if(arguments.length === 0)
                return false

            for(var i = 0; i < arguments.length; i++){
                var item = arguments[i]
                if(item === null || item === undefined)
                    return false
            }
            return true
        }
        function getPathArray(pathStr) {
            var type = typeof pathStr

            if(isUndef(pathStr) || type === 'object')
                return null;

            if(type != 'string')
                pathStr = pathStr.toString()

            return pathStr.split("/")
        }
        function idExists(id) {
            return idMap && isDef(idMap[id]) ? true : false
        }


        //checks in the array indices if not found in id, if array doesnt have id field!
        function findByIdSoft(arr,id, returnIndex) {
            var badVal = returnIndex ? -1 : null
            var keyInt = parseInt(id)
            keyInt     = isNaN(keyInt) ? null : keyInt
            var thereAreIds = false;

            if(!arr)
                return badVal

            for(var i = 0; i < arr.length; ++i) {
                var item = arr[i]
                if(item ) {
                    if(isDef(item.id)){
                        thereAreIds = true;
                        if(item.id == id)
                            return returnIndex ? i : item;
                    }
                }
            }

            if(!thereAreIds && keyInt !== null && keyInt >= 0 && keyInt < arr.length) {
                return returnIndex ? keyInt : arr[keyInt]
            }

            return badVal;
        }
        function findById(array, id, returnIndex){
            var badVal = returnIndex ? -1 : null
            if(!array)
                return badVal

            for(var i in array) {
                var a = array[i]
                if(a.id == id)
                    return returnIndex ? i : a
            }
            return badVal
        }

        //meaty functions, heavy lifters!
        function deepSet(item, pathArr, value) {
//            console.log("DEEPSET", item, pathArr, value)
            //if there's no item to do this set operation on
            //or if there's no path provided , return false;
            if(!pathArr)
                return false;

            if(item == priv.arr && priv.arr == undefined){
                item = priv.arr = []
                priv.length = 0;
            }


            //set up pointer and prevPtr!
            var po = newPtrObject(item);
            var idx = item === priv.arr ? findById(priv.arr,pathArr[0],true) : null
            //assign id to root!
            if(pathArr.length === 1 && isUndef(value.id) && item === priv.arr && toString.call(value) === '[object Object]') {
                value.id = pathArr[0]
            }




            var newItem = false;
            for(var p =0; p < pathArr.length; ++p) {
                var prop = pathArr[p]
                var isLast = p === pathArr.length - 1
                if(isLast){
//                    console.log(prop,value)
                    var ret = po.set(prop,value)
                    if(typeof ret === 'object'){
                        if(newItem || (p === 0 && ret.type === 'create')) {  //we created new thing @ root!! WOOT!
                            ret.type = 'createRoot'
                        }

                        return ret;
                    }
                }
                else {
                    if(!po.advance(prop)) {
                        var newObj = p === 0 && idx !== null ? { id : prop } : {}

                        po.set(prop, newObj)
                        if(!po.advance(prop))
                            return false;
                        else {
                            if(isDef(newObj.id)) {
                                newItem = true;
                            }
                        }
                    }
                }
            }

            return false;
        }
        function deepGet(item, pathArr) {
            var po = newPtrObject(item)
            var retVal

            _.some(pathArr, function(prop, k) {
                var isLast = k === pathArr.length -1
                if(isLast ) {
                    if(po.advance(prop))
                        retVal = po.ptr
                }
                else {
                    var r = po.advance(prop)
                    if(r === false || r === undefined) {
                        console.error("no such property as", prop)
                        return true;
                    }
                }
            })
            return retVal
        }
        function deepDel(item, pathArr){
            if(!pathArr || pathArr.length === 0)
                return false;

            var po = newPtrObject(item);
            var rVal

            for(var i = 0; i < pathArr.length; ++i) {
                var prop = pathArr[i]
                var isLast = i === pathArr.length - 1;
                if(isLast) {
                    return po.del(prop);
                }
                else {
                    rVal = po.advance(prop)
                    if(rVal === false || rVal === undefined) {
                        console.error("no such property as", prop)
                        return false;
                    }
                }
            }

            return false;
        }

    }


}
