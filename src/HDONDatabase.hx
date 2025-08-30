import HDON;
import haxe.io.Path;
using StringTools;

class HDONDatabase {

	//this is a directory of HDON files
	//you can instantiate it by passing a directory path
	//this does the work of maintaining a valid package struture
	//you can find HDON files by their name and classpath here
	//you can export this entire "database" to a folder, which writes all the files to the folder using the package structure

	public var rootDirectory:String;
	public var classPathToHDON:Map<String, HDON>;
	public var classNameToClassPaths:Map<String, Array<String>>;

	public function new(rootDirectory:String = null) {
		this.rootDirectory = rootDirectory;
		classPathToHDON = new Map();
		classNameToClassPaths = new Map();
		#if sys
		if (rootDirectory != null && sys.FileSystem.exists(rootDirectory)) {
			scanAndIndexDirectory(rootDirectory);
		}
		#end
	}

	public function put(hdon:HDON):String {
		var cp = computeClassPath(hdon);
		classPathToHDON.set(cp, hdon);
		indexClassName(cp);
		return cp;
	}

	public function putFromJSONString(classPath:String, json:String):HDON {
		var h = HDON.fromJSONString(classPath, json);
		put(h);
		return h;
	}

	public function putFromObject(classPath:String, obj:Dynamic):HDON {
		var h = HDON.fromObject(classPath, obj);
		put(h);
		return h;
	}

	public function getByClassPath(classPath:String):Null<HDON> {
		return classPathToHDON.get(classPath);
	}

	public function findByClassName(className:String):Array<HDON> {
		var results:Array<HDON> = [];
		var paths = classNameToClassPaths.get(className);
		if (paths != null) {
			for (p in paths) {
				var h = classPathToHDON.get(p);
				if (h != null) results.push(h);
			}
		}
		return results;
	}

	public function listClassPaths():Array<String> {
		var out:Array<String> = [];
		for (k in classPathToHDON.keys()) out.push(k);
		out.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
		return out;
	}

	public function exportToFolder(outputRoot:String):Void {
		#if sys
		for (cp in listClassPaths()) {
			var h = classPathToHDON.get(cp);
			if (h == null) continue;
			var dir = packageToDir(outputRoot, h._package);
			ensureDirectoryExists(dir);
			var filePath = Path.join([dir, h._className + '.hx']);
			var contents = h.stringify();
			sys.io.File.saveContent(filePath, contents);
		}
		#end
	}

	// Helpers
	static inline function computeClassPath(h:HDON):String {
		var pkg = h._package != null ? h._package.trim() : '';
		return pkg.length > 0 ? (pkg + '.' + h._className) : h._className;
	}

	#if sys
	private function scanAndIndexDirectory(dir:String):Void {
		for (entry in sys.FileSystem.readDirectory(dir)) {
			var full = Path.join([dir, entry]);
			if (sys.FileSystem.isDirectory(full)) {
				scanAndIndexDirectory(full);
			} else if (StringTools.endsWith(entry, '.hx')) {
				var content = sys.io.File.getContent(full);
				var h = new HDON();
				h.parse(content);
				put(h);
			}
		}
	}

	static function packageToDir(root:String, pkg:String):String {
		var segments:Array<String> = [root];
		if (pkg != null && pkg.trim().length > 0) {
			for (p in pkg.split('.')) if (p.trim().length > 0) segments.push(p);
		}
		return Path.join(segments);
	}

	static function ensureDirectoryExists(path:String):Void {
		if (path == null || path.trim().length == 0) return;
		var norm = Path.normalize(path);
		var unified = norm.split("\\").join("/");
		var parts:Array<String> = [];
		for (segment in unified.split('/')) {
			if (segment.trim().length == 0) continue;
			parts.push(segment);
			var cur = Path.join(parts.copy());
			if (!sys.FileSystem.exists(cur)) sys.FileSystem.createDirectory(cur);
		}
	}
	#end

	private function indexClassName(classPath:String):Void {
		var lastDot = classPath.lastIndexOf('.');
		var name = lastDot == -1 ? classPath : classPath.substr(lastDot + 1);
		var arr = classNameToClassPaths.get(name);
		if (arr == null) {
			arr = [];
			classNameToClassPaths.set(name, arr);
		}
		// prevent duplicates on re-scan
		var exists = false;
		for (p in arr) if (p == classPath) { exists = true; break; }
		if (!exists) arr.push(classPath);
	}

}