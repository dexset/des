## D Extended Set library

Work with 3d graphics, window systems, etc

* `des.app`: SDL wrap for working with windows

    * `base`: `DesWindow` and `DesApp`

    * `event`: events for mouse and keyboard

    * `evproc`: interface `SDLEventProcessor` convert SDL events to application
      events

    * `ftouch`: finger touch event and converter

    * `joystick`: joystick event and converter

* `des.gl`: OpenGL wrap

    * `base`: base concepts wrap

        * `object`: buffers, VAO, and simple usage of them

        * `texture`

        * `shader`: shader and shader program wraps
        
        * `frame`: RBO, FBO

        * `render`: simple usage of FBO

        * `type`: OpenGL types

    * `simple`: simple usage of `base`, model loader, text output

* `des.il`: code for descore image, that has external dependencies

    * `io`: image loading and saving functions

Documentation orient to [harbored-mod](https://github.com/kiith-sa/harbored-mod)

to build doc:
```sh
cd path/to/descore
path/to/harbored-mod/bin/hmod
```
