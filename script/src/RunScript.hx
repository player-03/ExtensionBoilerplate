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

import haxe.Json;
import haxe.Log;
import haxe.PosInfos;
import haxe.Template;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

class RunScript {
	private static var sourceFileExtensions:Array<String> = ["c", "cpp", "cxx", "cc", "m", "mm"];
	private static var headerFileExtensions:Array<String> = ["h", "hpp", "hxx"];
	
	public static function main():Void {
		var arg0:String = Sys.args()[0];
		if(arg0 == "-h" || arg0 == "--help") {
			printUsage();
		} else {
			//There's very little reason for the build() function to
			//exist, but this line would feel wrong without it.
			new RunScript(Sys.args()[Sys.args().length - 1]).build();
		}
	}
	
	/**
	 * The path to the target extension, including a slash at the end.
	 */
	private var extensionDir:String;
	
	private var externalInterfaceTemplate:String = "templates/ExternalInterface.cpp";
	private var buildXmlTemplate:String = "templates/Build.xml";
	
	/**
	 * The variables that will be passed to the templates.
	 */
	private var templateContext:Dynamic;
	
	/**
	 * The macros that will be passed to the templates.
	 */
	private var templateMacros:Dynamic;
	
	/**
	 * A list of the namespaces whose functions will be exposed to Haxe.
	 * By default this consists only of the extension's name (lowercase),
	 * but you can add namespaces using the command line flag
	 * "--namespace XYZ".
	 */
	private var acceptedNamespaces:Array<String>;
	
	private function new(extensionDir:String) {
		if(!StringTools.endsWith(extensionDir, "/")
			&& !StringTools.endsWith(extensionDir, "\\")) {
			extensionDir += "/";
		}
		this.extensionDir = extensionDir;
		
		templateContext = { };
		//I'm implementing this as a template variable so that the source
		//templates don't include the message. (Because you CAN modify
		//those without your changes being overwritten.)
		templateContext.autogeneratedMessage = "This file was automatically generated.\r\nAny changes you make will be overwritten when ExtensionBoilerplate is run again.";
		
		//Get info about the extension in general.
		var extensionName:String = null;
		try {
			extensionName = Json.parse(File.getContent(extensionDir + "haxelib.json")).name;
		} catch(e:Dynamic) {
			printUsage();
			Sys.exit(1);
		}
		var illegalChars:EReg = ~/[^\w_]/;
		while(illegalChars.match(extensionName)) {
			extensionName = illegalChars.replace(extensionName, "_");
		}
		templateContext.extension = extensionName;
		templateContext.extensionLowerCase = extensionName.toLowerCase();
		
		//If the target provides an ExtensionBoilerplate.txt file, add
		//additional arguments from that.
		var args:Array<String> = Sys.args();
		if(FileSystem.exists(extensionDir + "ExtensionBoilerplate.txt")) {
			var whitespace:EReg = ~/\s+/gs;
			args = args.concat(whitespace.split(
				File.getContent(extensionDir + "ExtensionBoilerplate.txt")));
		}
		
		acceptedNamespaces = [templateContext.extensionLowerCase];
		var namespaceFlag:Bool = false;
		var templatesFlag:Bool = false;
		for(arg in args) {
			if(namespaceFlag) {
				if(~/\w+/.match(arg)) {
					acceptedNamespaces.push(arg);
				}
				namespaceFlag = false;
			} else if(arg == "-n" || arg == "--namespace") {
				namespaceFlag = true;
			} else if(templatesFlag) {
				var templatesDir:String = null;
				if(FileSystem.exists(extensionDir + arg) && FileSystem.isDirectory(extensionDir + arg)) {
					templatesDir = extensionDir + arg;
				} else if(FileSystem.exists(arg) && FileSystem.isDirectory(arg)) {
					templatesDir = arg;
				}
				if(!StringTools.endsWith(templatesDir, "/")
					&& !StringTools.endsWith(templatesDir, "\\")) {
					templatesDir += "/";
				}
				if(FileSystem.exists(templatesDir + "Build.xml")) {
					buildXmlTemplate = templatesDir + "Build.xml";
				}
				if(FileSystem.exists(templatesDir + "ExternalInterface.cpp")) {
					externalInterfaceTemplate = templatesDir + "ExternalInterface.cpp";
				}
				templatesFlag = false;
			} else if(arg == "--templates") {
				templatesFlag = true;
			} else if(arg == "-verbose" || arg == "--verbose") {
				Utils.verbose = true;
			}
		}
		
		templateMacros = { regexMatch:Utils.regexMatch, regexReplace:Utils.regexReplace,
						includeIf:Utils.includeIf };
	}
	
	private function build():Void {
		generateBuildXML();
		
		generateExternalInterface();
		
		Utils.log("ExtensionBoilerplate finished.");
	}
	
	/**
	 * Creates the Build.xml file, which requires an explicit reference
	 * to every source file that needs to be compiled.
	 */
	private function generateBuildXML():Void {
		var sourceFiles:Array<FileData> = new Array<FileData>();
		Utils.log("Adding files to Build.xml:");
		Utils.addFiles(sourceFiles, sourceFileExtensions, extensionDir + "project/");
		templateContext.sourceFiles = sourceFiles;
		
		var buildXmlIn:String = File.getContent(buildXmlTemplate);
		var buildXmlOut:FileOutput = File.write(extensionDir + "project/Build.xml");
		buildXmlOut.writeString(new Template(buildXmlIn).execute(templateContext, templateMacros));
		buildXmlOut.close();
		
		Utils.log('Saved ${extensionDir}project/Build.xml.');
	}
	
	/**
	 * Creates the ExternalInterface.cpp file, which requires information
	 * about every function that should be accessible from Haxe.
	 */
	private function generateExternalInterface():Void {
		var headerFiles:Array<FileData> = new Array<FileData>();
		Utils.log("Searching for header files:");
		Utils.addFiles(headerFiles, headerFileExtensions, extensionDir + "project/include/");
		templateContext.headerFiles = headerFiles;
		
		//Extract the functions that should be available.
		var exposedFunctions:Array<FunctionData> = new Array<FunctionData>();
		Utils.log("Adding functions to ExternalInterface:");
		for(headerFile in headerFiles) {
			Utils.extractFunctions(exposedFunctions,
							extensionDir + "project/include/" + headerFile.path,
							acceptedNamespaces);
		}
		templateContext.exposedFunctions = exposedFunctions;
		
		//If the user moved the ExternalInterface file or changed its
		//extension, respect the change.
		var externalInterfaceFile:String = Utils.findFile("ExternalInterface", extensionDir + "project");
		if(externalInterfaceFile == null) {
			externalInterfaceFile = extensionDir + "project/common/ExternalInterface.cpp";
		}
		var externalInterfaceIn:String = File.getContent(externalInterfaceTemplate);
		var externalInterfaceOut:FileOutput = File.write(externalInterfaceFile);
		externalInterfaceOut.writeString(new Template(externalInterfaceIn).execute(templateContext, templateMacros));
		externalInterfaceOut.close();
		
		Utils.log('Saved $externalInterfaceFile.');
	}
	
	private static function printUsage():Void {
		trace("Usage: haxelib run ExtensionBoilerplate [--namespace XYZ]");
		trace("You must run the command from within your extension's directory.");
		trace("You must specify a namespace for it to be exposed. You may specify as many namespaces as you like.");
	}
}


