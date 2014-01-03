//
//  MPWLLVMAssemblyGenerator.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/13.
//
//

#import "MPWLLVMAssemblyGenerator.h"

@implementation MPWLLVMAssemblyGenerator

objectAccessor(NSMutableDictionary, selectorReferences, setSelectorReferences)

objectAccessor(NSString, nsnumberclassref, setNSnumberclassref)

-(id)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    [self setSelectorReferences:[NSMutableDictionary dictionary]];
    return self;
}

-(NSString*)selectorForName:(NSString*)selectorName
{
    NSString *ref=selectorReferences[selectorName];
    if ( !ref ) {
        ref=[NSString stringWithFormat:@"\\01L_OBJC_SELECTOR_REFERENCES_%d",(int)[selectorReferences count]];
        selectorReferences[selectorName]=ref;
    }
    return ref;
}

-(void)writeHeaderWithName:(NSString*)name
{
    [self printLine:@"%%object = type opaque"];
    [self printLine:@"%%id = type %%object*"];
    

    [self printLine:@"; ModuleID = '%@'",name];
    [self printLine:@"target datalayout = \"e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128\""];
    [self printLine:@"target triple = \"x86_64-apple-macosx10.9.0\""];
 
    [self printLine:@"%%struct.NSConstantString = type { i32*, i32, i8*, i64 }"];

    [self printLine:@"%%struct._objc_cache = type opaque"];
    [self printLine:@"%%struct._class_t = type { %%struct._class_t*, %%struct._class_t*, %%struct._objc_cache*, i8* (i8*, i8*)**, %%struct._class_ro_t* }"];
    [self printLine:@"%%struct._class_ro_t = type { i32, i32, i32, i8*, i8*, %%struct.__method_list_t*, %%struct._objc_protocol_list*, %%struct._ivar_list_t*, i8*, %%struct._prop_list_t* }"];
    [self printLine:@"%%struct.__method_list_t = type { i32, i32, [0 x %%struct._objc_method] }"];
    [self printLine:@"%%struct._objc_method = type { i8*, i8*, i8* }"];
    [self printLine:@"%%struct._objc_protocol_list = type { i64, [0 x %%struct._protocol_t*] }"];
    [self printLine:@"%%struct._protocol_t = type { i8*, i8*, %%struct._objc_protocol_list*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct._prop_list_t*, i32, i32, i8** }"];
    [self printLine:@"%%struct._prop_list_t = type { i32, i32, [0 x %%struct._prop_t] }"];
    [self printLine:@"%%struct._prop_t = type { i8*, i8* }"];
    [self printLine:@"%%struct._ivar_list_t = type { i32, i32, [0 x %%struct._ivar_t] }"];
    [self printLine:@"%%struct._ivar_t = type { i64*, i8*, i8*, i32, i32 }"];
    [self printLine:@"%%struct._category_t = type { i8*, %%struct._class_t*, %%struct.__method_list_t*, %%struct.__method_list_t*, %%struct._objc_protocol_list*, %%struct._prop_list_t* }"];
    
    
    [self printLine:@"@_objc_empty_cache = external global %%struct._objc_cache"];
    [self printLine:@"@_objc_empty_vtable = external global i8* (i8*, i8*)*"];
    [self printLine:@"@__CFConstantStringClassReference = external global [0 x i32]"];

    NSString* nsnumberclass=@"NSNumber";
    NSString* nsnumbersymbol=[self classSymbolForName:nsnumberclass isMeta:NO];
    [self writeExternalReferenceWithName:nsnumbersymbol type:@"%struct._class_t"];
    [self setNSnumberclassref:@"\01L_OBJC_CLASSLIST_REFERENCES_NSNUMBER"];
    
    [self printLine:@"@\"%@\" = internal global %%struct._class_t* @\"%@\", section \"__DATA, __objc_classrefs, regular, no_dead_strip\", align 8",[self nsnumberclassref ],nsnumbersymbol];
}

-(void)writeExternalReferenceWithName:(NSString*)name type:(NSString*)type
{
    [self printLine:@"@\"%@\" = external global %@",name,type];
}


-(void)generateCString:(NSString*)cstring symbol:(NSString*)symbolName type:(NSString*)type
{
    NSString *sectionString=[NSString stringWithFormat:@"section \"__TEXT,%@,cstring_literals\", align 1",type];
    [self printLine:@"@\"%@\" = internal global [%ld x i8] c\"%@\\00\", %@",symbolName,[cstring length]+1,cstring,sectionString];
}

