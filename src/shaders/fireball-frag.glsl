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
uniform float u_Time;
uniform float u_Gain;
uniform float u_Bias;
uniform float u_Freq;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos; 

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

//beachball shading
vec3 beachball_shading(vec3 n){
    float norm_length_reciprocal = ((1.f)/length(n));
    n = norm_length_reciprocal * vec3(n);
    //n = clamp(n, 0.f, 1.f); 
    n = clamp(n, 0.f, 0.5); 
    float num_colors = 255.f;
    vec3 abc = floor(vec3(n * num_colors));
    vec3 ret = vec3(num_colors); // initially all white
    ret = floor(ret);

    for (int i = 0; i < 3; i ++){
        //(0,0,0) <= norm scaled <= (255,255,255)
        //(a,b) a,b in set:[0,1]
        //a = 1 if first greater than second, 0 otherwise
        //b = 1 if equal, 0 otherwise
        if (abc[i] < 256.f ){
            if (abc[i] > -1.f){
                ret[i] = abc[i];
            }        
        }
    }

    return ret;
}

//normal shading
vec3 normal_shading(vec3 n){
    //color the negative coords in the back too!:
    vec3 _n = vec3(n);
    for (int i = 0; i < 3; i++){
        if(_n[i] < 0.f){
            _n[i] = abs(_n[i]);
        }
    }
    n = _n; // now the negative coords are flipped to pos
    float norm_length_reciprocal = ((1.f)/length(n));
    vec3 norm = norm_length_reciprocal * vec3(n);
    norm = clamp(n, 0.f, 1.f);
    float num_colors = 255.f;
    vec3 abc = vec3(norm);
    vec3 ret = vec3(num_colors); // initially all white
    ret = floor(ret);

    for (int i = 0; i < 3; i ++){
        //(0,0,0) <= norm scaled <= (255,255,255)
        //(a,b) a,b in set:[0,1]
        //a = 1 if first greater than second, 0 otherwise
        //b = 1 if equal, 0 otherwise
        if (abc[i] < 1.1 ){
            if (abc[i] > -0.1f){
                ret[i] = abc[i];
            }        
        }
    }

    return ret;
}

float ease_in_quadratic(float t){
    t = fract(t);
    return t*t;
}

float ease_in_out_quadratic(float t){
    t = fract(t);
    if (t < 0.5) {
        return ease_in_quadratic(t*2.0) / 2.0;
    } else {
        return 1.0 - (ease_in_quadratic( ((1.0 - t) * 2.0) / 2.0) );
    }
}


//cosine pallate
// t: time [u_Time]
// a: vertical shift
// b: amplitude
// c: period --- time to repeat
// d: phase shift left
vec3 palette(float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*(t+d)) );
}

//now attempting hypertexture

float _mod(float x, float y) {
    return x - y * float(floor(x/y));
}

//bias and gain functions lifted from http://demofox.org/biasgain.html
float getBias()
{
    float bias = u_Bias;
    float time = u_Time;
  return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float getBias(float time, float bias)
{
  return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float getGain()
{
    float gain = u_Gain;
    float time = mod(u_Time, 20.f);
  if(time < 0.5)
    return getBias(time * 2.0,gain)/2.0;
  else
    return getBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}


void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.6; //originally 0.2

        //lambert shading:s
        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        //define a cosine pallate
        vec3 a = vec3(0.5, 0.5, 0.5	);
        vec3 b = vec3(0.5, 0.5, 0.5	);
        vec3 c = vec3(1.0, 1.0, 1.0);
        vec3 d = vec3(0.00, 0.33, 0.67);
        float sint = abs(sin(u_Time*0.01)); //[0,1]
        vec3 cosine_pallate_color = palette(sint, a, b, c, d);
        vec3 abc_1 = cosine_pallate_color;
        vec3 abc_2 = normal_shading(vec3(fs_Nor));
        
        vec3 e0 = min(abc_1, abc_2);
        vec3 e1 = max(abc_1, abc_2);
        vec3 diff = e1 - e0; //space to add to base e0 in each dir (x,y,z) for valid hermite interp
        //we want to mix with time

        vec3 _x = smoothstep(vec3(e0), vec3(e1), vec3(e0) + vec3(diff)*getBias()*ease_in_out_quadratic(sint));
        vec3 abc = mix(e0, e1, _x);

        diffuseColor.xyz = abc;
        diffuseColor[1] *= 0.4;
        diffuseColor[2] *= 0.2;
        
        diffuseTerm = clamp(diffuseTerm, 0., 1.);   //avoid negative lighting
        
        float alpha = 1.;

        if(fs_Col[3] == 0.5){
            diffuseColor = vec4(0., 0., 1., 1.);
        }


        out_Col = vec4(diffuseColor.rgb*lightIntensity, 0.7);
        
}