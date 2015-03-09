module camera;

import std.math;
import des.math.linear;
import des.space;

import des.app.event;
import des.util.logsys;

class MouseControlCamera : SimpleCamera
{
protected:

    vec3 orb;
    vec2 rot;

    float rotate_coef = 80.0f;
    float offset_coef = 50.0f;
    float y_angle_limit = PI_2 - 0.01;

    bool modkey = false;

public:

    this( vec3 initial=vec3(0,10,2) )
    {
        super();
        orb = initial;
        target = vec3(0);
        up = vec3(0,0,1);
        near = 0.1;
        updatePos();
    }

    void mouseReaction( in MouseEvent ev )
    {
        if( ev.type == MouseEvent.Type.WHEEL )
        {
            if( modkey ) zoom( ev.whe.y );
            else moveFront( -ev.whe.y * 0.1 );
        }

        if( ev.type == ev.Type.MOTION )
        {
            if( ev.isPressed( ev.Button.LEFT ) )
            {
                auto frel = vec2( ev.rel ) * vec2(-1,1);
                auto angle = frel / rotate_coef;
                addRotate( angle );
            }
            if( ev.isPressed( ev.Button.MIDDLE ) )
            {
                auto frel = vec2( ev.rel ) * vec2(-1,1);
                auto offset = frel / offset_coef * sqrt( orb.len );
                moveCenter( offset );
            }
        }
    }

    void keyReaction( in KeyboardEvent ke )
    {
        if( ke.scan == ke.Scan.P && ke.pressed )
        {
            if( isPerspective ) setOrtho();
            else setPerspective();
        }

        if( ke.scan == ke.Scan.LSHIFT ) modkey = ke.pressed;
    }

protected:

    void zoom( int z )
    {
        float k = 1.05;
        if( z > 0 )
        {
            scale = scale * k;
            fov = fov / k;
        }
        else
        {
            scale = scale / k;
            fov = fov * k;
        }

    }

    void moveFront( float dist )
    {
        orb += orb * dist;
        if( orb.len2 < 1 ) orb = orb.e;
        updatePos();
    }

    void addRotate( in vec2 angle )
    {
        rot = normRotate( rot + angle );
        orb = vec3( cos(rot.x) * cos(rot.y),
                    sin(rot.x) * cos(rot.y),
                    sin(rot.y) ) * orb.len;
        updatePos();
    }

    void moveCenter( in vec2 offset )
    {
        auto lo = (look_tr.matrix * vec4(offset,0,0)).xyz;
        look_tr.target += lo;
        updatePos();
    }

    void updatePos() { pos = orb + target; }

    vec2 normRotate( in vec2 r )
    {
        vec2 ret = r;
        if( ret.y > y_angle_limit ) ret.y = y_angle_limit;
        if( ret.y < -y_angle_limit ) ret.y = -y_angle_limit;
        return ret;
    }
}
