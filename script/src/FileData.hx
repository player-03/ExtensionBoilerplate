package;

class FileData {
	public var path:String;
	
	public function new(path:String) {
		this.path = path;
	}
	
	public function toString():String {
		return "File at " + path;
	}
}
