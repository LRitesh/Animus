 // Author: Ritesh Lala
// May 6, 2011
// Cellular Automata for Animus @ MAT EoYS 2011

import supercollider.*;
import oscP5.*;

OscP5 oscP5;
Synth synth, synth2;

int w = 1280;  
int h = 1024;
PImage img;
//int w = 640;
//int h = 480;
int maxSize = 2800;
float tempM = 0;

float invWidth, invHeight, aspectRatio, aspectRatio2;

//import fullscreen.*;

//FullScreen fs;

PFont aFont;

// CA Variables
int res, rows, columns;
boolean[][] allStates;  // this 2D array will store the states of all cells in the system at any given time
boolean[][] allStatesTemp;  // temp 2D array to store the states before updating them
ArrayList microbes;     // arraylist to contain all the living cells/microbes to quickly draw them on screen
boolean quorumFlag =  false;  // set this flag when the number of microbes passes a threshold
long timeStamp = 0;  // keeps track of the frameCount when quorum sensing starts
boolean glowFlag = false;
float glowCounter = 0.0;
float inc = TWO_PI/30.0;

// previous mouse positions
float prevX = width/2; 
float prevY = height/2;

// openNI for gesture detection
import SimpleOpenNI.*;

SimpleOpenNI      context;
// NITE
XnVSessionManager sessionManager;
XnVFlowRouter     flowRouter;

PointDrawer       pointDrawer;

// Threading for NITE context updates
SimpleThread contextUpdate;
PVector handPoint;

void setup()
{
  /* start oscP5, listening for incoming messages at port 8475 */
  oscP5 = new OscP5(this,8475);
  // setup screen parameters
  size (w,h);
  invWidth = 1.0f/width;
  invHeight = 1.0f/height;
  aspectRatio = invWidth * height;
  aspectRatio2 = aspectRatio * aspectRatio;

  // setup fonts
  aFont = loadFont("Verdana-12.vlw");
  textFont(aFont, 16);

  // setup CA parameters
  res = 5;
  rows = height/res;
  columns = width/res;
  allStates = new boolean[columns][rows];  // [xIndex][yIndex]
  allStatesTemp = new boolean[columns][rows];  

  // initialize all cells to dead at first
  for (int i = 0; i < columns; i++) {
    for (int j = 0; j < rows; j++) {
      allStates[i][j] = false;
      allStatesTemp[i][j] = false;
    }
  }
//  
//  // init image
//  img = loadImage("sunflower.jpg");
  
  // initialize the arraylist with storage capacity rows*columns
  microbes = new ArrayList(rows*columns);

  background(0);
  smooth();
  println("press'c' to clean up");
//  fs = new FullScreen(this);
  println((rows*columns)/(res));

  // setup NITE context and session manager
  if (context == null) {
    contextSetup();

    pointDrawer = new PointDrawer();
    flowRouter = new XnVFlowRouter();
    flowRouter.SetActive(pointDrawer);

    sessionManager.AddListener(flowRouter);
  }

  contextUpdate = new SimpleThread(5,"a");
  contextUpdate.start();
//  handPoint = new PVector(0.0,0.0);
  handPoint = new PVector(width/2,height/2);
  
      synth = new Synth("sine");
    
    // set initial arguments
    synth.set("amp", 0.5);
    synth.set("freq", 440);
    
    // create synth
    synth.create();
    
    synth2 = new Synth("sine");
    
    // set initial arguments
    synth2.set("amp", 0.5);
    synth2.set("freq", 440);
    
    // create synth
    synth2.create();
}

