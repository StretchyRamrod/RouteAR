
#pragma transparent
#pragma body

uniform float speed = 1.0;

float speedR = clamp(speed / 18.0, 0.0, 1.0);
float start = 30.0 + 35.0 * speedR;
float end = 50.0 + 70 * speedR;
float l = length(_surface.position);
float r = l < 5 ? (l - 1.0) / 4.0 : (end - l) / (end - start);
float a = clamp(r, 0.0 , 1.0);

float mask = _surface.diffuse.a;
vec4 clr = vec4(0.3 , 0.4 + 0.6 * mask, 1.0 , 1.0); // _surface.diffuse.rgba;
//clr = vec3(1.0, 1.0, int(_surface.diffuseTexcoord.y) % 2);

_surface.diffuse = float4(clr.rgb, a * (1.0 - mask + 0.5) );
_surface.specular = float4(1, 1, 1, 1);


