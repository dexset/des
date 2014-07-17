module descl.glinterop.memory;

import desgl.base;
import descl.base;
import descl.memory;
import descl.commandqueue;

import descl.glinterop.context;

class CLGLMemory : CLMemory
{
protected:
    this( cl_mem id, Type type, ulong flags )
    { super( id, type, flags ); }

public:

    static auto createFromGLBuffer( CLGLContext context, ulong flags, GLBuffer buffer )
    in { assert( checkFlags( flags ) ); } body
    {
        int retcode;
        auto id = clCreateFromGLBuffer( context.id, flags, buffer.id, &retcode );
        checkError( retcode, "clCreateFromGLBuffer" );

        return new CLGLMemory( id, Type.BUFFER, flags );
    }

    static auto createFromGLTexture( CLGLContext context, ulong flags, GLTexture texture )
    in { assert( checkFlags( flags ) ); } body
    {
        int retcode;
        CLMemory.Type tp;
        cl_mem id;
        if( texture.type == texture.Target.T2D )
        {
            id = clCreateFromGLTexture2D( context.id, flags, texture.type, 
                                            0, texture.id, &retcode );
            tp = Type.IMAGE2D;
        }
        else if( texture.type == texture.Target.T3D )
        {
            id = clCreateFromGLTexture3D( context.id, flags, texture.type, 
                                            0, texture.id, &retcode );
            tp = Type.IMAGE3D;
        }
        else throw new CLException( format( "unsupported gl texture type %s", texture.type) );
        checkError( retcode, "clCreateFromGLTexture" );
        return new CLGLMemory( id, tp, flags );
    }

    void acquireFromGL( CLCommandQueue command_queue )
    {
        checkCall!(clEnqueueAcquireGLObjects)( command_queue.id, 1u, &id, 
                0, cast(cl_event*)null, cast(cl_event*)null ); // TODO events
    }

    void releaseToGL( CLCommandQueue command_queue )
    {
        checkCall!(clEnqueueReleaseGLObjects)( command_queue.id, 1u, &id, 
                0, cast(cl_event*)null, cast(cl_event*)null ); // TODO events
    }
}