void draw()
{
  background(0);
  stroke(51,143,188,random(150));
  noFill();
  //  strokeWeight(2);
  //  stroke(random(40,55),143,188,random(150));
  //ellipse(mouseX,mouseY,res,res);
// if(frameCount%5 == 0)
    stateUpdate();
  if (!mousePressed) handMoved();
  
  if (microbes.size() > maxSize)//((columns*rows)/(res/2))) 
  {
    quorumFlag = true;
    if (glowFlag) {
      timeStamp = frameCount;
      glowCounter = 0;
    }
    else {
      glowCounter += inc;
    }
    glowFlag = false;
  }
  else 
  {
    quorumFlag = false;
    glowFlag = true;
  }
  // go through the array list of microbes and mark the dead cells  
  // we could include this in the loop where the living ones are drawn but this makes it possible to 
  // draw the recently dead cells with a different color
  for (int mIndex = microbes.size()-1; mIndex >= 0; mIndex--) {
    Microbe microbe = (Microbe) microbes.get(mIndex);
    if (!(allStates[(int) microbe.pos.x][(int) microbe.pos.y])) microbe.state = false;
  }  

  int numberOfMicrobes = microbes.size();
  // go through the array list of microbes and draw the ones alive remove the ones dead
  for (int mIndex = microbes.size()-1; mIndex >= 0; mIndex--) {
    Microbe microbe = (Microbe) microbes.get(mIndex);
    if (microbe.state) microbe.drawMicrobe();
    else 
    {
      microbe.drawDeadMicrobe(); 
      microbes.remove(mIndex); // this is why the loop starts at the end and decrements till zero!
    }
  }

  //  if(quorumFlag) 
  //    blurScreen();
  if(quorumFlag) {
    synth.set("freq", 250);
    synth2.set("freq", map(sin(glowCounter),-1,1,250,260)); 
  }
  else {
    synth.set("freq", map(numberOfMicrobes,0,maxSize,100,250));
    synth2.set("freq", map(numberOfMicrobes,0,maxSize,100,250));// map(sin(glowCounter),-1,1,440,450)); 
   }
   
  fill(250);
  text(numberOfMicrobes,150,200);
  
  float m = millis() - tempM;
  if(m > 60000 ) {
     for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        allStates[i][j] = false;
        allStatesTemp[i][j] = false;
      }
    }
    microbes.clear();
    background(0,0,0);
    sessionManager.EndSession();
    tempM = millis();
  }
  text((60000-m)/1000,width-200,height-200);
 
}

/*  Update States based on CA Rules  */

void stateUpdate()
{
  int stateRadius = 30; 

  arraycopy(allStates,allStatesTemp);
  // go through all the live cells and apply these rules, check for boundaries
  for(int cIndex = 0; cIndex < columns; cIndex++) {
    for(int rIndex = 0; rIndex < rows; rIndex++) {

      int mNeighbors = 0;
      if(cIndex > 0 && rIndex > 0)               if (allStatesTemp[cIndex-1][rIndex-1]) mNeighbors++;
      if(rIndex > 0)                             if (allStatesTemp[cIndex  ][rIndex-1]) mNeighbors++;
      if(cIndex < columns-1 && rIndex > 0)       if (allStatesTemp[cIndex+1][rIndex-1]) mNeighbors++;
      if(cIndex > 0)                             if (allStatesTemp[cIndex-1][rIndex  ]) mNeighbors++;
      if (allStatesTemp[cIndex  ][rIndex  ]) mNeighbors++;
      if(cIndex < columns-1)                     if (allStatesTemp[cIndex+1][rIndex  ]) mNeighbors++;
      if(cIndex > 0 && rIndex < rows-1)          if (allStatesTemp[cIndex-1][rIndex+1]) mNeighbors++;
      if(rIndex < rows-1)                        if (allStatesTemp[cIndex  ][rIndex+1]) mNeighbors++;
      if(cIndex < columns-1 && rIndex < rows-1)  if (allStatesTemp[cIndex+1][rIndex+1]) mNeighbors++;

      if(cIndex > prevX-stateRadius && cIndex < prevX+stateRadius && rIndex > prevY-stateRadius && rIndex < prevY+stateRadius)
      {
        if(mNeighbors == (int) (sqrt((cIndex-prevX)*(cIndex-prevX) + (rIndex-prevY)*(rIndex-prevY))/(res*1.5))) 
        {
          allStatesTemp[cIndex][rIndex] = true;
          microbes.add(new Microbe(new PVector(cIndex,rIndex), true, 10));
        }
        else
        {
          allStatesTemp[cIndex][rIndex] = false;
        }
      }
      else  // all the cells outside this radius will follow different rules
      {

        // the number of living cells decreases as the function of distance from the mouse position
        //if(mNeighbors == (int) (sqrt((cIndex-prevX)*(cIndex-prevX) + (rIndex-prevY)*(rIndex-prevY))/(res)))
        if(mNeighbors == 3 )
        {
          allStatesTemp[cIndex][rIndex] = true;
          microbes.add(new Microbe(new PVector(cIndex,rIndex), true, 10));
        }
        else
        {
          allStatesTemp[cIndex][rIndex] = false;
        }
      }
    }
  }

  arraycopy(allStatesTemp,allStates);
}

