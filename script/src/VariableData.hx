package;

class VariableData {
	public var type:String;
	public var name:String;
	
	/**
	 * So that templates can decide whether to place a comma afterwards.
	 */
	public var isLast:Bool = false;
	
	public function new(type:String, name:String) {
		this.type = Utils.convertType(type);
		this.name = name;
	}
	
	public function toString():String {
		return '$type $name';
	}
}
