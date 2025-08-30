package cases;

import testcore.TestCase;
import testcore.Test;
import HDON;
using StringTools;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class HDONReadWriteConsistency extends TestCase {

    public function test_read_write_consistency(test: Test) {
        #if sys
        var resourcesDir = Sys.getCwd() + 'src/resources';
        test.assert(FileSystem.exists(resourcesDir), 'resources directory exists');
        var files = FileSystem.readDirectory(resourcesDir);
        var foundHx = false;
        for (f in files) {
            if (StringTools.endsWith(f, '.hx')) {
                foundHx = true;
                var path = resourcesDir + '/' + f;
                var original = File.getContent(path);

                var h = new HDON();
                h.parse(original);
                var rewritten = h.stringify();

                var originalCanonical = canonicalize(original);
                var rewrittenCanonical = canonicalize(rewritten);
                test.assert(originalCanonical == rewrittenCanonical, 'read-write matches for ' + f);
            }
        }
        test.assert(foundHx, 'found at least one .hx resource');
        #else
        test.assert(true, 'sys not available, skipping read-write consistency test');
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

