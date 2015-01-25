module camera;

import std.math;

import des.space;
import des.app;

class MCamera : SimpleCamera
{
protected:
    vec3 orb;
    vec2 rot;

    float rotate_coef = 80.0f;
    float offset_coef = 50.0f;
    float y_angle_limit = PI_2 - 0.01;

public:
    this()
    {
        super();
        orb = vec3( 5, 1, 3 );
        look_tr.target = vec3(0,0,0);
        look_tr.up = vec3(0,0,1);
        near = 0.001;
        updatePos();
    }

    void mouseReaction( in MouseEvent ev )
    {
        if( ev.type == MouseEvent.Type.WHEEL )
            moveFront( -ev.whe.y * 0.1 );

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

protected:
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

    void updatePos() { pos = orb + look_tr.target; }

    vec2 normRotate( in vec2 r )
    {
        vec2 ret = r;
        if( ret.y > y_angle_limit ) ret.y = y_angle_limit;
        if( ret.y < -y_angle_limit ) ret.y = -y_angle_limit;
        return ret;
    }
}
