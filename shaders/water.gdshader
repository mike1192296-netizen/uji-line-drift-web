shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float waves=(sin(wp.x*0.7+wp.z*1.5+TIME*0.7)+sin(wp.z*2.3+wp.x*0.13-TIME*0.5))*0.5;
 float ripple=sin(wp.x*12.0+wp.z*7.0+TIME*1.4)*0.008;
 ALBEDO=mix(vec3(0.025,0.13,0.115),vec3(0.075,0.25,0.22),waves*0.5+0.5)+ripple;
 ROUGHNESS=0.45; METALLIC=0.0; SPECULAR=0.2;
 NORMAL=normalize(NORMAL+vec3(waves*0.07,0.0,ripple));
}
