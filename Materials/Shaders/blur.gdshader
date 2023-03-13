shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// amt of sampled directions
uniform int directions: hint_range(1, 64) = 16;
// amt of pixels sampled along a given direction
uniform int quality: hint_range(1, 10) = 3;
// max distance from ref. pixel
uniform float radius: hint_range(0.0, 30.0, 0.1) = 8.;
uniform float alpha: hint_range(0.0, 1.0, 0.1) = 1.;

vec3 blur(sampler2D text, vec2 resolution, vec2 uv, int Directions, int Quality, float Size) {   
	vec2 Radius = Size/resolution.xy;

	// Pixel colour
	vec3 Color = texture(text, uv).rgb;

	float q = 1. / float(Quality);
	// Blur calculations
	for( float d=0.0; d<TAU; d+=TAU/float(Directions)) {
		for(float i=q; i<=1.0; i+=q) {
			Color += texture( text, uv+vec2(cos(d),sin(d))*Radius*i).rgb;
		}
	}

	Color /= float(Quality * Directions);
	return Color;
}

void fragment(){
	COLOR.a = alpha;
	
	if (alpha != 0.0) {
		vec2 res = 1. / SCREEN_PIXEL_SIZE;
		vec3 color = blur(SCREEN_TEXTURE, res, SCREEN_UV, directions, quality, radius);
		COLOR.rgb = color;
	}
}