-(void)writeNSConstantString:(NSString*)value withSymbol:(NSString*)symbol
{
    // currently still ignores the value
    int stringLen=(int)[value length];
    int withNull=stringLen+1;
    numStrings++;
    
    [self printFormat:@"@.str_%d = linker_private unnamed_addr constant [%d x i8] c\"",numStrings,withNull ];
    for (int i=0;i<[value length];i++) {
        unichar ch=[value characterAtIndex:i];
        if ( ch < 32 ) {
            [self printFormat:@"\\0%x",ch];
        } else {
            [self printFormat:@"%c",ch];
        }
    }
    [self printLine:@"\\00\", align 1"];
    
    [self printLine:@"%@ = private constant %%struct.NSConstantString { i32* getelementptr inbounds ([0 x i32]* @__CFConstantStringClassReference, i32 0, i32 0), i32 1992, i8* getelementptr inbounds ([%d x i8]* @.str_%d, i32 0, i32 0), i64 %d }, section \"__DATA,__cfstring\"",symbol,withNull,numStrings,stringLen];
}



-(NSString*)classSymbolForName:(NSString*)className isMeta:(BOOL)isMeta
{
    NSString* base=isMeta ? @"OBJC_METACLASS_$_" : @"OBJC_CLASS_$_";
    return [base stringByAppendingString:className];
}

-(void)writeClassStructWithLabel:(NSString*)structLabel
                       className:(NSString*)classNameSymbol
                         nameLen:(long)nameLenNull
                          param1:(int)p1
                          param2:(int)p2
                   methodListRef:(NSString*)methodListRefSymbol
                      numMethods:(int)numMethods
{
    NSString *methodListRef= methodListRefSymbol ? [NSString stringWithFormat:@"bitcast ({ i32, i32, [%d x %%struct._objc_method] }* @\"%@\" to %%struct.__method_list_t*)",numMethods,methodListRefSymbol] : @"null";
    [self printLine:@"@\"%@\" = internal global %%struct._class_ro_t { i32 %d, i32 %d, i32 %d, i8* null, i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), %%struct.__method_list_t* %@, %%struct._objc_protocol_list* null, %%struct._ivar_list_t* null, i8* null, %%struct._prop_list_t* null }, section \"__DATA, __objc_const\", align 8",structLabel,p1,p2,p2,nameLenNull,classNameSymbol,methodListRef];
}

-(void)writeClassDefWithLabel:(NSString*)classSymbol
                  structLabel:(NSString*)classStructSymbol
              superClassSymbol:(NSString*)superClassSymbol
              metaClassSymbol:(NSString*)metaClassSymbol
{
    [self printLine:@"@%@ = global %%struct._class_t { %%struct._class_t* @\"%@\", %%struct._class_t* @\"%@\", %%struct._objc_cache* @_objc_empty_cache, i8* (i8*, i8*)** @_objc_empty_vtable, %%struct._class_ro_t* @\"%@\" }, section \"__DATA, __objc_data\", align 8",classSymbol,metaClassSymbol,superClassSymbol,classStructSymbol];
}

-(void)writeClassWithName:(NSString*)aName superclassName:(NSString*)superclassName instanceMethodListRef:(NSString*)instanceMethodListSymbol numInstanceMethods:(int)numInstanceMethods
{
    long nameLen=[aName length];
    long nameLenNull=nameLen+1;
    NSString *superClassSymbol = [self classSymbolForName:superclassName isMeta:NO];
    NSString *superMetaClassSymbol =[self classSymbolForName:superclassName isMeta:YES];

    NSString *classSymbol = [self classSymbolForName:aName isMeta:NO];
    NSString *metaClassSymbol =[self classSymbolForName:aName isMeta:YES];

    NSString *classNameSymbol = [@"\\01L_OBJC_CLASS_NAME_" stringByAppendingString:aName];
    NSString *metaClassStructSymbol = [@"\\01l_OBJC_METACLASS_RO_$_" stringByAppendingString:aName];
    NSString *classStructSymbol =[@"\\01l_OBJC_CLASS_RO_$_" stringByAppendingString:aName];
    NSString *classLabelSymbol =[@"\\01L_OBJC_LABEL_CLASS_$_" stringByAppendingString:aName];
    
    [self writeExternalReferenceWithName:superClassSymbol type:@"%struct._class_t"];
    [self writeExternalReferenceWithName:superMetaClassSymbol type:@"%struct._class_t"];
    
    
    [self generateCString:aName symbol:classNameSymbol type:@"__objc_classname"];

    
    [self writeClassStructWithLabel:metaClassStructSymbol className:classNameSymbol nameLen:nameLenNull param1:1 param2:40 methodListRef:nil numMethods:0];
    [self writeClassDefWithLabel:metaClassSymbol structLabel:metaClassStructSymbol superClassSymbol:superMetaClassSymbol metaClassSymbol:superClassSymbol];
    
    
    [self writeClassStructWithLabel:classStructSymbol className:classNameSymbol nameLen:nameLenNull param1:0 param2:8 methodListRef:instanceMethodListSymbol numMethods:numInstanceMethods];
    [self writeClassDefWithLabel:classSymbol structLabel:classStructSymbol superClassSymbol:superClassSymbol metaClassSymbol:metaClassSymbol];
    
    [self printLine:@"@\"\%@\" = internal global [1 x i8*] [i8* bitcast (%%struct._class_t* @\"%@\" to i8*)], section \"__DATA, __objc_classlist, regular, no_dead_strip\", align 8",classLabelSymbol, classSymbol];
    [self printLine:@"@llvm.used = appending global [2 x i8*] [i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), i8* bitcast ([1 x i8*]* @\"%@\" to i8*)], section \"llvm.metadata\"",nameLenNull,classNameSymbol,classLabelSymbol];
    
}

