-- Copyright (C) 2017 ifritJP

local libs = {}
local libclangcore = require( 'libclanglua.core' )
libs.core = libclangcore

if _VERSION == "Lua 5.1" then
   table.pack = function( ... )
      return { ... }
   end
   table.unpack = function( list )
      return unpack( list )
   end
end

libs.cx2string = function( cxstr )
   local str = libclangcore.clang_getCString( cxstr )
   libclangcore.clang_disposeString( cxstr )
   return str
end

libs.visitChildrenLow = function( cursor, func, exInfo )
   if not __libclang_visit then
      __libclang_visit = {}
   end
   table.insert( __libclang_visit, { func, exInfo } )
   local result = libclangcore.clang_visitChildren( cursor, nil )

   table.remove( __libclang_visit )
   
   return result
end

libs.clang_visitChildren = function( cursor, func, exInfo )
   local wrapFunc = function( aCursor, aParent, aExInfo )
      return func( libs.CXCursor:new( aCursor ),
		   libs.CXCursor:new( aParent ), aExInfo )
   end
   return libs.visitChildrenLow( cursor, wrapFunc, exInfo )
end


libs.getInclusionsLow = function( unit, func, exInfo )
   if not __libclang_visit then
      __libclang_visit = {}
   end
   table.insert( __libclang_visit, { func, exInfo } )
   libclangcore.clang_getInclusions( unit, nil )

   table.remove( __libclang_visit )
end

libs.clang_getInclusions = function( unit, func, exInfo )
   local wrapFunc = function( included_file, inclusion_stack,
			      include_len, client_data )
      return func( libs.CXFile:new( included_file ),
		   libs.CXCXSourceLocation:new( inclusion_stack ),
		   inclusion_len, client_data )
   end
   return libs.getInclusionsLow( cursor, wrapFunc, exInfo )
end

libs.mkCharArray = function( strArray )
   local array = {
      __length = #strArray,
      __ptr = libclangcore.new_charArray( #strArray ),
      
      getLength = function( self )
	 return self.__length
      end,
      
      getPtr = function( self )
	 return self.__ptr
      end,
   }
   
   for key, str in ipairs( strArray ) do
      libclangcore.charArray_setitem( array.__ptr, key - 1, str )
   end
   return array
end

libs.isBuiltInTypeKind = function( typeKind )
   return typeKind >= libclangcore.CXType_FirstBuiltin and
      typeKind <= libclangcore.CXType_LastBuiltin
end

libs.getNamespaceList = function( cursor, includeCurrent )
   local nsList = {}
   local target = cursor

   if includeCurrent then
      table.insert( nsList, target:getCursorSpelling() )
   end
   
   while true do
      local parent = target:getCursorSemanticParent()
      target = parent
      local cursorKind = parent:getCursorKind()
      if cursorKind == libclangcore.CXCursor_InvalidFile then
	 break
      end
      if cursorKind == libclangcore.CXCursor_ClassDecl or
	 cursorKind == libclangcore.CXCursor_StructDecl or
	 cursorKind == libclangcore.CXCursor_Namespace
      then
	 table.insert( nsList, 1, parent:getCursorSpelling() )
      end
   end

   if cursor:getCursorKind() == libclangcore.CXCursor_StructDecl then
      table.insert( nsList, 1, "@struct" )
   end
   if cursor:getCursorKind() == libclangcore.CXCursor_EnumDecl then
      table.insert( nsList, 1, "@enum" )
   end

   local namespace = ""
   for index, name in ipairs( nsList ) do
      namespace = namespace .. "::" .. name
   end
   
   return nsList, namespace
end

local cxFileArray
if libs.core.new_CXFileArray then
   cxFileArray = libs.core.new_CXFileArray( 1 )
end
--   libs.core.delete_CXFileArray( cxFileArray )
libs.getFileLocation = function( obj, func, ... )
   local params = table.pack( ... )
   table.insert( params, cxFileArray )
   local result = table.pack( func( obj, table.unpack( params ) ) )
   local cxFile = libs.CXFile:new( libs.core.CXFileArray_getitem( cxFileArray, 0 ) )
   return cxFile, table.unpack( result )
end

libs.getCurosrPlainText = function( cursor )
   local txt = ""
   libs.mapCurosrPlainText(
      cursor,
      function( tokenTxt )
	 if txt ~= "" and tokenTxt ~= "}" then
	    txt = txt .. " " .. tokenTxt
	 else
	    txt = txt .. tokenTxt
	 end
	 if tokenTxt == ";" or tokenTxt == "{" or
	    string.find( tokenTxt, "*/$" ) or string.find( tokenTxt, "^//" )
	 then
	    txt = txt .. "\n"
	 end
      end
   )
   return txt
end

libs.mapCurosrPlainText = function( cursor, func, ... )
   local srcRange = libclangcore.clang_getCursorExtent( cursor )
   local unit = libclangcore.clang_Cursor_getTranslationUnit( cursor )
   local tokenPBuf = libclangcore.new_CXTokenPArray( 1 )
   local tokenNum = libclangcore.clang_tokenize( unit, srcRange, tokenPBuf )
   local tokenArray = libclangcore.CXTokenPArray_getitem( tokenPBuf, 0 )
   local txt = ""
   for index = 0, tokenNum - 1 do
      local token = libclangcore.CXTokenArray_getitem( tokenArray, index )
      func( libs.cx2string( libclangcore.clang_getTokenSpelling( unit, token ) ), ... )
   end
   libclangcore.clang_disposeTokens( unit, tokenArray, tokenNum )
   libclangcore.delete_CXTokenPArray( tokenPBuf )
end