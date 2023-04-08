float remap(float value, float from1, float to1, float from2, float to2) {
    return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float remap_clamped(float value, float from1, float to1, float from2, float to2) {
	value = clamp(value, from1, to1);
	
    return remap(value, from1, to1, from2, to2);
}

float compare(float value, float ref, float width) {
	return float(abs(value - ref) <= width/2.);
}

float smooth_compare(float value, float ref, float width, float smoothness) {
	if (smoothness == 1.) {
		return compare(value, ref, width);
	}
	
	float h_width = width / 2.;
	float v = abs(value - ref);
	float x = clamp(smoothness, 0., 1.) * h_width;
	
	if (v <= x) {
		return 1.;
	}
	else if (v > h_width) {
		return 0.;
	}
	else {
		return remap_clamped(v, x, h_width, 1., 0.);
	}
}