-(void)writeCategoryNamed:(NSString*)categoryName ofClass:(NSString*)aName instanceMethodListRef:(NSString*)methodListRefSymbol numInstanceMethods:(int)numMethods
{
    NSString *classNameSymbol = [self classSymbolForName:aName isMeta:NO];
    [self writeExternalReferenceWithName:classNameSymbol type:@"%struct._class_t"];
    NSString *categoryNameStringSymbol=[NSString stringWithFormat:@"\\01L_OBJC_CATEGORY_NAME_%@",categoryName];
    
    [self generateCString:categoryName symbol:categoryNameStringSymbol type:@"__objc_classname"];
   
    NSString *methodListRef= methodListRefSymbol ? [NSString stringWithFormat:@"bitcast ({ i32, i32, [%d x %%struct._objc_method] }* @\"%@\" to %%struct.__method_list_t*)",numMethods,methodListRefSymbol] : @"null";

    [self printLine:@"@\"\\01l_OBJC_$_CATEGORY_NSObject_$_empty\" = internal global %%struct._category_t { i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), %%struct._class_t* @\"OBJC_CLASS_$_NSObject\", %%struct.__method_list_t* %@, %%struct.__method_list_t* null, %%struct._objc_protocol_list* null, %%struct._prop_list_t* null }, section \"__DATA, __objc_const\", align 8",[categoryName length]+1, categoryNameStringSymbol,methodListRef];
    [self printLine:@"@\"\\01L_OBJC_LABEL_CATEGORY_$\" = internal global [1 x i8*] [i8* bitcast (%%struct._category_t* @\"\\01l_OBJC_$_CATEGORY_NSObject_$_empty\" to i8*)], section \"__DATA, __objc_catlist, regular, no_dead_strip\", align 8"];


}

static NSString *typeCharToLLVMType( char typeChar ) {
    switch (typeChar) {
        case '@':
            return @"%id ";
        case ':':
            return @"i8* ";
        case 'i':
            return @"i32 ";
        default:
            [NSException raise:@"invalidtype" format:@"unrecognized type char '%c' when converting to LLVM types",typeChar];
            return @"";
    }
}


-(NSString*)typeStringToLLVMMethodType:(NSString*)typeString
{
    NSMutableString *llvmType=[NSMutableString string];
    char typeBytes[1000];
    NSUInteger len=0;
    [typeString getBytes:typeBytes maxLength:900 usedLength:&len encoding:NSASCIIStringEncoding options:0 range:NSMakeRange(0, [typeString length]) remainingRange:NULL];
    int from,to=0;
    for (from=0;from<len;from++) {
        char cur=typeBytes[from];
        if ( !isdigit(cur)) {
            typeBytes[to++]=cur;
        }
    }
    typeBytes[to]=0;
    from=0;
    [llvmType appendString:typeCharToLLVMType(typeBytes[from++])];
    [llvmType appendString:@"( "];
    while ( from < to) {
        [llvmType appendString:typeCharToLLVMType(typeBytes[from++])];
        if ( from < to ) {
            [llvmType appendString:@", "];
        }
    }
    [llvmType appendString:@")"];

    return llvmType;
}

