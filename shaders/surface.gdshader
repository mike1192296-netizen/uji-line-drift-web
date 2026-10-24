shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.25,0.3,0.2,1.0);
uniform int surface_kind = 0;
varying vec3 wp;
varying vec3 wn;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float fine=noise(wp.xz*85.0); float grain=noise(wp.xz*5.0); float broad=noise(wp.xz*0.13);
 vec3 col=base_color.rgb;
 if(surface_kind==0){
  // dry asphalt aggregate, broad repairs and narrow dark seams
  col*=0.78+fine*0.40+grain*0.12;
  float seam=smoothstep(0.004,0.015,abs(sin(wp.x*0.7+noise(wp.xz*0.4)*2.2)));
  col*=mix(0.82,1.0,seam);
  col*=mix(0.90,1.04,smoothstep(0.25,0.65,broad));
  ROUGHNESS=0.94;
 }else if(surface_kind==1){
  float rock=clamp((1.0-abs(wn.y))*1.9,0.0,1.0);
  col=mix(col,vec3(0.25,0.24,0.20),rock*0.7);
  col*=0.55+grain*0.45+broad*0.4+fine*0.10;
  ROUGHNESS=1.0;
 }else if(surface_kind==2){
  col*=0.72+grain*0.25+fine*0.15;
  float row=step(0.94,fract(wp.y*1.5));
  col*=1.0-row*0.26;
  ROUGHNESS=0.95;
 }else{
  col*=0.65+noise(vec2(wp.x+wp.z,wp.y)*vec2(18,1.5))*0.6;
  ROUGHNESS=1.0;
 }
 ALBEDO=col;
}
