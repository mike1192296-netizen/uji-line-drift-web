shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.12,0.23,0.07,1.0);
varying vec3 wp;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
void vertex(){VERTEX += NORMAL*(sin(VERTEX.x*9.0+VERTEX.y*5.0)*sin(VERTEX.z*8.0)*0.15);wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float n=hash(floor(wp*30.0));
 float edge=abs(dot(normalize(NORMAL),normalize(VIEW)));
 if(edge<0.26 && n<0.4){discard;}
 ALBEDO=base_color.rgb*(0.65+n*0.40);
 ROUGHNESS=0.95;
 BACKLIGHT=vec3(0.07,0.09,0.015);
}
