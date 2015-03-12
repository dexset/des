module des.gl.shader;

import des.gl.general;
import des.gl.texture;

///
class GLShaderException : DesGLException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}

///
class GLShader : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:

    GLenum _type;
    string _source;
    uint _id;
    bool _compiled;

public:

    pure @property
    {
        nothrow const
        {
            ///
            uint id() { return _id; }
            /// get source
            string source() { return _source; }
            ///
            GLenum type() { return _type; }
            ///
            bool compiled() { return _compiled; }
        }

        /// set source
        string source( string s ) { _source = s; return _source; }
    }

    ///
    this( GLenum tp, string src )
    {
        logger = new InstanceLogger(this);
        _type = tp;
        _source = src;
    }

    /// glCreateShader, glShaderSource, glCompileShader
    void make()
    {
        _id = checkGLCall!glCreateShader( _type );

        if( auto il = cast(InstanceLogger)logger )
            il.instance = format( "%d", _id );

        logger.Debug( "[%s] with type [%s]", _id, _type ); 

        auto src = _source.toStringz;
        checkGLCall!glShaderSource( _id, 1, &src, null );
        checkGLCall!glCompileShader( _id );

        int res;
        checkGLCall!glGetShaderiv( _id, GL_COMPILE_STATUS, &res );

        string fmtSource()
        {
            auto lines = source.splitLines();
            foreach( i, ref line; lines )
                line = format( "% 3d ", i+1 ) ~ line;
            return lines.join("\n");
        }

        if( res == GL_FALSE )
        {
            int logLen;
            checkGLCall!glGetShaderiv( _id, GL_INFO_LOG_LENGTH, &logLen );
            if( logLen > 0 )
            {
                auto chlog = new char[logLen];
                checkGLCall!glGetShaderInfoLog( _id, logLen, &logLen, chlog.ptr );
                throw new GLShaderException( "shader compile error: \n" ~ toDString(chlog.ptr) ~ "\n--- shader sources ---\n" ~ fmtSource() );
            }
        }

        _compiled = true;
        logger.Debug( "pass" );
    }

protected:

    override void selfConstruct() { make(); }

    override void selfDestroy()
    {
        if( _compiled )
            checkGLCall!glDeleteShader( _id );
        logger.Debug( "pass" );
    }
}

///
class GLVertShader : GLShader
{ this( string src="" ) { super( GL_VERTEX_SHADER, src ); } }

///
class GLFragShader : GLShader
{ this( string src="" ) { super( GL_FRAGMENT_SHADER, src ); } }

///
class GLGeomShader : GLShader
{ this( string src="" ) { super( GL_GEOMETRY_SHADER, src ); } }

/++ parse solid input string to different shaders

 Use [vert|vertex] for vertex shader,
 [geom|geometry] for geometry shader,
 [frag|fragment] for fragment shader

 Example:
    //###vert
    ... code of vertex shader ...
    //###frag
    ... cod of fragment shader ...

 +/
GLShader[] parseGLShaderSource( string src, string separator = "//###" )
{
    GLShader[] ret;

    foreach( ln; src.splitLines() )
    {
        if( ln.startsWith(separator) )
        {
            auto str_type = ln.chompPrefix(separator).strip().toLower;
            switch( str_type )
            {
                case "vert": case "vertex":   ret ~= new GLVertShader; break;
                case "geom": case "geometry": ret ~= new GLGeomShader; break;
                case "frag": case "fragment": ret ~= new GLFragShader; break;
                default: throw new GLShaderException( "parse shader source: unknown section '" ~ str_type ~ "'" );
            }
        }
        else
        {
            if( ret.length == 0 )
            {
                if( ln.strip.length == 0 ) continue;
                throw new GLShaderException( "parse shader source: no section definition" );
            }
            ret[$-1].source = ret[$-1].source ~ ln ~ '\n';
        }
    }

    return ret;
}

///
class GLShaderProgram : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:

    uint _id = 0;

    private static uint inUse = 0;
    final @property
    {
        /// check this is current shader program
        bool thisInUse() const { return inUse == _id; }

        /// glUseProgram, set this is current shader program or set zero (if u==false)
        void thisInUse( bool u )
        {
            if( ( thisInUse && u ) || ( !thisInUse && !u ) ) return;
            uint np = 0;
            if( !thisInUse && u ) np = _id;
            checkGLCall!glUseProgram( np );
            inUse = np;
        }
    }

    ///
    GLShader[] shaders;

