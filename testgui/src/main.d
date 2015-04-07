import des.gui;
import mwidget;

void main()
{
    auto ctx = new DiSDLGLContext;
    auto wid = new MainWidget( ctx );

    while( ctx.isRunning )
        ctx.step();

    wid.destroy();
    ctx.destroy();
}
