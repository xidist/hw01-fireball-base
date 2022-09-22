#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;  

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

//from https://www.shadertoy.com/view/XsXfRH
float hash(vec3 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec3(0.71,0.113,0.419));
    return -1.0+2.0*fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}


// return value noise (in x) and its derivatives (in yzw)
vec4 noised(vec3 x )
{
    vec3 i = floor(x);
    vec3 w = fract(x);

    // quintic interpolation
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);   
    
    float a = hash(i+vec3(0.0,0.0,0.0));
    float b = hash(i+vec3(1.0,0.0,0.0));
    float c = hash(i+vec3(0.0,1.0,0.0));
    float d = hash(i+vec3(1.0,1.0,0.0));
    float e = hash(i+vec3(0.0,0.0,1.0));
	float f = hash(i+vec3(1.0,0.0,1.0));
    float g = hash(i+vec3(0.0,1.0,1.0));
    float h = hash(i+vec3(1.0,1.0,1.0));
	
    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z, 
                 du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                            k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                            k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );
}

#define OCTAVES 9
float fbm (vec3 v) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;

    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * (1.1 - abs(noised(v).x))*(1.1 - abs(noised(v).x))*noised(vec3(0.4*fs_Col)).x;
        v *= 2.;
        amplitude *= .5;
    }
    return value;
}


float fbm2 (vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < OCTAVES; ++i) {
        vec4 _noised = noised(vec3(_st, 1.));
        v += a * fbm(vec3(_noised));
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

vec3 random3( vec3 p ) {
  return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                        dot(p,vec3(269.5, 183.3, 765.54)),
                        dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

void main()
{
    
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;
        diffuseColor += fbm(vec3(fs_Pos));
        diffuseColor += 0.3*fbm(vec3(fs_Pos)); //stacking fbm noise
        vec4 _noised = noised(vec3(u_Color));
        vec3 derivs = vec3(_noised.y, _noised.z, _noised.w);
        diffuseColor += 0.35*fbm(vec3(derivs));
        diffuseColor -= 0.15*fbm(vec3(derivs));

        //static noise
        vec3 staticNoise = vec3(1.) - random3(fs_Col.xyz);
        vec3 dc = vec3(diffuseColor);
        dc += mix(dc, staticNoise, smoothstep(vec3(0.8), vec3(1.2), dc)) *  0.5;
        diffuseColor = vec4(dc, 1.);

        // //complimentary color
        // vec4 comp = vec4(1.) - diffuseColor;
        // comp += fbm2(vec2(fs_Pos.x, fs_Pos.y));
        // diffuseColor +\
        //COLOR ANIM
    //complimentary color
        vec4 comp = vec4(1.) - diffuseColor;
        comp += 0.7*fbm2(vec2(fs_Pos.x, fs_Pos.y))*0.3*fbm(vec3(fs_Pos));
        //vs_Col = comp;
       // fs_Col = vs_Col;
       diffuseColor += 0.3*comp;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0., 1.);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);

}
