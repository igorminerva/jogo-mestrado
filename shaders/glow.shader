shader_type canvas_item

void fragment() {
    COLOR = texture(TEXTURE, UV);
    COLOR.rgb += vec3(0.15, 0.08, 0.08) * COLOR.a;
}
