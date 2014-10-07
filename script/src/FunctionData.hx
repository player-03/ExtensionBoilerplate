package;

class FunctionData {
	/**
	 * Matches a C-style function declaration contained on a single line,
	 * with no checks to make sure the identifiers are valid.
	 */
	public static var FUNCTION_MATCHER:EReg = ~/([a-z]+)( +| *\* *)(\w+) *\(((?: *(?:const )?[a-z]+(?: +| *\* *)\w+ *,? *)*)\) *;/i;
	/**
	 * Matches an argument in a C-style function declaration.
	 */
	private static var ARGUMENT_MATCHER:EReg = ~/(?:const )?([a-z]+)( +| *\* *)(\w+) *(?:,|$)/i;
	
	public var namespace:String;
	public var returnType:String;
	public var name:String;
	public var splitName:String;
	public var args:Array<VariableData>;
	
	/**
	 * Because templates can't count.
	 */
	public var argsCount:Int;
	/**
	 * Because templates can't do other computation either. AFAIK.
	 */
	public var returnTypeIsVoid:Bool;
	
	/**
	 * Creates a function based on the current value matched by
	 * FUNCTION_MATCHER. Results unspecified if FUNCTION_MATCHER did not
	 * just match a string.
	 * @param	namespace The namespace that the function was found in.
	 */
	public function new(namespace:String) {
		this.namespace = namespace;
		
		returnType = Utils.convertType(FUNCTION_MATCHER.matched(1)
				+ StringTools.trim(FUNCTION_MATCHER.matched(2)));
		returnTypeIsVoid = returnType == "void";
		name = FUNCTION_MATCHER.matched(3);
		splitName = Utils.splitCamelCase(name).toLowerCase();
		
		args = new Array<VariableData>();
		var argsSource:String = FUNCTION_MATCHER.matched(4);
		while(ARGUMENT_MATCHER.match(argsSource)) {
			argsSource = ARGUMENT_MATCHER.matchedRight();
			
			args.push(new VariableData(ARGUMENT_MATCHER.matched(1)
										+ StringTools.trim(ARGUMENT_MATCHER.matched(2)),
										ARGUMENT_MATCHER.matched(3)));
		}
		argsCount = args.length;
		if(argsCount > 0) {
			args[argsCount - 1].isLast = true;
		}
	}
	
	public function toString():String {
		return '$returnType $name(${args.join(", ")})';
	}
}