/*  Mouse and Keyboard inputs  */

void mouseMoved()
{
  int radius = 0;
  int posX = (int) map (mouseX, 0, width, 0, columns);
  int posY = (int) map (mouseY, 0, height, 0, rows);
  // mark the state of the cell true if mouseOver'd and not already existing

  for (int xIndex = -radius; xIndex <= radius; xIndex++) {
    for (int yIndex = -radius; yIndex <= radius; yIndex++) {
      if (posX+xIndex > 0 && posX+xIndex < columns && posY+yIndex > 0 && posY+yIndex < rows)
      {
        if(!allStates[posX+xIndex][posY+yIndex])
        { 
          allStates[posX+xIndex][posY+yIndex] = true;    
          // add that cell into the arraylist of microbes (alive and to be drawn)
          microbes.add(new Microbe(new PVector(posX+xIndex, posY+yIndex), true, 10));
        }
      }
    }
  }

  prevX = posX;
  prevY = posY;
}

void keyPressed()
{
  switch(key)
  {
   case 'e':
    // end sessions
    sessionManager.EndSession();
    println("end session");
    break;
  case 'f':  // enter fullscreen
   // fs.enter();
    break;
  case 'q':  // leave fullscreen
  //  fs.leave();
    break;  
  case 'c':  // clear the screen
    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        allStates[i][j] = false;
        allStatesTemp[i][j] = false;
      }
    }
    microbes.clear();
    background(0,0,0);
    break;
  }
}

/*  hand moved routine  */

void handMoved()
{

  //  println (handPoint.x + " " + handPoint.y);
  int radius = 1;
  int posX = (int) map (handPoint.x, 100, context.depthWidth()-100, 0, columns);
  int posY = (int) map (handPoint.y, 0, context.depthHeight(), 0, rows);

  ellipse(posX*res,posY*res,res*2,res*2);
  // mark the state of the cell true if mouseOver'd and not already existing

  for (int xIndex = -radius; xIndex <= radius; xIndex++) {
    for (int yIndex = -radius; yIndex <= radius; yIndex++) {
      if (posX+xIndex > 0 && posX+xIndex < columns && posY+yIndex > 0 && posY+yIndex < rows)
      {
        if(!allStates[posX+xIndex][posY+yIndex])
        { 
          if (true)
          {
            allStates[posX+xIndex][posY+yIndex] = true;    
            // add that cell into the arraylist of microbes (alive and to be drawn)
            microbes.add(new Microbe(new PVector(posX+xIndex, posY+yIndex), true, 10));
          }
        }
      }
    }
  }

  prevX = posX;
  prevY = posY;
}


/*  session callbacks  */

void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}

void onEndSession()
{
  println("onEndSession: ");
}

void onFocusSession(String strFocus,PVector pos,float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}

/*  NITE context setup  */

void contextSetup() {
  println("Running Setup:...");
  context = new SimpleOpenNI(this);
  println("Animus On Line");

  // mirror is by default enabled
  context.setMirror(true);
  println("Mirroring Set");

  // enable depthMap generation 
  context.enableDepth();
  println("Genereating Depth Map...");

  // enable the hands + gesture
  context.enableGesture();
  context.enableHands();
  println("Tracking Enabled");

  // setup NITE 
  sessionManager = context.createSessionManager("Click,Wave", "RaiseHand");
}


void oscEvent(OscMessage theOscMessage) {
  /* check if theOscMessage has the address pattern we are looking for. */
  
  if(theOscMessage.checkAddrPattern("/atmo/freq")==true) {
    /* check if the typetag is the right one. */
    if(theOscMessage.checkTypetag("f")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float temp = theOscMessage.get(0).floatValue();  
      println(" temp: " + temp);    
      return;
    }  
  } 
  println(" typetag: "+theOscMessage.typetag());
  println("### received an osc message. with address pattern "+theOscMessage.addrPattern());
}

void stop() {
  synth.free();
  synth2.free();
}

