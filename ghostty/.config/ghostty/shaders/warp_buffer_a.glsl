const float threshold = 0.15;
const float effect_strength = 0.2;

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float map(vec2 uv, float t)
{
    float c = cos(t), s = sin(t);
    mat2 R = mat2(c, s, -s, c);

    vec2 a = R * vec2(-2.0, 0.0);
    vec2 b = R * vec2(2.0, 0.0) - a;
    vec2 p = uv - a;

    float sdf = mix(
        length(clamp(dot(p, b) / dot(b, b), 0.0, 1.0) * b - p),
        length(clamp(round(dot(p, b) / dot(b, b) * 30.0) / 30.0, 0.0, 1.0) * b - p),
        0.5 + 0.5 * tanh(10.0 * sin(iTime * 0.1))
    );
    return sdf;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec3 color = vec3(0.0);

    if (length(uv) > 1.0) uv /= 1e-7 + dot(uv, uv);
    vec2 tex_uv = uv;

    const float PI = 3.14159265;
    float angle = 2.0 * PI * 0.01 * iTime;
    float c = cos(angle), s = sin(angle);
    mat2 R = mat2(c, s, -s, c);

    tex_uv = sqrt(tex_uv * tex_uv + 0.0005);
    tex_uv += 0.1 + cos(iTime * 0.33) * 0.05;
    tex_uv = asin(sin(tex_uv));
    tex_uv /= 0.001 + dot(tex_uv, tex_uv);
    tex_uv *= 1.05 + sin(iTime * 0.1) * 0.05;
    tex_uv *= R;

    for (float j = 0.01; j < 1.0; j += j) tex_uv += cos(tex_uv.yx * j) / j * 0.005;

    tex_uv = (tex_uv * iResolution.y + iResolution.xy) * 0.5 / iResolution.xy;

    vec2 uv2 = 2.0 * (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float speed = 2.0;
    float t = iTime * speed - mix(log2(dot(uv2, uv2)), dot(uv2, uv2), 0.5 + 0.5 * tanh(4.0 * sin(iTime * 0.25)));
    float sdf2 = map(uv2, t);
    vec3 col = vec3(0.0);

    float alpha = 0.0;
    for (float i = 0.01; i < 1.024; i += i)
    {
        t -= sdf2 * i;
        sdf2 = map(uv2, t);
        float a = 0.01 / (0.001 + sdf2);
        alpha += a;
        col += (0.5 + 0.5 * cos(t * 0.25 + vec3(3.0, 2.0, 1.0))) * a;
    }

    alpha = 1.0 - exp2(-alpha);
    color += col * exp(0.5 - length(uv));
    color += texture(iChannel0, tex_uv).rgb * smoothstep(0.0, 1.0, 1.0 - alpha) * 0.98;

    color *= pow(abs(color), vec3(0.75));
    color = sqrt(tanh(color * color));

    vec2 texCoord = fragCoord.xy / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, texCoord);
    float mask = 1.0 - step(threshold, luminance(terminalColor.rgb));
    vec3 blendedColor = mix(terminalColor.rgb, color, mask * effect_strength);

    fragColor = vec4(blendedColor, terminalColor.a);
}