public:

    /// `create()`
    this( GLShader[] shs )
    {
        logger = new InstanceLogger( this );
        foreach( sh; shs )
            enforce( sh !is null, new GLShaderException( "shader is null" ) );
        shaders = registerChildEMM( shs, true );
        create();
    }

    ///
    uint id() pure nothrow const @safe @property { return _id; }

    ///
    final void use() { thisInUse = true; }

protected:

    /// create program, attach shaders, bind attrib locations, link program
    void create()
    {
        _id = checkGLCall!glCreateProgram();

        if( auto il = cast(InstanceLogger)logger )
            il.instance = format( "%d", _id );

        logger.Debug( "program created" );

        attachShaders();

        bindAttribLocations();
        bindFragDataLocations();

        link();

        logger.Debug( "pass" );
    }

    /// makes shaders if are not compiled and attach their
    final void attachShaders()
    {
        foreach( sh; shaders )
        {
            if( !sh.compiled ) sh.make();
            checkGLCall!glAttachShader( _id, sh.id );
        }
        logger.Debug( "pass" );
    }

    ///
    final void detachShaders()
    {
        foreach( sh; shaders )
            checkGLCall!glDetachShader( _id, sh.id );
        logger.Debug( "pass" );
    }

    /// check link status, throw exception if false
    void check()
    {
        int res;
        checkGLCall!glGetProgramiv( _id, GL_LINK_STATUS, &res );
        if( res == GL_FALSE )
        {
            int logLen;
            checkGLCall!glGetProgramiv( _id, GL_INFO_LOG_LENGTH, &logLen );
            if( logLen > 0 )
            {
                auto chlog = new char[logLen];
                checkGLCall!glGetProgramInfoLog( _id, logLen, &logLen, chlog.ptr );
                throw new GLShaderException( "program link error: \n" ~ chlog.idup );
            }
        }
    }

    ///
    uint[string] attribLocations() @property { return null; }

    /// uses result of `attribLocations()` call, affect after `link()` call
    final void bindAttribLocations()
    {
        foreach( key, val; attribLocations )
        {
            checkGLCall!glBindAttribLocation( _id, val, key.toStringz );
            logger.Debug( "attrib '%s' bind to location %d", key, val );
        }
        logger.Debug( "pass" );
    }

    ///
    uint[string] fragDataLocations() @property { return null; }

    /// uses result of `fragDataLocations()` call, affect after `link()` call
    final void bindFragDataLocations()
    {
        foreach( key, val; fragDataLocations )
        {
            checkGLCall!glBindFragDataLocation( _id, val, key.toStringz );
            logger.Debug( "frag data '%s' bind to location %d", key, val );
        }
        logger.Debug( "pass" );
    }

    /// link program and check status
    final void link()
    {
        checkGLCall!glLinkProgram( _id );
        check();
        logger.Debug( "pass" );
    }

    override void selfConstruct() { create(); }

    override void preChildsDestroy()
    {
        thisInUse = false;
        detachShaders();
    }

    override void selfDestroy()
    {
        checkGLCall!glDeleteProgram( _id );
        debug logger.Debug( "pass" );
    }
}

///
class CommonGLShaderProgram : GLShaderProgram
{
public:
    ///
    this( GLShader[] shs ) { super(shs); }

    ///
    int getAttribLocation( string name )
    { 
        auto ret = checkGLCall!glGetAttribLocation( _id, name.toStringz ); 
        debug if( ret < 0 ) logger.warn( "bad attribute name: '%s'", name );
        return ret;
    }

    ///
    int[] getAttribLocations( string[] names... )
    { 
        int[] ret;
        foreach( name; names )
            ret ~= getAttribLocation( name );
        return ret;
    }

    ///
    int getUniformLocation( string name )
    { return checkGLCall!glGetUniformLocation( _id, name.toStringz ); }

