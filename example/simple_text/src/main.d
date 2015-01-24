import des.app;
import des.gl;

import des.math.linear;

import window;

void main()
{
    auto app = new DesApp;
    app.addWindow({ return new MainWindow; });

    while( app.isRunning ) app.step();
    app.destroy();
}
