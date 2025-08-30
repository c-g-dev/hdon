package cases;

import testcore.TestCase;
import testcore.Test;
import HDON;

class HDONTests extends TestCase {
    public function test_defaults_on_new(test: Test) {
        var h = new HDON();
        test.assert(h._className == 'HDONClass', 'default class name');
        test.assert(h._package == '', 'default package');
        test.assert(h._extends == null, 'default extends');
        test.assert(h._implements.length == 0, 'default implements');
        test.assert(h._jsonString == '{}', 'default json string');
    }

    public function test_stringify_builds_haxe_like_class(test: Test) {
        var h = new HDON();
        h._package = 'my.pkg';
        h._className = 'Thing';
        h._extends = 'Base';
        h._implements = ['IOne','ITwo'];
        h.setJSONString('{"a":1, "b":2}');
        var s = h.stringify();
        test.assert(s.indexOf('package my.pkg;') != -1, 'includes package');
        test.assert(s.indexOf('class Thing extends Base implements IOne, ITwo') != -1, 'header correct');
        test.assert(s.indexOf('@:data var _data = {') != -1, 'has data marker');
        test.assert(s.indexOf('a:') != -1 && s.indexOf('b:') != -1, 'haxe-like keys without quotes');
    }

    public function test_parse_reads_package_class_extends_implements(test: Test) {
        var src = 'package a.b;\n\nclass Foo extends Bar implements IOne, ITwo {\n\n    @:data var _data = {\n        a: 1,\n        name: "X"\n    };\n\n}';
        var h = new HDON();
        h.parse(src);
        test.assert(h._package == 'a.b', 'parsed package');
        test.assert(h._className == 'Foo', 'parsed class name');
        test.assert(h._extends == 'Bar', 'parsed extends');
        test.assert(h._implements.length == 2 && h._implements[0] == 'IOne' && h._implements[1] == 'ITwo', 'parsed implements');
        test.assert(h._jsonString.indexOf('"a"') != -1 && h._jsonString.indexOf('"name"') != -1, 'keys quoted in json');
    }

    public function test_parse_with_no_markers_defaults_empty_data(test: Test) {
        var src = 'class Plain { }';
        var h = new HDON();
        h.parse(src);
        test.assert(h._jsonString == '{}', 'empty json if no @:data');
    }

    public function test_fromJSONString_builds_basic_class(test: Test) {
        var h = HDON.fromJSONString('x.y.MyClass', '{"k": 3}');
        test.assert(h._package == 'x.y', 'pkg from classPath');
        test.assert(h._className == 'MyClass', 'name from classPath');
        test.assert(h._jsonString.indexOf('"k"') != -1, 'json kept');
    }

    public function test_fromJSONObject_and_fromObject_equivalence(test: Test) {
        var obj: Dynamic = { k: 5, s: 'hi' };
        var h1 = HDON.fromObject('M', obj);
        var h2 = HDON.fromJSONObject('M', obj);
        test.assert(h1._jsonString == h2._jsonString, 'object and jsonObject produce same json');
    }

    public function test_haxe_like_to_json_and_back_integration(test: Test) {
        var src = 'class C {\n @:data var _data = { a: 1, b: { c: 2 } };\n}';
        var h = new HDON();
        h.parse(src);
        test.assert(h._jsonString.indexOf('"a"') != -1, 'keys quoted after parse');
        var classStr = h.stringify();
        test.assert(classStr.indexOf('a: 1') != -1, 'keys unquoted after stringify');
    }
}