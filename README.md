ExtensionBoilerplate
====================

Boilerplate code generator for OpenFL's native extensions.

The problem
-----------

Let's say I want to call this C++ method from Haxe:

TestExp.cpp

    int SampleMethod(int inputValue) {
        return inputValue * 100;
    }

I will need to add the following code as well:

Utils.h

    int SampleMethod(int inputValue);

ExternalInterface.cpp

    static value testext_sample_method (value inputValue) {
        return(alloc_int(SampleMethod(val_int(inputValue)));
    }
    DEFINE_PRIM (testext_sample_method, 1);

Build.xml

    <file name="common/TestExt.cpp"/>

This tool's purpose is to write the latter two for you, removing most of the excess work. I chose not to automatically generate header files, because I felt that would take away too much control.

Generating boilerplate
----------------------

Unfortunately, this cannot be run automatically by adding it to your extension's include.xml. Instead, you will have to run it from the command line.

Installation:

    haxelib git ExtensionBoilerplate https://github.com/player-03/ExtensionBoilerplate.git

Usage:

    haxelib run ExtensionBoilerplate --namespace YourNamespace --templates path/to/my/templates/

So what does `--namespace YourNamespace` mean? Well, the thing is, an extension can have a lot of C++ functions, and I need a way to tell which ones should be processed. I settled on filtering by namespace. Functions are only included if they're in a namespace that you specify on the command line. Don't worry, you can specify as many namespaces as you like.

And `--templates path/to/my/templates/`? This one is optional, but it's there in case the templates I provide don't work out for you. My Build.xml template sets all the default flags, but maybe you have a custom flag you want to set. All you have to do is make a copy of Build.xml, make the changes you want, and then provide the path to it. For more information, see templates/Readme.md.

I realize these are a lot of command-line arguments to type out, and that you won't need to change them very much. For your convenience, you can add an "ExtensionBoilerplate.txt" file to your extension (must be in the top-level folder). Put your extra arguments in there, run `haxelib run ExtensionBoilerplate`, and the text file's contents will be treated as command-line arguments. (Bonus: line breaks are allowed.)

Quirks
------

This tool:
- ...makes plenty of assumptions about your project structure. For instance, all source files must be in `project/`, and all header files must be in `project/include/`.
- ...only recognizes functions that are declared in header files.
- ...uses a naive method of identifying functions; if a function declaration spans multiple line, the function will not be recognized.
- ...makes no distinction between commented code and uncommented code.
- ...does not generate any Haxe code. For that, see [NDLLClassBuilder](https://github.com/player-03/haxeutils/blob/master/README.md#ndllclassbuilderhx).
