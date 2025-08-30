import haxe.Json;
using StringTools;

//marker types
typedef HDONString = String;
typedef JSONString = String;
typedef JSONObject = Dynamic;

class HDON {
    
    public var _className: String;
    public var _package: String;
    public var _extends: String;
    public var _implements: Array<String>;
    public var _jsonObject: JSONObject;
    public var _jsonString: String;
    public var _classString: HDONString;
    public var _wasParsed: Bool;
    
    public function new() {
        _className = 'HDONClass';
        _package = '';
        _extends = null;
        _implements = [];
        _jsonString = '{}';
        _jsonObject = Json.parse(_jsonString);
        _classString = buildClassString();
        _wasParsed = false;
    }

    public function stringify(): HDONString {
        // If this instance was created by parse(), preserve the original class content
        // and only replace the @:data block contents in-place.
        if (_wasParsed) {
            var markerIndex = _classString.indexOf("@:data");
            if (markerIndex >= 0) {
                var openBraceIndex = _classString.indexOf("{", markerIndex);
                if (openBraceIndex > markerIndex) {
                    var jsonSource = extractBalancedBraces(_classString, openBraceIndex);
                    if (jsonSource != null) {
                        var start = openBraceIndex;
                        var end = start + jsonSource.length;
                        // end points one past the closing brace index
                        var before = _classString.substr(0, start);
                        var after = _classString.substr(start + jsonSource.length);
                        var haxeLike = jsonToHaxeLike(_jsonString != null ? _jsonString : '{}');
                        var replaced = before + haxeLike + after;
                        _classString = replaced;
                        return replaced;
                    }
                }
            }
            // Fallback to normal generation if marker not found
        }
        // Normal generation path
        formatJSONString();
        var formatted = formatClassString(buildClassString());
        _classString = formatted;
        return formatted;
    }

    public function parse(hdonString: HDONString) {
        _classString = hdonString;
        _wasParsed = true;

        // package
        var pkgRegex = new EReg("(?m)^\\s*package\\s+([A-Za-z0-9_\\.]+)\\s*;", "");
        if (pkgRegex.match(hdonString)) {
            _package = pkgRegex.matched(1);
        }

        // class name
        var classRegex = new EReg("(?m)class\\s+([A-Za-z_][A-Za-z0-9_]*)", "");
        if (classRegex.match(hdonString)) {
            _className = classRegex.matched(1);
        }

        // extends
        var extendsRegex = new EReg("(?m)extends\\s+([A-Za-z_][A-Za-z0-9_\\.]*)", "");
        if (extendsRegex.match(hdonString)) {
            _extends = extendsRegex.matched(1);
        }

        // implements (comma-separated)
        var implementsRegex = new EReg("(?m)implements\\s+([A-Za-z0-9_\\.,\\s]+)", "");
        if (implementsRegex.match(hdonString)) {
            var raw = implementsRegex.matched(1);
            var parts = raw.split(",");
            var impls: Array<String> = [];
            for (p in parts) {
                var t = p.trim();
                if (t.length > 0) impls.push(t);
            }
            _implements = impls;
        } else {
            _implements = [];
        }

        // extract @:data var _data = { ... }
        var markerIndex = hdonString.indexOf("@:data");
        if (markerIndex >= 0) {
            var openBraceIndex = hdonString.indexOf("{", markerIndex);
            if (openBraceIndex > markerIndex) {
                var jsonSource = extractBalancedBraces(hdonString, openBraceIndex);
                if (jsonSource != null) {
                    _jsonString = haxeLikeToJson(jsonSource);
                    _jsonObject = Json.parse(_jsonString);
                    return;
                }
            }
        }

        // default empty data if nothing found
        _jsonString = "{}";
        _jsonObject = Json.parse(_jsonString);
    }

    private function formatJSONString() {
        var jsonObject = Json.parse(_jsonString);
        _jsonString = Json.stringify(jsonObject, null, "    ");
    }

    public function setJSONData(jsonObject: JSONObject) {
        _jsonObject = jsonObject;
        _jsonString = Json.stringify(jsonObject);
        _classString = buildClassString();
    }

    public function setJSONString(jsonString: JSONString) {
        _jsonString = jsonString;
        _jsonObject = Json.parse(jsonString);
        _classString = buildClassString();
    }

    public static function fromJSONString(classPath: String, jsonString: JSONString): HDON {
        var hdon = new HDON();
        var parsed = parseClassPath(classPath);
        hdon._package = parsed.pkg;
        hdon._className = parsed.name;
        hdon._extends = null;
        hdon._implements = [];
        hdon._jsonString = jsonString;
        hdon._jsonObject = Json.parse(jsonString);
        hdon._classString = hdon.buildClassString();
        return hdon;
    }