    ///
    void setUniform(T)( int loc, in T[] vals... ) 
        if( isAllowType!T || isAllowVector!T || isAllowMatrix!T || is( T == bool ) )
    {
        if( loc < 0 )
        {
            logger.error( "bad uniform location" );
            return;
        }

        use();

        enum fnc = "checkGLCall!glUniform";

        static if( isAllowMatrix!T )
        {
            enum args_str = "loc, cast(int)vals.length, GL_TRUE, cast(float*)vals.ptr";
            static if( T.width == T.height )
                mixin( format( "%sMatrix%dfv( %s );", fnc, T.height, args_str ) );
            else
                mixin( format( "%sMatrix%dx%dfv( %s );", fnc, T.height, T.width, args_str ) );
        }
        else static if( is( T == bool ) )
        {
            auto iv = to!(int[])(vals);
            mixin( format( "%s1iv( loc, cast(int)vals.length, iv.ptr );", fnc ) );
        }
        else
        {
            static if( isAllowVector!T )
            {
                alias X = T.datatype;
                enum sz = T.length;
            }
            else
            {
                alias X = T;
                enum sz = 1;
            }
            enum pf = glPostfix!X;
            enum cs = X.stringof;

            mixin( format( "%s%d%sv( loc, cast(int)vals.length, cast(%s*)vals.ptr );", fnc, sz, pf, cs ) );
        }
    }

    ///
    void setUniform(T)( string name, in T[] vals... ) 
        if( is( typeof( setUniform!T( 0, vals ) ) ) )
    {
        auto loc = getUniformLocation( name );
        if( loc < 0 )
        {
            logger.error( "bad uniform name: '%s'", name );
            return;
        }
        setUniform!T( loc, vals );
    }

    /// set uniform and bind texture
    void setTexture( int loc, GLTexture tex )
    in{ assert( tex !is null ); } body
    {
        if( loc < 0 )
        {
            logger.error( "bad texture location" );
            return;
        }

        tex.bind();
        setUniform!int( loc, tex.unit );
    }

    /// ditto
    void setTexture( string name, GLTexture tex )
    in{ assert( tex !is null ); } body
    {
        auto loc = getUniformLocation( name );
        if( loc < 0 )
        {
            logger.error( "bad texture name: '%s'", name );
            return;
        }
        setTexture( loc, tex );
    }
}

private pure @property
{
    bool isAllowType(T)()
    {
        return is( T == int ) ||
               is( T == uint ) ||
               is( T == float );
    }

    bool isAllowVector(T)()
    {
        static if( !isStaticVector!T ) return false;
        else return isAllowType!(T.datatype) && T.length <= 4;
    }

    unittest
    {
        static assert( isAllowVector!vec2 );
        static assert( isAllowVector!ivec4 );
        static assert( isAllowVector!uivec3 );
        static assert( !isAllowVector!dvec3 );
        static assert( !isAllowVector!rvec3 );
        static assert( !isAllowVector!(Vector!(5,float)) );
    }

    bool isAllowMatrix(T)()
    {
        static if( !isStaticMatrix!T ) return false;
        else return is( T.datatype == float ) &&
            T.width >= 2 && T.width <= 4 &&
            T.height >= 2 && T.height <= 4;
    }

    unittest
    {
        static assert( isAllowMatrix!mat4 );
        static assert( isAllowMatrix!mat2x3 );
        static assert( !isAllowMatrix!rmat2x3 );
        static assert( !isAllowMatrix!dmat2x3 );
        static assert( !isAllowMatrix!(Matrix!(5,2,float)) );
    }
}

private string castArgsString(S,string data,T...)() @property
{
    string ret = "";
    foreach( i, type; T )
        ret ~= format( "cast(%s)%s[%d],", 
                S.stringof, data, i );

    return ret[0 .. $-1];
}

unittest
{
    string getFloats(string data,T...)( in T vals )
    { return castArgsString!(float,data,vals)(); }

    assert( getFloats!"v"( 1.0f, 2u, -3 ) == "cast(float)v[0],cast(float)v[1],cast(float)v[2]" );
}

/// allows `float`, `int`, 'uint`
string glPostfix(T)() pure @property
{
         static if( is( T == float ) ) return "f";
    else static if( is( T == int ) )   return "i";
    else static if( is( T == uint ) )  return "ui";
    else static if( isStaticVector!T ) return glPostfix!(T.datatype);
    else static if( isStaticMatrix!T ) return glPostfix!(T.datatype);
    else return "";
}

///
unittest
{
    assert( glPostfix!float  == "f" );
    assert( glPostfix!int    == "i" );
    assert( glPostfix!uint   == "ui");
    assert( glPostfix!double == ""  );
}

bool isAllConv(S,Args...)() pure @property
{
    foreach( t; Args )
        if( !is( t : S ) )
            return false;
    return true;
}
