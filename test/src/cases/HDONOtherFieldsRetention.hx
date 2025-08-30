package cases;

import testcore.TestCase;
import testcore.Test;
import HDON;
using StringTools;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class HDONOtherFieldsRetention extends TestCase {

    public function test_other_fields_are_preserved(test: Test) {
        #if sys
        var path = Sys.getCwd() + 'src/resources/OtherFields.hx';
        test.assert(FileSystem.exists(path), 'OtherFields resource exists');
        var original = File.getContent(path);
        var h = new HDON();
        h.parse(original);
        var rewritten = h.stringify();
        test.assert(rewritten.indexOf('var someField: String;') != -1, 'someField retained');
        test.assert(rewritten.indexOf('var someOtherField: Int;') != -1, 'someOtherField retained');
        test.assert(rewritten.indexOf('public function doStuff()') != -1, 'method retained');
        #else
        test.assert(true, 'sys not available, skipping');
        #end
    }

    public function test_other_fields_read_write_consistency(test: Test) {
        #if sys
        var path = Sys.getCwd() + 'src/resources/OtherFields.hx';
        var original = File.getContent(path);
        var h = new HDON();
        h.parse(original);
        var rewritten = h.stringify();
        test.assert(canonicalize(original) == canonicalize(rewritten), 'read-write equal for OtherFields');
        #else
        test.assert(true, 'sys not available, skipping');
        #end
    }

    static function canonicalize(source: String): String {
        var s = StringTools.replace(source, "\r\n", "\n");
        s = StringTools.replace(s, "\r", "\n");
        var lines = s.split("\n");
        var result = new Array<String>();
        var previousWasBlank = false;
        for (line in lines) {
            var rightTrimmed = StringTools.rtrim(line);
            var isBlank = StringTools.trim(rightTrimmed).length == 0;
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
        if (!StringTools.endsWith(out, "\n")) out += "\n";
        return out;
    }
}