    public static function fromJSONObject(classPath: String, jsonObject: JSONObject): HDON {
        var jsonString = Json.stringify(jsonObject);
        return fromJSONString(classPath, jsonString);
    }

    public static function fromObject(classPath: String, object: Dynamic): HDON {
        var jsonString = Json.stringify(object);
        return fromJSONString(classPath, jsonString);
    }

    // helpers
    private function buildClassString(): String {
        var lines: Array<String> = [];
        if (_package != null && _package.trim().length > 0) {
            lines.push('package ' + _package + ';');
            lines.push('');
        }

        var header = 'class ' + (_className != null ? _className : 'HDONClass');
        if (_extends != null && _extends.trim().length > 0) {
            header += ' extends ' + _extends;
        }
        if (_implements != null && _implements.length > 0) {
            header += ' implements ' + _implements.join(', ');
        }
        lines.push(header + ' {');
        lines.push('');
        var dataLiteral = jsonToHaxeLike(_jsonString != null ? _jsonString : '{}');
        // Derive indentation from existing file style (four spaces here) and repeat 6 times
        var outerIndent = '    ';
        var baseIndent = '';
        for (i in 0...5) baseIndent += outerIndent;
        var indentedDataLiteral = dataLiteral.split("\n").join("\n" + baseIndent);
        lines.push(outerIndent + '@:data var _data = ' + indentedDataLiteral + ';');
        lines.push('');
        lines.push('}');
        return lines.join("\n");
    }

    private static function formatClassString(source: String): String {
        var s = source.replace("\r\n", "\n").replace("\r", "\n");
        var lines = s.split("\n");
        var result = new Array<String>();
        var previousWasBlank = false;
        for (line in lines) {
            var rightTrimmed = StringTools.rtrim(line);
            var isBlank = rightTrimmed.trim().length == 0;
            if (isBlank) {
                if (!previousWasBlank) {
                    result.push("");
                    previousWasBlank = true;
                }
            } else {
                result.push(rightTrimmed);
                previousWasBlank = false;
            }
        }
        var out = result.join("\n");
        if (!out.endsWith("\n")) out += "\n";
        return out;
    }

    private static function parseClassPath(classPath: String): { pkg: String, name: String } {
        var lastDot = classPath.lastIndexOf('.');
        if (lastDot == -1) {
            return { pkg: '', name: classPath };
        }
        var pkg = classPath.substr(0, lastDot);
        var name = classPath.substr(lastDot + 1);
        return { pkg: pkg, name: name };
    }

    private static function extractBalancedBraces(source: String, openIndex: Int): String {
        var depth = 0;
        var start = -1;
        var i = openIndex;
        var len = source.length;
        while (i < len) {
            var c = source.charAt(i);
            if (c == '{') {
                depth++;
                if (start == -1) start = i;
            } else if (c == '}') {
                depth--;
                if (depth == 0) {
                    var endInclusive = i;
                    return source.substr(start, endInclusive - start + 1);
                }
            }
            i++;
        }
        return null;
    }

    private static function jsonToHaxeLike(jsonString: String): String {
        // Remove quotes around object keys: "key": -> key:
        var re = new EReg('(\"([A-Za-z_][A-Za-z0-9_]*)\")\\s*:', 'g');
        return re.replace(jsonString, '$2:');
    }

    private static function haxeLikeToJson(haxeObjectLiteral: String): String {
        // Add quotes around object keys: key: -> "key":
        // Avoid matching inside strings heuristically by requiring start of object or comma/brace/whitespace before key
        var re = new EReg('([{,\\s])([A-Za-z_][A-Za-z0-9_]*)\\s*:', 'g');
        var s = re.replace(haxeObjectLiteral, '$1"$2":');
        return s;
    }
}


/*

hdon is like json except it represents a haxe class with data inside it. it interops with json.
basically hdon contains a json object which represents its data and also haxe class artifacts like functions and variables
this way a browser gui can read the class files themselves and pull the data out them and write it back to the hdon class itself
this means we don't need to store data and then hydrate it back into the class, it is all one file
so really HDON will only be used in the browser, and the classes 

for json like this:

{
    "name": "John",
    "age": 30,
    "city": "New York"
}

like this:

class MyHDONExportedClass {

    //json is placed here as a haxe object, scrub the quotations from the field names
    @:data var _data = {
        name: "John",
        age: 30,
        city: "New York"
    }

    public function someFunction() {
        //this function exists in the exported version of the class but is not part of the "data"
        //is is retained in HDON._classString
    }

}

*/