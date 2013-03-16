/*******************************************************************
Author: Ritesh Lala
Original release: May 6, 2011
Updated: Mar 16, 2013
Cellular Automata for Animus @ MAT EoYS 2011

Copyright © 2013 Ritesh Lala <riteshlala.ed@gmail.com>

This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the LICENSE file for more details.
**********************************************************************/

import supercollider.*;
import oscP5.*;

OscP5 oscP5;
Synth synth, synth2;

int w = screen.width;  
int h = screen.height;

int quorumThreshold = 2800;
int maxMicrobes = 6000;
float tempM = 0;

float invWidth, invHeight, aspectRatio, aspectRatio2;

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
  
  // initialize the arraylist with storage capacity rows*columns
  microbes = new ArrayList(rows*columns);

  background(0);
  smooth();
  println("press'c' to clean up");
  
  // setup supercollider
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

  // update states for cellular automata
  stateUpdate();
  
  if (microbes.size() > quorumThreshold)//((columns*rows)/(res/2))) 
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

  if(quorumFlag) {
    synth.set("freq", 250);
    synth2.set("freq", map(sin(glowCounter),-1,1,250,260)); 
  }
  else {
    synth.set("freq", map(numberOfMicrobes,0,quorumThreshold,100,250));
    synth2.set("freq", map(numberOfMicrobes,0,quorumThreshold,100,250));
   }
   
  fill(250);
  text(numberOfMicrobes,50,50);
  
  float m = millis() - tempM;
  if(m > 60000 ) {
     for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        allStates[i][j] = false;
        allStatesTemp[i][j] = false;
      }
    }
    microbes.clear();
    background(0);
    tempM = millis();
  }
  text((60000-m)/1000,width-100,height-50);
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
        if(mNeighbors == (int) (sqrt((cIndex-prevX)*(cIndex-prevX) + (rIndex-prevY)*(rIndex-prevY))/(res*1.5)) && (microbes.size() < maxMicrobes)) 
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
        if(mNeighbors == 3 && (microbes.size() < maxMicrobes))
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
    stopAndExit();
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

void stopAndExit() {
  synth.free();
  synth2.free();
  exit();
}

