module descl.base;

public import derelict.opencl.cl;

package
{
    import std.string;
    import std.traits;
    import std.range;
    import std.algorithm;
    import std.array;
}

static this()
{
    DerelictCL.load();
    DerelictCL.reload(CLVersion.CL11);
}

class CLException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

interface CLReference
{
    void release();
}

package
{
    template amap(fun...) { auto amap(Range)(Range r) { return array(map!(fun)(r)); } }

    void checkError( int code, string fnc_call, string file=__FILE__, size_t line=__LINE__ )
    {
        if( code == CL_SUCCESS ) return;

        string errstr;
        mixin( getErrorSwitchStr );

        throw new CLException( format( "'%s' return error code %d: %s", 
                    fnc_call, code, errstr), file, line );
    }

    string getErrorSwitchStr( string cn = "code", string es = "errstr" )
    {
        string[] errors = 
        [
            "CL_DEVICE_NOT_FOUND",
            "CL_DEVICE_NOT_AVAILABLE",
            "CL_COMPILER_NOT_AVAILABLE",
            "CL_MEM_OBJECT_ALLOCATION_FAILURE",
            "CL_OUT_OF_RESOURCES",
            "CL_OUT_OF_HOST_MEMORY",
            "CL_PROFILING_INFO_NOT_AVAILABLE",
            "CL_MEM_COPY_OVERLAP",
            "CL_IMAGE_FORMAT_MISMATCH",
            "CL_IMAGE_FORMAT_NOT_SUPPORTED",
            "CL_BUILD_PROGRAM_FAILURE",
            "CL_MAP_FAILURE",
            "CL_INVALID_VALUE",
            "CL_INVALID_DEVICE_TYPE",
            "CL_INVALID_PLATFORM",
            "CL_INVALID_DEVICE",
            "CL_INVALID_CONTEXT",
            "CL_INVALID_QUEUE_PROPERTIES",
            "CL_INVALID_COMMAND_QUEUE",
            "CL_INVALID_HOST_PTR",
            "CL_INVALID_MEM_OBJECT",
            "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR",
            "CL_INVALID_IMAGE_SIZE",
            "CL_INVALID_SAMPLER",
            "CL_INVALID_BINARY",
            "CL_INVALID_BUILD_OPTIONS",
            "CL_INVALID_PROGRAM",
            "CL_INVALID_PROGRAM_EXECUTABLE",
            "CL_INVALID_KERNEL_NAME",
            "CL_INVALID_KERNEL_DEFINITION",
            "CL_INVALID_KERNEL",
            "CL_INVALID_ARG_INDEX",
            "CL_INVALID_ARG_VALUE",
            "CL_INVALID_ARG_SIZE",
            "CL_INVALID_KERNEL_ARGS",
            "CL_INVALID_WORK_DIMENSION",
            "CL_INVALID_WORK_GROUP_SIZE",
            "CL_INVALID_WORK_ITEM_SIZE",
            "CL_INVALID_GLOBAL_OFFSET",
            "CL_INVALID_EVENT_WAIT_LIST",
            "CL_INVALID_EVENT",
            "CL_INVALID_OPERATION",
            "CL_INVALID_GL_OBJECT",
            "CL_INVALID_BUFFER_SIZE",
            "CL_INVALID_MIP_LEVEL",
            "CL_INVALID_GLOBAL_WORK_SIZE"
        ];

        string ret = format( `switch(%s)
        {`, cn);

        foreach( errname; errors )
            ret ~= format( `case %s: %s = "%s"; break;`, errname, es, errorToDescription(errname) );

        return ret ~ format( `default: %s = "unknown error"; break;
        }`, es );

    }

    string errorToDescription( string errname )
    { return (array( map!(a=>a.toLower)(errname.split("_")) )[1 .. $]).join(" ").idup; }

    unittest
    {
        assert( errorToDescription("CL_INVALID_DEVICE_TYPE") == "invalid device type" );
    }

    void checkCall(alias fnc, string file=__FILE__, size_t line=__LINE__, Args...)( Args args )
    {
        auto fnc_call = (&fnc).stringof[2..$];
        fnc_call ~= format( "(%( %(%c%),%) )", argsToString( args ) );
        checkError( fnc(args), fnc_call, file, line );
    }

    string[] argsToString(Args...)( Args args )
    {
        static if( Args.length > 1 )
            return argsToString( args[0] ) ~ argsToString( args[1..$] );
        else
            return [ format( "%s", args[0] ) ];
    }

    string infoProperties( string subject, in string[] list )
    {
        return infoPropertiesData( list ) ~
               getInfoFunc( subject ) ~ 
               infoUpdater( "CL_" ~ subject.toUpper, list ) ~
               infoPropertiesFuncs( list );
    }

    string infoPropertiesData( in string[] list )
    {
        string ret;

        foreach( ln; list )
        {
            auto tpl = ln.split(":");
            string type;
            string name;
            if( tpl.length == 2 )
            {
                type = tpl[0];
                name = tpl[1];
            }
            else
            {
                type = tpl[1];
                name = tpl[2];
            }
            ret ~= format( "private %s %s;\n", type, fmtPropDataName(name) );
        }

        return ret;
    }

    string getInfoFunc( string subject )
    {
        return format( `
        private R getInfo(T,R=T)( uint param_name )
        {
            import std.algorithm;
            import std.array;
            static if( isArray!T )
            {
                size_t max_length = 2048;
                alias ElementEncodingType!T etype;
                alias Unqual!etype type;

                alias ElementEncodingType!T ret_etype;
                alias Unqual!etype ret_type;

                auto buf = new type[]( max_length );
                size_t len;
                checkCall!(clGet%1$sInfo)( id, param_name, buf.length, buf.ptr, &len );

                static if( is( type == etype ) )
                    return array( map!(a=>cast(ret_type)(a))( buf[0 .. len]) ).dup;
                else
                    return array( map!(a=>cast(ret_type)(a))( buf[0 .. len]) ).idup;
            }
            else
            {
                T buf;
                size_t len;
                checkCall!(clGet%1$sInfo)( id, param_name, buf.sizeof, &buf, &len );
                return cast(R)(buf);
            }
        }
        `, toCamelCase( subject ) );
    }

    string toCamelCase( string str, string splitter="_", bool upperFirst=true )
    {
        if( upperFirst )
            return ( array(map!(a=>a.capitalize)( str.split(splitter) ) ) ).join("");
        else
        {
            auto words = str.split( splitter );
            return words[0].toLower ~ (amap!(a=>a.capitalize)( words[1..$] ).join("")); 
        }
    }

    unittest
    {
        assert( toCamelCase( "program_build" ) == "ProgramBuild" );
        assert( toCamelCase( "single-precision-constant", "-", false ) == "singlePrecisionConstant" );
    }

    string infoUpdater( string prefix, in string[] list )
    {
        return format(`
        void updateProperties()
        {
%s
        }
        `, updaterCode( prefix, list ) );
    }

    string updaterCode( string prefix, in string[] list )
    {
        string ret = "import std.stdio;\n";

        foreach( ln; list )
        {
            auto tpl = ln.split(":");

            string type_in_cl;
            string type_in_d;
            string name;

            if( tpl.length == 2 )
            {
                type_in_cl = tpl[0];
                type_in_d = tpl[0];
                name = tpl[1];
            }
            else
            {
                type_in_cl = tpl[0];
                type_in_d = tpl[1];
                name = tpl[2];
            }

            debug(getinfocallparamname)
            {
            ret ~= format( `stderr.writeln( "getInfo: ", (%s).stringof, " ", %s );
                    `, propEnumName(prefix,name), propEnumName(prefix,name) );
            }
            ret ~= format( "%s = getInfo!(%s,%s)(%s);\n",
                    fmtPropDataName(name), type_in_cl, type_in_d, propEnumName(prefix,name) );
        }

        return ret;
    }

    string infoPropertiesFuncs( in string[] list )
    {
        string ret = "\n";

        foreach( tt; list )
        {
            auto tpl = tt.split(":");

            string type;
            string name;

            if( tpl.length == 2 )
            {
                type = tpl[0];
                name = tpl[1];
            }
            else
            {
                type = tpl[1];
                name = tpl[2];
            }

            ret ~= format( "@property auto %s() const { return %s; }\n", 
                              checkName(name), fmtPropDataName(name) );
        }

        return ret;
    }

    string fmtPropDataName( string name )
    { return "_" ~ checkName(name); }

    string checkName( string name )
    {
        if( name == "version" || name == "debug" ) 
            return "_" ~ name;
        return name;
    }

    string propEnumName( string prefix, string name )
    { return format( "%s_%s", prefix, name.toUpper ); }

    unittest
    {
        assert( propEnumName( "CL_PLATFORM", "name" ) == "CL_PLATFORM_NAME" );
        assert( propEnumName( "CL_PLATFORM", "nAmE" ) == "CL_PLATFORM_NAME" );
        assert( propEnumName( "CL_DEVICE", "max_work_item_dimensions" ) 
                == "CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS" );
    }
}
