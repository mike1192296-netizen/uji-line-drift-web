shader_type spatial;
render_mode cull_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform int tile = 0;
uniform float metal = 0.2;
uniform float rough = 0.3;
varying vec3 local_pos;
varying vec3 local_normal;
void vertex() { local_pos=VERTEX; local_normal=NORMAL; }
vec3 sample_tile(vec2 uv) {
 vec2 offset=vec2(float(tile%2),float(tile/2))*0.5;
 return texture(atlas,offset+vec2(0.006)+fract(uv)*0.488).rgb;
}
void fragment() {
 vec3 weights=pow(abs(normalize(local_normal)),vec3(6.0));
 weights/=max(weights.x+weights.y+weights.z,0.001);
 float scale=tile==3?7.0:(tile==1?1.8:2.0);
 vec3 p=local_pos*scale;
 vec3 tex=sample_tile(p.zy)*weights.x+sample_tile(p.xz)*weights.y+sample_tile(p.xy)*weights.z;
 if(tile==3) tex=mix(vec3(1.0),tex,0.14);
 ALBEDO=tint.rgb*tex;
 METALLIC=metal;
 ROUGHNESS=rough;
 CLEARCOAT=tile==3?0.8:0.0;
 CLEARCOAT_ROUGHNESS=0.2;
}
