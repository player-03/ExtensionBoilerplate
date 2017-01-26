/*
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 Joseph Cloutier
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package;

import haxe.io.Eof;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;

class Utils {
	public static function addFiles(list:Array<FileData>, fileExtensions:Array<String>, basePath:String, path:String = ""):Void {
		if(FileSystem.isDirectory(basePath + path)) {
			for(item in FileSystem.readDirectory(basePath + path)) {
				addFiles(list, fileExtensions, basePath, (path.length > 0 ? path + "/" : "") + item);
			}
		} else {
			var dotIndex:Int = path.lastIndexOf(".");
			if(dotIndex > 1 && fileExtensions.indexOf(path.substr(dotIndex + 1)) >= 0) {
				list.push(new FileData(path));
			}
		}
	}
	
	public static function findFile(substr:String, basePath:String):String {
		if(FileSystem.isDirectory(basePath)) {
			var f:String;
			for(item in FileSystem.readDirectory(basePath)) {
				f = findFile(substr, basePath + "/" + item);
				if(f != null) {
					return f;
				}
			}
		} else {
			if(basePath.indexOf(substr) >= 0) {
				return basePath;
			}
		}
		return null;
	}
	
	public static var NAMESPACE_MATCHER:EReg = ~/namespace +(\w+) *{/i; //}
	
	/**
	 * Given a C-style header file, extracts data for everything in the
	 * file that resembles a function declaration. (Though it can be
	 * fairly picky. For instance, the function declaration, including
	 * a semicolon at then end, must be entirely on the same line.)
	 */
	public static function extractFunctions(list:Array<FunctionData>, headerFilePath:String, acceptedNamespaces:Array<String>):Void {
		var headerInput:FileInput = File.read(headerFilePath);
		var line:String;
		var currentNamespace:String = null;
		var unclosedBrackets:Int = 0;
		while(!headerInput.eof()) {
			try {
				line = headerInput.readLine();
			} catch(e:Eof) {
				break;
			}
			
			//Track the current namespace, because it's mandatory when
			//referring to the function.
			if(NAMESPACE_MATCHER.match(line)) {
				if(currentNamespace != null) {
					trace("Warning: ExtensionBoilerplate doesn't support nested namespaces.");
				}
				currentNamespace = NAMESPACE_MATCHER.matched(1);
				unclosedBrackets = 1;
				
				//Filter the namespaces.
				if(acceptedNamespaces.indexOf(currentNamespace) < 0) {
					currentNamespace = null;
					unclosedBrackets = 0;
				}
			} else if(currentNamespace != null) {
				var c:Int;
				for(i in 0...line.length) {
					c = StringTools.fastCodeAt(line, i);
					if(c == "{".code) {
						unclosedBrackets++;
					} else if(c == "}".code) {
						unclosedBrackets--;
						if(unclosedBrackets <= 0) {
							currentNamespace = null;
							break;
						}
					}
				}
			}
			
			if(currentNamespace != null && FunctionData.FUNCTION_MATCHER.match(line)) {
				list.push(new FunctionData(currentNamespace));
			}
		}
		
		headerInput.close();
	}
	
	/**
	 * Returns the name used by hx.CFFIAPI to refer to the given type. For
	 * instance, "char*" becomes "string", because CFFI provides the
	 * val_string() and alloc_string() functions to convert to and from
	 * the char* type.
	 */
	public static function convertType(type:String):String {
		type = type.toLowerCase();
		switch(type) {
			//Void is an exception, but the template will skip the alloc_ and
			//val_ calls in that case.
			case "void", "bool", "int", "float":
				return type;
			case "char*":
				return "string";
			case "double":
				return "float";
			//I have no idea if these will really work in practice. I'm just
			//copying down the names defined in CFFIAPI.h.
			case "wchar_t*":
				return "wstring";
			case "bool*":
				return "array_bool";
			case "int*":
				return "array_int";
			case "double*":
				return "array_double";
			case "float*":
				return "array_float";
			default:
				trace('Warning: type $type may not be supported.');
				return type;
		}
	}
	
	public static function regexMatch(resolve:Dynamic, regex:String, string:String):Bool {
		var ereg:EReg = new EReg(regex, "");
		return ereg.match(string);
	}
	public static function regexReplace(resolve:Dynamic, regex:String, string:String, replacement:String):String {
		var ereg:EReg = new EReg(regex, "g");
		return ereg.replace(string, replacement);
	}
	public static function includeIf(resolve:Dynamic, condition:String, resultIf:String, resultElse:String):String {
		if(condition == "true") {
			return resultIf;
		} else {
			return resultElse;
		}
	}

}
