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
    
    if (!quorumFlag) 
    {
     fill(118,115,111,turnOnTime);
     
     strokeWeight(1);
     stroke(random(112,118),242,242,random(50,255));
     
     if(turnOnTime < 100) 
       turnOnTime++;
    }
    else {
      strokeWeight(2);
      fill(51,143,188,map(sin(glowCounter),-1,1,0,180));
      stroke(random(40,55),60,30,random(50,255));
    }

    beginShape(QUADS);
    {
      vertex(pos.x*res, pos.y*res);
      vertex(pos.x*res + mSize, pos.y*res);
      vertex(pos.x*res + mSize, pos.y*res + mSize);
      vertex(pos.x*res, pos.y*res +mSize);
    }
    endShape();

    noStroke();
  }

  public void drawDeadMicrobe()
  {
    strokeWeight(5);
    stroke(67,78,79);
    point(pos.x*res, pos.y*res);
  }
}