-(NSString*)methodListForClass:(NSString*)className methodNames:(NSArray*)methodNames methodSymbols:(NSArray*)methodSymbols methodTypes:(NSArray*)typeStrings
{
    NSString *methodListSymbol=[@"\\01l_OBJC_$_INSTANCE_METHODS_" stringByAppendingString:className];
    NSMutableArray *nameSymbols=[NSMutableArray array];
    NSMutableArray *typeSymbols=[NSMutableArray array];
    int methodCount=(int)[methodSymbols count];
    
    for (int i=0;i<[methodNames count];i++) {
        NSString *methodTypeString=typeStrings[i];
        NSString *methodName=methodNames[i];
        NSString *nameSymbol=[NSString stringWithFormat:@"\\01L_OBJC_METH_VAR_NAME_%d",i];
        NSString *typeSymbol=[NSString stringWithFormat:@"\\01L_OBJC_METH_VAR_TYPE_%d",i];
        [self generateCString:methodName symbol:nameSymbol type:@"__objc_methname"];
        [self generateCString:methodTypeString symbol:typeSymbol type:@"__objc_methtype"];
        [nameSymbols addObject:nameSymbol];
        [typeSymbols addObject:typeSymbol];
    }
    
    
    [self printFormat:@"@\"%@\" = internal global { i32, i32, [%d x %%struct._objc_method] } { i32 24, i32 %d, [%d x %%struct._objc_method] [ ",methodListSymbol,methodCount,methodCount,methodCount];
    for (int i=0;i<methodCount;i++) {
        NSString *methodSymbol=methodSymbols[i];
        NSString *methodTypeString=typeStrings[i];
        NSString *methodName=methodNames[i];
        if (i!=0) {
            [self printFormat:@", "];
        }
        [self printFormat:@"%%struct._objc_method { i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), i8* bitcast ( %@ * @\"\\01%@\" to i8*) } ",[methodName length]+1, nameSymbols[i],[methodTypeString length]+1, typeSymbols[i],[self typeStringToLLVMMethodType:typeStrings[i]],methodSymbol];

    }
    [self printLine:@" ] }, section \"__DATA, __objc_const\", align 8"];
    return methodListSymbol;
}


-(void)flushSelectorReferences
{
    __block int num=0;
    [selectorReferences enumerateKeysAndObjectsUsingBlock:^(id selector, id sel_reference, BOOL *stop) {
        NSString *symbol=[NSString stringWithFormat:@"\\01L_OBJC_METH_VAR_NAME_REF_%d",num++];
        [self generateCString:selector  symbol:symbol type:@"__objc_methname"];
        [self printLine:@"@\"%@\" = internal externally_initialized global i8* getelementptr inbounds ([%d x i8]* @\"%@\", i32 0, i32 0), section \"__DATA, __objc_selrefs, literal_pointers, no_dead_strip\"",sel_reference,[selector length]+1,symbol];
    }];
    
    
}

-(NSString*)allocLocal:(NSString*)type
{
    numLocals++;
    NSString *localName=[NSString stringWithFormat:@"%%%d",numLocals];
    [self printLine:@"%@ = alloca %@, align 8",localName,type];
    return localName;
}

-(void)writeMethodHeaderWithName:(NSString*)methodFunctionName returnType:(NSString*)returnType additionalParametrs:(NSArray*)additionalParams
{
    [self printFormat:@"define internal %@ @\"\\01%@\"(%%id %%self, i8* %%_cmd",returnType, methodFunctionName];
    for ( NSString *param in additionalParams) {
        [self printFormat:@", %@",param];
    }
    [self printLine:@" ) uwtable ssp {"];
    [self printLine:@"%%1 = alloca %%id, align 8"];
    [self printLine:@"%%2 = alloca i8*, align 8"];
    [self printLine:@"store %%id %%self, %%id* %%1, align 8"];
    [self printLine:@"store i8* %%_cmd, i8** %%2, align 8"];
    numLocals=2;
    
}


-(NSString*)emitMsg:(NSString*)msgName receiver:(NSString*)receiverName  returnType:(NSString*)retType args:(NSArray*)args argTypes:(NSArray*)argTypes
{
    NSString *selectorRef=[self selectorForName:msgName];
    numLocals++;
    int selectorIndex=numLocals;
    numLocals++;
    int returnIndex=numLocals;
    [self printLine:@"%%%d = load i8** @\"%@\", !invariant.load !4",selectorIndex,selectorRef];
    [self printFormat:@"%%%d = call %@ bitcast (i8* (i8*, i8*, ...)* @objc_msgSend to %@ (%%id, i8* ",returnIndex,retType,retType];
    for ( NSString *argType in argTypes) {
        [self printFormat:@", %@",argType];
    }
    [self printFormat:@")*)( %%id %@, i8* %%%d " ,receiverName,selectorIndex];
    for ( int i=0;i<[args count];i++) {
        [self printFormat:@", %@ %@ ",argTypes[i],args[i]];
    }
    [self printLine:@" )"];
    return [NSString stringWithFormat:@"%%%d",returnIndex];
}


