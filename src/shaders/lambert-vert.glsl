#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;             // The array of vertex positions passed to the shader

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.


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
        value += amplitude * abs(noised(v).x);
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


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    
    float ss = 0.;
    float a = 0.;
    float b = 1.;
    float x = 0.3*((sin(u_Time*0.1)*cos(u_Time*0.2))+1.05);
    ss += smoothstep(a,b,x);
    ss *= 0.2;
    vec4 ssv = vec4(ss); //0.2*vec4(ss);
    //vec4 pos = vec4(normalize(vec3(vs_Pos)), 1);
    vec4 pos = vec4(vs_Pos);
    //pos += vec4(noise3(vec3(vs_Pos)), 1.);
    //pos += vec4(0.01*sin(u_Time*0.5), 0.02*cos(u_Time*0.7), 0, 0);
    pos += ssv;
    vec4 n = noised(vec3(pos));
    pos += 0.4*sin(u_Time*0.15)*cos(u_Time*0.1)*n;
    float zMove = fbm(vec3(pos))*(sin(u_Time*0.2));
    pos -= vec4(0., 0., 0.3*zMove, 0.); 
    vec4 floorPos = floor(pos);
    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    //fs_LightVec = -fs_LightVec
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
