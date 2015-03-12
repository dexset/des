module des.gl.vao;

import des.gl.general;

///
struct GLAttrib
{
    ///
    string name;

    /// by default invalid value < 0
    int location = -1;
    ///
    uint elements;
    ///
    GLType type;
    ///
    size_t stride;
    ///
    size_t offset;
    ///
    bool norm;

pure:
    ///
    this( string name, int location, uint elements,
          GLType type=GLType.FLOAT,
          size_t stride=0, size_t offset=0, bool norm=false )
    {
        this.name     = name;
        this.location = location;
        this.elements = elements;
        this.type     = type;
        this.stride   = stride;
        this.offset   = offset;
        this.norm     = norm;
    }

    size_t dataSize() const @property
    {
        if( stride ) return stride;
        return elements * sizeofGLType( type );
    }
}

/// Vertex Array Object
final class GLVAO : GLObject!("VertexArray",false)
{
protected:

    int[int] aaset;

public:
    ///
    static nothrow void unbind(){ glBindVertexArray(0); }

    /// `glGenVertexArrays`
    this()
    {
        super(0);
        logger.Debug( "pass" );
    }

    ///
    int[] enabled() const @property { return aaset.keys; }

    /// `glBindVertexArray( id )`
    override void bind()
    {
        checkGLCall!glBindVertexArray( id );
        debug logger.trace( "pass" );
    }

    /// `glBindVertexArray( 0 )`
    override void unbind()
    {
        checkGLCall!glBindVertexArray( 0 );
        debug logger.trace( "pass" );
    }

    /// `glEnableVertexAttribArray`
    void enable( int n )
    {
        debug scope(exit) logger.Debug( "[%d]", n );
        if( n < 0 ) return;
        bind();
        ntCheckGLCall!glEnableVertexAttribArray( n );
        aaset[n] = n;
    }

    /// `glDisableVertexAttribArray`
    void disable( int n )
    {
        debug scope(exit) logger.Debug( "[%d]", n );
        if( n < 0 ) return;
        bind();
        ntCheckGLCall!glDisableVertexAttribArray( n );
        aaset.remove(n);
    }
}