-(NSString*)writeNSNumberLiteralForInt:(NSString*)theIntSymbolOrLiteral
{
    numLocals++;
    int loadedClass=numLocals;
    numLocals++;
    int bitcastClass=numLocals;
    [self printLine:@"%%%d = load %%struct._class_t** @\"%@\", align 8",loadedClass,[self nsnumberclassref ]];
    [self printLine:@"%%%d = bitcast %%struct._class_t* %%%d to %%id",bitcastClass,loadedClass];
    NSString *retval=[self emitMsg:@"numberWithInt:" receiver:[NSString stringWithFormat:@"%%%d",bitcastClass] returnType:@"%id" args:@[ theIntSymbolOrLiteral ] argTypes:@[ @"i32"]];
    return retval;
}

-(NSString*)writeMethodNamed:(NSString*)methodName className:(NSString*)className methodType:(NSString*)methodType additionalParametrs:(NSArray*)params methodBody:(void (^)(MPWLLVMAssemblyGenerator*  ))block
{
    NSString *methodFunctionName=[NSString stringWithFormat:@"-[%@ %@]",className,methodName];
    
    
    [self printLine:@""];
    [self writeMethodHeaderWithName:methodFunctionName returnType:methodType additionalParametrs:params];
    block( self );
    [self printLine:@"}"];
    [self printLine:@""];
    
    return methodFunctionName;
}

-(void)emitReturnVal:(NSString*)val type:(NSString*)type
{
    [self printLine:@"ret %@ %@",type,val];
}


-(NSString*)writeConstMethod1:(NSString*)className methodName:(NSString*)methodName methodType:(NSString*)typeString
{
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"%id %s", @"%id %delimiter"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        
        NSString *retval=[generator emitMsg:@"componentsSeparatedByString:" receiver:@"%s" returnType:@"%id" args:@[ @"%delimiter"] argTypes:@[ @"%id"]];
        
        [self emitReturnVal:retval type:@"%id"];
    }];
}

-(NSString*)stringRef:(NSString*)ref
{
    NSString *stringArg=[NSString stringWithFormat:@"bitcast (%%struct.NSConstantString* %@ to %%id)",ref];
    return stringArg;
}


-(NSString*)writeStringSplitter:(NSString*)className methodName:(NSString*)methodName methodType:(NSString*)typeString splitString:(NSString*)splitString
{
    NSString *splitStringSymbol=[@"@splitString" stringByAppendingString:[methodName substringToIndex:[methodName length]-1]];
    
    [self writeNSConstantString:splitString withSymbol:splitStringSymbol];
    
    [self printLine:@""];

    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"%id %s"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        NSString *retval=[self emitMsg:@"componentsSeparatedByString:" receiver:@"%s" returnType:@"%id" args:@[ [self stringRef:splitStringSymbol] ] argTypes:@[ @"%id"]];
        [self emitReturnVal:retval type:@"%id"];
    }];
}

-(NSString*)writeMakeNumberFromArg:(NSString*)className methodName:(NSString*)methodName
{
    
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[@"i32 %num"] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        [generator emitReturnVal:[generator writeNSNumberLiteralForInt:@"%num"] type:@"%id"];
    }];
    
}

-(NSString*)writeMakeNumber:(int)aNumber className:(NSString*)className methodName:(NSString*)methodName
{
    
    return [self writeMethodNamed:methodName className:className methodType:@"%id" additionalParametrs:@[ ] methodBody:^(MPWLLVMAssemblyGenerator *generator) {
        [generator emitReturnVal:[generator writeNSNumberLiteralForInt:[NSString stringWithFormat:@"%d",aNumber]] type:@"%id"];
    }];
    
}

-(void)writeTrailer
{
    [self printLine:@" declare i8* @objc_msgSend(i8*, i8*, ...) nonlazybind"];

    [self printLine:@" !llvm.module.flags = !{!0, !1, !2, !3}"];
    [self printLine:@"!0 = metadata !{i32 1, metadata !\"Objective-C Version\", i32 2}"];
    [self printLine:@"!1 = metadata !{i32 1, metadata !\"Objective-C Image Info Version\", i32 0}"];
    [self printLine:@"!2 = metadata !{i32 1, metadata !\"Objective-C Image Info Section\", metadata !\"__DATA, __objc_imageinfo, regular, no_dead_strip\"}"];
    [self printLine:@"!3 = metadata !{i32 4, metadata !\"Objective-C Garbage Collection\", i32 0}"];
    [self printLine:@"!4 = metadata !{}"];

}

@end
