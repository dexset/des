module des.gl.object;

import des.gl.general;

///
abstract class GLObject(string Subj,bool write_bind=true) : DesObject
{
    mixin DES;
    mixin ClassLogger;
private:

    uint _id;

    static string callFormat(Args...)( string fmt, Args args )
    { return format( "checkGLCall!"~fmt, args ); }

protected:

    GLenum _target;

    ///
    string log_name;

public:

    /// `glGen<subject>s( 1, &_id )`
    this( GLenum trg )
    {
        _target = trg;
        mixin( callFormat( "glGen%ss( 1, &_id );", Subj ) );
        logger = new InstanceLogger( this,
                format( "%s%d", (log_name ? log_name ~ ":" : ""), _id ) );
    }

    final pure const nothrow @nogc @property
    {
        ///
        GLenum target() { return _target; }

        /// return _id
        uint id() { return _id; }
    }

    static if( write_bind )
    {
        /// `glBind<subject>( target, id )`
        void bind()
        {
            mixin( callFormat( "glBind%s( target, id );", Subj ) );
            debug logger.trace( "pass" );
        }

        /// `glBind<subject>( target, 0 )`
        void unbind()
        {
            mixin( callFormat( "glBind%s( target, 0 );", Subj ) );
            debug logger.trace( "pass" );
        }
    }
    else
    {
        abstract void bind();
        abstract void unbind();
    }

protected:

    override void selfDestroy()
    {
        unbind();
        mixin( format( "checkGLCall!glDelete%ss( 1, &_id );", Subj ) );
        logger.Debug( "pass" );
    }
}
