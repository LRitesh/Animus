class Microbe {
  PVector pos;
  boolean state;
  float turnOnTime;
  float mSize;

  public Microbe(PVector mPos, boolean mState, float mTOT)
  {
    pos = mPos;
    state = mState;
    turnOnTime = mTOT;
    mSize = 3*res;
  }

  public void drawMicrobe()
  {
    strokeWeight(3);
 //    fill(147,75,79,random(1,255));
//   colorMode(HSB,100);
//    if (!quorumFlag) fill(51,143,188,random(255));
//    else fill(211,227,46,random(255));

     if (!quorumFlag) 
     {
//       fill(51,143,188,random(255)); //blue
       fill(118,115,111,turnOnTime);
 
       strokeWeight(1);
     //  stroke(random(40,55),60,30,random(50,255));
     stroke(random(112,118),242,242,random(50,255));
       if(turnOnTime < 100) turnOnTime++;
     }
     else {
       strokeWeight(2);
  //     fill(118,115,111,random(0,180));
       fill(51,143,188,map(sin(glowCounter),-1,1,0,180));
//       stroke(random(112,118),242,242,map(sin(glowCounter),-1,1,20,255));
      stroke(random(40,55),60,30,random(50,255));
  
     }
    { 
      beginShape(QUADS);
      {
        vertex(pos.x*res, pos.y*res);
        vertex(pos.x*res + mSize, pos.y*res);
        vertex(pos.x*res + mSize, pos.y*res + mSize);
        vertex(pos.x*res, pos.y*res +mSize);
      }
      endShape();
//      ellipse (pos.x*res, pos.y*res, random(res,3*res), random(res,3*res));
    }
    
    noStroke();
  
  }

  public void drawDeadMicrobe()
  {
    //    stroke(131,81,81);
    strokeWeight(5);
    stroke(67,78,79);
    point(pos.x*res, pos.y*res);
//    fill(67,78,79,random(1,255));
//    ellipse(pos.x*res,pos.y*res,res,res);
//    stroke(77,110,105);
//    point(pos.x*res, pos.y*res);

  }
}

