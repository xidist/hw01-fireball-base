import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  red: 255,
  green: 0,
  blue: 0,
  bias: 0.5,
  gain: 0.5,
  frequency: 5,
  octaves: 8,
  'Reset': reset,
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let prevRed: number = 20;
let prevGreen: number = 20;
let prevBlue: number = 20;
let prevBias: number = 0.5;
let prevGain: number = 0.5;
let prevFrequency: number = 5;
let prevOctaves: number = 8;

let check: number = 0;

let time = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function reset(){
  check = 0;
  controls.octaves = 8;
  controls.bias = 0.5;
  controls.gain = 0.5;
  prevOctaves = 8;
  prevBias = 0.5;
  prevGain = 0.5;
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'red', 0, 255).step(10);
  gui.add(controls, 'green', 0, 255).step(10);
  gui.add(controls, 'blue', 0, 255).step(10);
  gui.add(controls, 'bias',0, 1);
  gui.add(controls, 'gain',0, 1);
  //gui.add(controls, 'frequency', 0, 1);
  gui.add(controls, 'frequency', 1, 10).step(1);
  gui.add(controls, 'octaves', 2, 10).step(1);
  gui.add(controls, 'Reset');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);
  const fireball = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);
  
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    //initialize octaves, bias and gain
    if(check !=1){
      fireball.setOctaves(8);
      fireball.setBias(0.5);
      fireball.setGain(0.5);
      check = 1;
    }
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    if(controls.red != prevRed)
    {
      prevRed = controls.red;
      fireball.setGeometryColor(vec4.fromValues(controls.red/255., controls.green/255., controls.blue/255., 1));
    }
    if(controls.green != prevGreen)
    {
      prevGreen = controls.green;
      fireball.setGeometryColor(vec4.fromValues(controls.red/255., controls.green/255., controls.blue/255., 1));
    }
    if(controls.blue != prevBlue)
    {
      prevBlue = controls.blue;
      fireball.setGeometryColor(vec4.fromValues(controls.red/255., controls.green/255., controls.blue/255., 1));
    }
    if(controls.bias != prevBias)
    {
      prevBias = controls.bias;
      fireball.setBias(controls.bias);
    }
    if(controls.gain != prevGain)
    {
      prevGain = controls.gain;
      fireball.setGain(controls.gain);
    }
    if(controls.frequency != prevFrequency)
    {
      prevFrequency = controls.frequency;
      fireball.setFreq(controls.frequency);
    }
    if(controls.octaves != prevOctaves)
    {
      prevOctaves = controls.octaves;
      fireball.setOctaves(controls.octaves);
    }
    
    renderer.render(camera, fireball, [icosphere], time);
    time++;
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  tick();
}

main();
