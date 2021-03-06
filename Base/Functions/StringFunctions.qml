import QtQuick 2.0
QtObject {

    function currentLineNum(stackidx) {
        stackidx = stackidx || 1;
        var stack = new Error().stack.split('\n')
        if(stack.length > stackidx) {
            var relevantLine = stack[stackidx];
            var lastIdx = relevantLine.lastIndexOf(":");
            if(lastIdx !== -1){
                var num = relevantLine.slice(lastIdx+1);
                return parseInt(num);
            }
        }
        return 0;
    }

    function currentFileAndLineNum(stackidx) {
        stackidx = stackidx || 1;
        var stack = new Error().stack.split('\n')
        if(stack.length > stackidx) {
            var relevantLine = stack[stackidx];
            var arr = relevantLine.split("/");

            relevantLine = arr[arr.length -1];
            arr = relevantLine.split(":");
            if(arr.length == 2) {
                return arr[0] + "::" + arr[1];
            }
        }
        return "";
    }

    function strToBool(str){
        if(str){
            str = str.toLowerCase()
            return str === "true" || str === "t"
        }
        return false
    }
    function replaceLine(str, searchTerm, newLine, numReplaces){
        var strarr = str.split('\n')
        var replaced = 0
        for(var s in strarr)
        {
            if(strarr[s].indexOf(searchTerm) != -1)
            {
                strarr[s] = newLine
                replaced++
                if(numReplaces && replaced >= numReplaces)
                    break
            }
        }
         return strarr.join('\n')
    }
    function capitalizeFirstLetter(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    }
    function lowercaseFirstLetter(string) {
        return string.charAt(0).toLowerCase() + string.slice(1);
    }

    function nextChar(c) {
        return String.fromCharCode(c.charCodeAt(0) + 1);
    }
    function replaceChar(string, index, character) {
        return string.substr(0, index) + character + string.substr(index+character.length);
    }
    function replaceAll(find, replace, str) {
      return str.replace(new RegExp(escapeRegExp(find), 'g'), replace);
    }
    function escapeRegExp(string) {
        return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
    }
    function initials(){
        if(arguments.length === 0)
            return ""

        var args = arguments
        var str = ""
        for(var a = 0; a < args.length; a++){
            var item = args[a].toString()
            str      += item.substring(0,1).toUpperCase()
        }
        return str
    }
    function buildString(str){
        var args = Array.prototype.slice.call(arguments, 1)
        console.log(args)
        var index = 0
        return str.replace(/%s/g, function(match, number)
        {
            var ret = typeof args[index] != 'undefined' ? args[index] : index ;
            index++
            return ret
        });
    }
    function countOccurences(str, searchText){
        return str.split(searchText).length - 1
    }
    function endsWith(str, suffix, ignoreCase) {
        if(ignoreCase === null || typeof ignoreCase === 'undefined')
            ignoreCase = false

        if(ignoreCase){
            str = str.toLowerCase()
            suffix = suffix.toLowerCase()
        }

        return str.indexOf(suffix, str.length - suffix.length) !== -1;
    }
    function startsWith(str, prefix, ignoreCase){
        if(ignoreCase === null || typeof ignoreCase === 'undefined')
            ignoreCase = false

        if(ignoreCase){
            str = str.toLowerCase()
            prefix = prefix.toLowerCase()
        }

        return str.indexOf(prefix) === 0;
    }
    function contains(str, term, ignoreCase){
        if(ignoreCase === null || typeof ignoreCase === 'undefined')
            ignoreCase = false

        if(ignoreCase){
            str = str.toLowerCase()
            term = term.toLowerCase()
        }

        return str.indexOf(term)
    }
    function phoneNumberify(str) {
        if(str && str.indexOf("-") === -1)
            return str.substr(0, 3) + '-' + str.substr(3, 3) + '-' + str.slice(6)
        return str
    }
    function beautifyString(str, specialCaseArray){
        //find index of all Cap words
        var arr = getWords(str)
        if(specialCaseArray === null || specialCaseArray === undefined)
            specialCaseArray = ["of"]
//        console.log(arr)

        //special case "of", turn it to lowercase
        for(var a in arr){
            var index = specialCaseArray.indexOf(arr[a].toLowerCase())
            if(index !== -1)
                arr[a] = arr[a].toLowerCase()
        }

        return arr.join(' ')
    }
    function getWords(str){
        var ind1  = -1
        var words = []

        for(var s = 0 ; s < str.length; s++){
            var c = str.charAt(s)
            if(c >= 'A' && c <= 'Z'){
                if(ind1 === -1)
                    ind1 = s
                else {
                    if(words.length === 0)  //is first entry in it
                        words.push(capitalizeFirstLetter(str.substring(0,ind1)))

                    words.push(str.substring(ind1,s));
                    ind1 = s
                }
            }
            if(s === str.length - 1 && ind1 !== -1){
                if(words.length === 0)  //is first entry in it
                    words.push(capitalizeFirstLetter(str.substring(0,ind1)))

                words.push(str.substring(ind1,s+1))
            }
        }

        if(words.length === 0){ //no camelCase stuff
            words.push(capitalizeFirstLetter(str))
        }

        return words
    }
    function getNumbers(str){
        return str.replace(/[^\d.-]/g, '');
    }
    function noNumbers(str){
        return str.replace(/[0-9]/g, '');
    }

    function isADecimalNumber(str){
        return str.match(/^\d*\.?\d*$/g);
    }
    function moneyify(number, modifier, c, d, t){
        if(modifier === null || typeof modifier === 'undefined')
            modifier = 1

        var n = number * modifier
        c = isNaN(c = Math.abs(c)) ? 2 : c
        d = d == undefined ? "." : d
        t = t == undefined ? "," : t
        var s = n < 0 ? "-" : ""
        var i = parseInt(n = Math.abs(+n || 0).toFixed(c)) + ""
        var j = (j = i.length) > 3 ? j % 3 : 0
        return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
     }
    function spch(str)    {     return  "\"" + str + "\"";   }


    function createUrl(url, params) {
        if(toString.call(params) !== '[object Object]')
            return url;

        var first = true;
        for(var p in params) {
            if(first) {
                url += "?";
                first = false;
            }
            else {
                url += "&"
            }
            url += p + "=" + params[p]
        }
        return url;
    }

    function getUrlInfo(url, dontDecode) {
        var retObj = { url : url }

        function getQueryParams(qs) {
            qs = qs.split('+').join(' ');

            var params = {},
                tokens,
                re = /[?&]?([^=]+)=([^&]*)/g;

            while (tokens = re.exec(qs)) {
                if(!dontDecode)
                    params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
                else
                    params[tokens[1]] = tokens[2];
            }

            return params;
        }


        if(typeof url !== 'string')
            return retObj;

        //find the query string first
        var qIdx = url.indexOf('?')
        if(qIdx === -1)
            return retObj;

        var qStr = url.slice(qIdx);
        return {
            url    : url.substring(0,qIdx),
            params : getQueryParams(qStr)
        }

    }



}
