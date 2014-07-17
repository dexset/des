module descl.kernel;

import std.string;
import std.traits;

import descl.base;
import descl.event;
import descl.memory;
import descl.commandqueue;
import descl.program;

class CLKernel : CLReference
{
    package cl_kernel id;

    this( CLProgram program, string name )
    {
        int retcode;
        id = clCreateKernel( program.id, name.toStringz, &retcode );
        checkError( retcode, "clCreateKernel" );
    }

    void setArgs(Args...)( Args args ) { _setArgs(0,args); }

    void exec( CLCommandQueue command_queue, uint dim, size_t[] global_work_offset,
            size_t[] global_work_size, size_t[] local_work_size,
            CLEvent[] wait_list=[], CLEvent event=null )
    in
    {
        assert( global_work_offset.length == dim );
        assert( global_work_size.length == dim );
        assert( local_work_size.length == dim );
    }
    body
    {
        checkCall!(clEnqueueNDRangeKernel)( command_queue.id,
                this.id, dim,
                global_work_offset.ptr,
                global_work_size.ptr,
                local_work_size.ptr,
                cast(cl_uint)wait_list.length, 
                amap!(a=>a.id)(wait_list).ptr,
                (event is null ? null : &(event.id)) );
    }

    void release() { checkCall!(clReleaseKernel)(id); }

    private void _setArgs(Args...)( uint index, Args args )
    {
        static if( args.length > 1 )
        {
            _setArgs(index,args[0]);
            _setArgs(index+1,args[1 .. $]);
        }
        else
        {
            alias Args[0] Arg;
            auto arg = args[0];

            void *value;
            size_t size;

            static if( is( Arg : CLMemory ) )
            {
                auto aid = (cast(CLMemory)arg).id;
                value = &aid;
                size = aid.sizeof;
            }
            else static if( !hasIndirections!Arg )
            {
                value = &arg;
                size = arg.sizeof;
            }
            else static assert( 0, format( "type %s couldn't be "~
                        "set as kernel argument", typeid(Arg) ) );

            clSetKernelArg( id, index, size, value );
            debug(printkernelargs)
            {
                import std.stdio;
                stderr.writefln( "set '%s' arg #%d: %s %s", 
                        Arg.stringof, index, size, value );
            }
        }
    }
}
