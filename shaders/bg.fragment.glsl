#define distortion 0.08

//"in" attributes from our vertex shader
varying vec4 v_color;
varying vec2 v_texCoords;

uniform sampler2D u_texture;
uniform vec4 high;
uniform vec4 low;

uniform float contrast;
uniform int enableVignette;

uniform vec2 u_resolution;

const float outerRadius = .75, innerRadius = .25, intensity = .35;

uniform float iGlobalTime;

//CRT effects
uniform int enableCRT;

vec2 CRTCurveUV( vec2 uv )
{
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs( uv.yx ) / vec2( 6.0, 4.0 );
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

vec2 radialDistortion(vec2 coord) {
  vec2 cc = coord - vec2(0.5);
  float dist = dot(cc, cc) * distortion;
  return coord + cc * (1.0 - dist) * dist;
}

vec4 DrawVignette( vec4 color, vec2 uv )
{    
    float vignette = uv.x * uv.y * ( 1.0 - uv.x ) * ( 1.0 - uv.y );
    vignette = clamp( pow( 16.0 * vignette, 0.3 ), 0.0, 1.0 );
    color.rgb *= vignette;
    return color;
}

vec4 DrawScanline( vec4 color, vec2 uv )
{
    float scanline 	= clamp( 0.95 + 0.05 * cos( 3.14 * ( uv.y + 0.008 * iGlobalTime ) * 240.0 * 1.0 ), 0.0, 1.0 );
    float grille 	= 0.85 + 0.15 * clamp( 1.5 * cos( 3.14 * uv.x * 640.0 * 1.0 ), 0.0, 1.0 );    
    color.rgb *= scanline * grille * 1.2;
    return color;
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec4 DrawGame( vec4 color, vec2 coord) {
	if (any(greaterThan(color.rgb, vec3(0.0))))
    {
        vec3 c = rgb2hsv(color.rgb);
        vec3 m = mix(low.rgb, high.rgb, smoothstep(0.0, 0.5, c.z * contrast));
        return vec4(m, color.a);
    }
    else
    {  
        vec3 h = mix(low.rgb, high.rgb, smoothstep(0.5, 1.0, contrast));
        return vec4(h, 1.0);
    }
}

void main(void) {

	vec4 color;
    if (enableCRT == 1) {
    	vec2 uv = radialDistortion(v_texCoords);
	    vec4 texCol = texture(u_texture, uv);
	    vec2 coord = gl_FragCoord.xy / u_resolution.xy;
	    // CRT effects (curvature, vignette, scanlines and CRT grille)
	    if ( uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 )
	    {
	        color = vec4( 0.0, 0.0, 0.0, 1.0 );
	    } 
	    else {
			color = DrawGame(texCol, gl_FragCoord.xy);
	        color = DrawVignette( color, uv );
		    color = DrawScanline( color, uv );
	    }
    } else if (enableVignette == 1) {
		vec4 texCol = texture2D(u_texture, v_texCoords);
    	vec2 uv    = gl_FragCoord.xy / u_resolution.xy;
		// CRT effects (curvature, vignette, scanlines and CRT grille)
	    if ( uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 )
	    {
	        color = vec4( 0.0, 0.0, 0.0, 1.0 );
	    } else {
	    	color = DrawGame(texCol, gl_FragCoord.xy);
		    color = DrawVignette( color, uv );
	    }
    } else {
    	vec4 texCol = texture2D(u_texture, v_texCoords);
    	color = DrawGame(texCol, gl_FragCoord.xy);
    }
    
    gl_FragColor = color;
    
}
