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
uniform float u_Gain;
uniform float u_Bias;
uniform float u_Freq;
uniform float u_Octaves;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.


//bias and gain functions lifted from http://demofox.org/biasgain.html
float getBias(float time, float bias)
{
  return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float getGain(float time, float gain)
{
  if(time < 0.5)
    return getBias(time * 2.0,gain)/2.0;
  else
    return getBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}

float hash(vec3 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec3(0.71,0.113,0.419));
    return -1.0+2.0*fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float turbulence( vec3 p ) {

  float w = 100.0;
  float t = -.5;

  for (float f = 1.0 ; f <= 10.0 ; f++ ){
    float power = pow( 2.0, f );
    t += abs( hash( vec3( power * p ) ) / power );
  }

  return t;

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

//#define OCTAVES u_Octaves
float fbm (vec3 v) {
    int oct = int(u_Octaves);
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;

    // Loop of octaves
    for (int i = 0; i < oct; i++) {
        value += amplitude * abs(noised(v).x);
        v *= 2.;
        amplitude *= .5;
    }
    return value;
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

float _smoothstep(float edge0, float edge1, float x){
    //scale, bias and saturate x to 0..1 range
    x = clamp((x-edge0)/(edge1-edge0), 0.0, 1.0);
    //eveal polynomial
    return x*x*(3.0-2.0*x);
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec3 normal = vec3(vs_Nor);
    // get a turbulent 3d noise using the normal, normal to high freq
  float noise = 10.0 *  (0.0-0.10 )* turbulence( .5 * normal );
  // get a 3d noise using the position, low frequency
  float b = 5.0 * noised( 0.05 * vec3(vs_Pos)).x;
  // compose both noises
  float displacement = -0.10 * noise + (b* 0.6);

  // move the position along the normal and transform it
  vec3 newPosition = vec3(vs_Pos) + normal * displacement;
  
  newPosition *= fbm(newPosition*0.5);

  float sinc = 0.5*((sin(u_Time * 0.5 * getGain(u_Time, u_Gain))) + 1.0);
  float x1_min = min(sinc*newPosition[0], newPosition[0]);
  float x1_max = max(sinc*newPosition[0], newPosition[0]);
  float x2_min = min(sinc*newPosition[1], newPosition[1]);
  float x2_max = max(sinc*newPosition[1], newPosition[1]);
  float x3_min = min(sinc*newPosition[2], newPosition[2]);
  float x3_max = max(sinc*newPosition[2], newPosition[2]);
  vec3 min_pos = vec3(x1_min, x2_min, x3_min);
  vec3 max_pos = vec3(x1_max, x2_max, x3_max);
  float _time = u_Time*0.02;
  float pposx = _smoothstep(x1_min, x1_max, (sin(_time)+1.0)*0.5);
  float pposy = _smoothstep(x2_min, x2_max, (sin(_time)+1.0)*0.5);
  float pposz = _smoothstep(x3_min, x3_max, (sin(_time)+1.0)*0.5);
  vec3 ppos = 0.3*3.1415*vec3(pposx, pposy, pposz);
    newPosition *= sin(_time)*fract(ppos);
    vec4 modelposition = u_Model * vec4(newPosition, 1.0);
    //vec4 modelposition = u_Model * vec4(ppos, 1.0);


    //vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}