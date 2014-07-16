module descl.event;

import descl.base;
import descl.context;

class CLEvent : CLReference
{
package:
    cl_event id;

    this( cl_event id )
    {
        this.id = id;
    }

public:

    CLEvent createUserEvent( CLContext context )
    {
        int retcode;
        auto id = clCreateUserEvent( context.id, &retcode );
        checkError( retcode, "clCreateUserEvent" );
        return new CLEvent( id );
    }

    void release() { checkCall!(clReleaseEvent)(id); }

    enum CommandType
    {
        NDRANGE_KERNEL       = CL_COMMAND_NDRANGE_KERNEL,
        TASK                 = CL_COMMAND_TASK,
        NATIVE_KERNEL        = CL_COMMAND_NATIVE_KERNEL,
        READ_BUFFER          = CL_COMMAND_READ_BUFFER,
        WRITE_BUFFER         = CL_COMMAND_WRITE_BUFFER,
        COPY_BUFFER          = CL_COMMAND_COPY_BUFFER,
        READ_IMAGE           = CL_COMMAND_READ_IMAGE,
        WRITE_IMAGE          = CL_COMMAND_WRITE_IMAGE,
        COPY_IMAGE           = CL_COMMAND_COPY_IMAGE,
        COPY_BUFFER_TO_IMAGE = CL_COMMAND_COPY_BUFFER_TO_IMAGE,
        COPY_IMAGE_TO_BUFFER = CL_COMMAND_COPY_IMAGE_TO_BUFFER,
        MAP_BUFFER           = CL_COMMAND_MAP_BUFFER,
        MAP_IMAGE            = CL_COMMAND_MAP_IMAGE,
        UNMAP_MEM_OBJECT     = CL_COMMAND_UNMAP_MEM_OBJECT,
        MARKER               = CL_COMMAND_MARKER,
        ACQUIRE_GL_OBJECTS   = CL_COMMAND_ACQUIRE_GL_OBJECTS,
        RELEASE_GL_OBJECTS   = CL_COMMAND_RELEASE_GL_OBJECTS
    }

    enum CommandExecutionStatus
    {
        QUEUED    = CL_QUEUED,
        SUBMITTED = CL_SUBMITTED,
        RUNNING   = CL_RUNNING,
        COMPLETE  = CL_COMPLETE
    }

    static private enum prop_list = 
    [
        "cl_command_type:CommandType:command_type",
        "cl_int:CommandExecutionStatus:command_execution_status"
    ];

    mixin( infoProperties( "event", prop_list ) );
}
