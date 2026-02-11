void mainImage(out vec4 O, in vec2 C)
{
    vec3 color = texture(iChannel0, C / iResolution.xy).rgb;
    color = mix(
        12.92 * color,
        pow(1.055 * color, vec3(1.0 / 2.4)) - 0.055,
        step(0.0031308, color)
    );
    O = vec4(
        clamp(
            color + (1.0 / 128.0) * texelFetch(iChannel1, (ivec2(C) + iFrame * 31) % 1024, 0).rgb,
            0.0,
            1.0
        ),
        1.0
    );
}
