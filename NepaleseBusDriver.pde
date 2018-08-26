import ddf.minim.ugens.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import processing.video.*;

Capture video;
int vidW = 160;
int vidH = 120;

Minim       context;
AudioPlayer player;
AudioOutput       out;
Sampler           sampler;
EnvelopeFollower envFollow;
FFT         fft;
PImage img; 
int stage;
float brightness; 
int fftSize;
float dB;
boolean videoEnabled;

// events on the time line of the audio track seconds:
// 0 - 30 fade in, 30 - 52 song1 runnig, 52 - change of tonation in song1
// 110 - song1 finishing, 117.5 - song2 comes in, 142  - change1 in song2
// 162 - change2 in song2, 180 - change3 in song2, 222 chage4 in song2 (solo), 252 - end of the whole track
float[] timeLine = {0, 30, 52, 110, 117.5, 142, 192, 162, 180, 222, 252};
BeatDetect beat;

void setup()
{
  stage = 0;
  brightness = 0;
  videoEnabled = false;

  size(800, 450, P3D);
  imageMode(CENTER);
  video = new Capture(this, vidW, vidH); 
  video.start();

  context = new Minim(this);       
  out = context.getLineOut(); 
  frameRate(60);

  // create sampler
  sampler = new Sampler("VOICE224_Pokhara_City_Bus_Music.mp3", 1, context);

  // patch wave to the output
  sampler.patch( out );

  // create envelope follower
  envFollow = new EnvelopeFollower( 0.001, // attack time in seconds
    0.1, // release time in seconds 
    512 // size of buffer to analyze 
    );
  Sink sink = new Sink();
  sampler.patch( envFollow ).patch( sink ).patch( out );

  // trigger the sampler
  sampler.trigger();

  // create an FFT object that has a time-domain buffer
  fft = new FFT( out.bufferSize(), 48000 );
  fft.logAverages( 25, 32 ); 

  beat = new BeatDetect();
}

void draw()
{
  if (video.available()) {
    video.read();
    video.loadPixels();
  }

  //****************************************************************
  // calculate the envelope follower in decibels
  float eF = envFollow.getLastValues()[0];
  dB = 20 * log10(eF);

  // perform a forward FFT on the samples of the out mix buffer
  fft.forward( out.mix );
  fftSize =  fft.avgSize(); // we store number of bins in the int variable to simplify the code inside the loop

  // perform the beat detection - apparently it is not very accurate in case of our field recording
  // which contains asian music but we do get some form of reading / peak indication
  beat.detect(out.mix);

  if ( beat.isOnset() ) background(0);  // we erase the background on the beat

  calculateStage();
  println(stage);
  if (stage == 0)
  {
    brightness = constrain(map(millis(), -10000, 30000, 0, 1.0f), 0.0f, 1.0f);
    println("brightness " + brightness);
  } else if (stage == 1)
  {
  } else if (stage == 2)
  {
  } else if (stage == 3)
  {
  } else if (stage == 4)
  {
    videoEnabled = true;
  } else if (stage == 5)
  {
  } else if (stage == 6)
  {
  } else if (stage == 7)
  {
  } else if (stage == 8)
  {
  }

  // draw elements of our visualisation
  drawTheEFsphere(dB);
  pushMatrix();
  cubes();

  popMatrix();
  quadStrip();

  if (videoEnabled)
  {
    drawVideo();
  }
}

void drawVideo()
{
  pushMatrix();
  int bin = 0;
  // we iterate through the pixels of the video 
  for (int xx=0; xx<vidW; xx++)
  {
    for (int yy=0; yy<vidH; yy++)
    {
      // while we iterate through the pixels of the video
      // we increment the bin number 
      bin = (bin + 1) % fftSize;
      // Extract the red green and blue values from the video pixels
      int pixelColor = video.pixels[xx + yy * vidW];
      // Faster method of calculating r, g, b than red(), green(), blue() 
      // Reference: Ben Fry AsciiVideo.pde sketch from the Video library examples
      //
      int r = (pixelColor >> 16) & 0xff;
      int g = (pixelColor >> 8) & 0xff;
      int b = pixelColor & 0xff;

      // we want our video source to be averaged to monochrome
      float avColour = (r + g + b) / 3;

      // we calculate a variable called s which equals current bin mangitude + 1  so it
      // does reading does not start from 0
      float s = 1 + fft.getAvg(bin);
      // we do a subjectively chosen calculation to establish colour of rectangle
      // our s variable (based on the bin) is taken into account
      fill((avColour / s) * 0.4, (avColour + s) * 0.4, avColour * s * 0.2);

      // we take the magnitude of a bin into account to draw a rectangle of size it maps to
      // the rectangles are modified pixels of the live video
      // we also take the envelope follower into account - it is mapped to the vertical
      // position of the video
      rect(xx - 400, yy - 400 + map(dB, -120, 0, 0, 100), s, s);
    }
  }

  popMatrix();
}

void calculateStage()
{
  float time = millis() / 1000; 
  int resultingStage  = 0;

  for (int i = stage; i < timeLine.length - 1; i++)
  {
    if (time >= timeLine[i] && time < timeLine[i+1])
    {
      resultingStage = i;
    }
  }
  if (resultingStage >= stage)
  {
    stage = resultingStage;
  }
}

void quadStrip()
{
  translate(width/2, height/2);
  fill(90 * brightness, 40 * brightness, 30 * brightness);
  noStroke();
  beginShape(QUAD_STRIP);
  for (int i = 0; i < fftSize; i++)
  {
    // how we calculate vertices of our quad strip is we take subsequent bins for x, y and z and we use modulo so that we
    // don't run out of bins
    vertex(map(fft.getAvg(i%fftSize), 0, 200, -255, 255), map(fft.getAvg((i + 1)%fftSize), 0, 200, -255, 255), map(fft.getAvg((i + 2)%fftSize), 0, 200, -255, 255));
  }
  endShape();
}

void drawTheEFsphere(float dB)
{
  //****************************************************************
  // SPHERE CONTROLLED BY THE ENVELOPE FOLLOWER
  println(dB);
  fill(223 * brightness, 37 * brightness, 1 * brightness);
  noStroke();
  lights();
  pushMatrix();
  translate(width/2, height/2);

  rotateX(frameCount * 0.01);
  rotateZ(frameCount * 0.015);

  // the rotation calculated from dB looks little less agressive
  rotateY(map(dB, -120, 0, 0, TWO_PI * 0.5));

  // detail of sphere changes with respect to envelope follower
  sphereDetail( (int)  map(dB, -100, 0, 3, 5), 
    12 );

  // size of the sphere changes with time at the beginning of the track 
  float sphereSize = constrain((-10 + frameCount * 0.09), 10, 120);
  sphere(sphereSize);
  popMatrix();
}

void cubes()
{
  // CUBES CONTROLLED BY THE FFT
  //****************************************************************
  int colWidth = width/fft.avgSize();
  for (int i = 0; i < fft.avgSize(); i++)
  {
    // print(fft.getAvg(i) + " ");
    pushMatrix();
    translate( i * colWidth, height);
    fill(map(fft.getAvg(i), 0, 200, 0, 255) * brightness, 100 * brightness, 100 * brightness);
    box(40, fft.getAvg(i), 40);
    popMatrix();

    rotateX(frameCount * 0.01 * 0.1);
    rotateZ(frameCount * 0.015 * 0.1);
  }
}

float log10 (float x) {
  return (log(x) / log(10));
}