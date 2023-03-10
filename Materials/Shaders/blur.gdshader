shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float lod: hint_range(0.0, 5) = 0.0;
// amt of sampled directions
uniform int directions: hint_range(1, 64) = 16;
// amt of pixels sampled along a given direction
uniform int quality: hint_range(1, 10) = 3;
// max distance from ref. pixel
uniform float radius: hint_range(0.0, 30.0, 0.1) = 8.;

vec4 blur(sampler2D text, vec2 resolution, vec2 uv, int Directions, int Quality, float Size) {   
	vec2 Radius = Size/resolution.xy;

	// Pixel colour
	vec4 Color = texture(text, uv);

	float q = 1. / float(Quality);
	// Blur calculations
	for( float d=0.0; d<TAU; d+=TAU/float(Directions)) {
		for(float i=q; i<=1.0; i+=q) {
			Color += texture( text, uv+vec2(cos(d),sin(d))*Radius*i);
		}
	}

	Color /= float(Quality * Directions);
	return Color;
}

void fragment(){
	vec2 res = 1. / SCREEN_PIXEL_SIZE;
	vec4 color = blur(SCREEN_TEXTURE, res, SCREEN_UV, directions, quality, radius);
	COLOR = color;
}