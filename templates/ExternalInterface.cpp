/* ::autogeneratedMessage:: */

#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>
::foreach headerFiles::#include "::path::"
::end::::foreach exposedFunctions::
static ::if returnTypeIsVoid::void::else::value::end:: ::namespace::_::splitName:: (::foreach args::value ::name::::if !isLast::, ::end::::end::) {
	::if !returnTypeIsVoid::return alloc_::returnType::(::end::::namespace::::::name::(::foreach args::val_::type::(::name::)::if !isLast::, ::end::::end::)::if !returnTypeIsVoid::)::end::;
}
DEFINE_PRIM (::namespace::_::splitName::, ::argsCount::);
::end::

extern "C" void ::extensionLowerCase::_main () {
	
	val_int(0); // Fix Neko init
	
}
DEFINE_ENTRY_POINT (::extensionLowerCase::_main);

extern "C" int ::extensionLowerCase::_register_prims () { return 0; }