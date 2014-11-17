import des.app;
import des.gl;

import des.math.linear;

import window;

void main()
{
    GLApp app;

    app = new GLApp;
    app.addWindow({ return new MainWindow; });

    app.run();
}
