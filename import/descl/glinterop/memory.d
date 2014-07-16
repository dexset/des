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

    static auto createFromGLBuffer( CLGLContext context, ulong flags, GLVBO buffer )
    in { assert( checkFlags( flags ) ); } body
    {
        int retcode;
        auto id = clCreateFromGLBuffer( context.id, flags, buffer.id, &retcode );
        checkError( retcode, "clCreateFromGLBuffer" );

        return new CLGLMemory( id, Type.BUFFER, flags );
    }

    static auto createFromGLTexture2D( CLGLContext context, ulong flags, GLTexture2D texture )
    in { assert( checkFlags( flags ) ); } body
    {
        int retcode;
        auto id = clCreateFromGLTexture2D( context.id, flags, texture.type, 
                                           0, texture.id, &retcode );
        checkError( retcode, "clCreateFromGLTexture2D" );

        return new CLGLMemory( id, Type.IMAGE2D, flags );
    }

    static auto createFromGLTexture3D( CLGLContext context, ulong flags, GLTexture3D texture )
    in { assert( checkFlags( flags ) ); } body 
    {
        int retcode;
        auto id = clCreateFromGLTexture3D( context.id, flags, texture.type, 
                                           0, texture.id, &retcode );
        checkError( retcode, "clCreateFromGLTexture2D" );

        return new CLGLMemory( id, Type.IMAGE3D, flags );
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
