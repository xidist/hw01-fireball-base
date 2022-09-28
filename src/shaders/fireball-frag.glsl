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

//checkerboard shading


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


void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.2;

        //lambert shading:s
        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        lightIntensity = 1.f; //flat shading
        // Compute final shaded color
       // out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);


//
// comment below:
//
        // // // normals mapping
        // vec3 norm = vec3(fs_Nor);
        // float norm_length_reciprocal = (1.f/length(norm));
        // norm = norm_length_reciprocal * norm;
        // norm = clamp(norm, 0.f, 1.f);

        // //diffuse color a
        // //let a be the r and x component
        // //normalized a: [0,1]
        // int a = int(norm[0]*255.f);
        // //let n_0 be the the scaled int from n_0: [0,255]
        // float n_0 = norm[0];
        // //make sure the color value max is 255
        // if ( n_0 < 1.1  ){
        //     //make sure the color value min is 0
        //     if (n_0 > -0.1){
        //         diffuseColor[0] = (norm[0]);
        //     }
        // } 
        // //let n_1 be the the scaled int from n_1: [1,255]
        // float n_1 = norm[1];
        // //make sure the color value max is 255
        // if ( n_1 < 1.1  ){
        //     //make sure the color value min is 0
        //     if (n_1 > -0.1){
        //         diffuseColor[1] = (norm[1]);
        //     }
        // } 
        // //let n_2 be the the scaled int from n_2: [2,255]
        // int n_2 = int(norm[2]*255.f);
        // //make sure the color value max is 255
        // if ( n_2 < 256  ){
        //     //make sure the color value min is 1
        //     if (n_2 > -1){
        //         //diffuseColor[2] = (norm[2]);
        //         diffuseColor[2] = (norm[2]);
        //     }
        // } 

        // int b = int(norm[2]);
        // int c = int(norm[2]);
        // vec3 abc = vec3(a, b, c);

      
        

//uncomment for beachball
        // vec3 abc_1 = beachball_shading(vec3(fs_Nor));
        //0.8, 0.5, 0.4		0.2, 0.4, 0.2	2.0, 1.0, 1.0	0.00, 0.25, 0.25
        // vec3 a = vec3(0.8, 0.5, 0.4);
        // vec3 b = vec3(0.2, 0.4, 0.2);
        // vec3 c = vec3(2.0, 1.0, 1.0);
        // vec3 d = vec3(0.00, 0.25, 0.25);
        vec3 a = vec3(0.5, 0.5, 0.5	);
        vec3 b = vec3(0.5, 0.5, 0.5	);
        vec3 c = vec3(1.0, 1.0, 1.0);
        vec3 d = vec3(0.00, 0.33, 0.67);
        float sint = abs(sin(u_Time*0.01)); //[0,1]
        vec3 cosine_pallate_color = palette(sint, a, b, c, d);
        vec3 abc_1 = cosine_pallate_color;
        vec3 abc_2 = normal_shading(vec3(fs_Nor));
        //bool flip = mod(int(u_Time),2);
        
        bool flip = true;
        vec3 abc = vec3(0.0);
        if(sint < 0.0){  ///flip greater for beachball
            abc = abc_1;
        } else {
            abc = abc_2;
        }

        bvec3 gt = greaterThan(abc_1, abc_2);
        vec3 e0 = vec3(0.0);
        vec3 e1 = vec3(1.0);
        for(int i = 0; i < 3; i++){
            if (gt[i]) { //if beachball > normal
                e1[i] = abc_1[i];
                e0[i] = abc_2[i];
            } else {
                e1[i] = abc_2[i];
                e0[i] = abc_1[i];
            }
        }

        vec3 diff = e1 - e0; //space to add to base e0 in each dir (x,y,z) for valid hermite interp
        //we want to mix with time
        vec3 _x = smoothstep(vec3(e0), vec3(e1), vec3(e0) + vec3(diff)*sint);

        abc = mix(e0, e1, _x);

        diffuseColor[0] = abc[0];
        diffuseColor[1] = abc[1];
        diffuseColor[2] = abc[2];

        
        //diffuseColor = vec4(cosine_pallate_color, diffuseColor.w);

        
        diffuseTerm = clamp(diffuseTerm, 0., 1.);   //avoid negative lighting
        out_Col = vec4(diffuseColor.rgb*lightIntensity, 1.f);
        
}