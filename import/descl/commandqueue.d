module descl.commandqueue;

import descl.base;
import descl.device;
import descl.context;

class CLCommandQueue : CLReference
{
package cl_command_queue id;

public:

    enum Properties
    {
        NONE = 0,
        OUT_OF_ORDER_EXEC_MODE_ENABLE = CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE,
        PROFILING_ENABLE = CL_QUEUE_PROFILING_ENABLE
    }

    this( CLContext context, CLDevice device, Properties prop=Properties.NONE )
    {
        int retcode;
        id = clCreateCommandQueue( context.id, device.id,
                prop, &retcode );
        checkError( retcode, "clCreateCommandQueue" );
    }

    void release() { checkCall!(clReleaseCommandQueue)(id); }

    void flush() { clFlush(id); }

    // TODO info
}
