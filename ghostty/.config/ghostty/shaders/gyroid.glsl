// "tm gyroid 2" from https://www.shadertoy.com/view/tXtyW8
// terminal contents luminance threshold to be considered background (0.0 to 1.0)
const float threshold = 0.15;

// blend effect over terminal contents
const bool transparent = false;
const float effect_strength = 0.15;

#define FAR 30.0
#define PI 3.1415

int m = 0;

mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
mat3 lookAt(vec3 dir) {
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 rt = normalize(cross(dir, up));
    return mat3(rt, cross(rt, dir), dir);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float gyroid(vec3 p) { return dot(cos(p), sin(p.zxy)) + 1.0; }

float map(vec3 p) {
    float r = 1e5;
    float d;

    d = gyroid(p);
    if (d < r) { r = d; m = 1; }

    d = gyroid(p - vec3(0.0, 0.0, PI));
    if (d < r) { r = d; m = 2; }

    return r;
}

float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 150; i++) {
        float d = map(ro + rd * t);
        if (abs(d) < 0.001) break;
        t += d;
        if (t > FAR) break;
    }
    return t;
}

float getAO(vec3 p, vec3 sn) {
    float occ = 0.0;
    for (float i = 0.0; i < 4.0; i++) {
        float t = i * 0.08;
        float d = map(p + sn * t);
        occ += t - d;
    }
    return clamp(1.0 - occ, 0.0, 1.0);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.5773, -0.5773) * 0.001;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yyx * map(p + e.yyx) +
        e.yxy * map(p + e.yxy) +
        e.xxx * map(p + e.xxx)
    );
}

vec3 trace(vec3 ro, vec3 rd) {
    vec3 C = vec3(0.0);
    vec3 throughput = vec3(1.0);

    for (int bounce = 0; bounce < 2; bounce++) {
        float d = raymarch(ro, rd);
        if (d > FAR) { break; }

        float fog = 1.0 - exp(-0.008 * d * d);
        C += throughput * fog * vec3(0.0);
        throughput *= 1.0 - fog;

        vec3 p = ro + rd * d;
        vec3 sn = normalize(getNormal(p) + pow(abs(cos(p * 64.0)), vec3(16.0)) * 0.1);

        vec3 lp = vec3(10.0, -10.0, -10.0 + ro.z);
        vec3 ld = normalize(lp - p);
        float diff = max(0.0, 0.5 + 2.0 * dot(sn, ld));
        float diff2 = pow(length(sin(sn * 2.0) * 0.5 + 0.5), 2.0);
        float diff3 = max(0.0, 0.5 + 0.5 * dot(sn, vec2(1.0, 0.0).yyx));

        float spec = max(0.0, dot(reflect(-ld, sn), -rd));
        float fres = 1.0 - max(0.0, dot(-rd, sn));
        vec3 col = vec3(0.0);
        vec3 alb = vec3(0.0);

        col += vec3(0.4, 0.6, 0.9) * diff;
        col += vec3(0.5, 0.1, 0.1) * diff2;
        col += vec3(0.9, 0.1, 0.4) * diff3;
        col += vec3(0.3, 0.25, 0.25) * pow(spec, 4.0) * 8.0;

        float freck = dot(cos(p * 23.0), vec3(1.0));
        if (m == 1) { alb = vec3(0.2, 0.1, 0.9); alb *= max(0.6, step(2.5, freck)); }
        if (m == 2) { alb = vec3(0.6, 0.3, 0.1); alb *= max(0.8, step(-2.5, freck)); }
        col *= alb;

        col *= getAO(p, sn);
        C += throughput * col;

        rd = reflect(rd, sn);
        ro = p + sn * 0.01;
        throughput *= 0.9 * pow(fres, 1.0);
    }
    return C;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) / iResolution.y;
    vec2 mo = (iMouse.xy - iResolution.xy * 0.5) / iResolution.y;

    vec3 ro = vec3(PI / 2.0, 0.0, -iTime * 0.5);
    vec3 rd = normalize(vec3(uv, -0.5));

    if (iMouse.z > 0.0) {
        rd.zy = rot(mo.y * PI) * rd.zy;
        rd.xz = rot(-mo.x * PI) * rd.xz;
    } else {
        rd.xy = rot(sin(iTime * 0.2)) * rd.xy;
        vec3 ta = vec3(cos(iTime * 0.4), sin(iTime * 0.4), 4.0);
        rd = lookAt(normalize(ta)) * rd;
    }

    vec3 col = trace(ro, rd);
    col *= smoothstep(0.0, 1.0, 1.2 - length(uv * 0.9));
    col = pow(col, vec3(0.4545));

    vec2 texCoord = fragCoord.xy / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, texCoord);

    if (transparent) {
        col += terminalColor.rgb;
    }

    float mask = 1.0 - step(threshold, luminance(terminalColor.rgb));
    vec3 blendedColor = mix(terminalColor.rgb, col, mask * effect_strength);
    fragColor = vec4(blendedColor, terminalColor.a);
}
