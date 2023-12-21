/*

 Fall 2023 Semester
 [AAT3008] Creative Algorithms - Final Project
 20201127 LEE CHANG HYUN
  
 "PINGPONGwithALLOS"
 
   This is a 3D ping pong game named [PINGPONG with ALLOS]
  It utilizes PeasyCam and Minim libraries for camera control and audio playback.
  The game involves hitting a ball on a ping pong table, featuring coaching feedback, scoring, and a timer.
  It interacts with a machine learning model through OSC messages, adjusting ball behavior. 
  Visual elements include a 3D ping pong table, timer display, coaching messages, and characters.
  Success/failure screens prompt user restart or exit.

 
 */

import oscP5.*;
import netP5.*;
import peasy.*;
import ddf.minim.*;
import java.util.Iterator;


Minim minim;
AudioPlayer bgm;
AudioPlayer ping;
AudioPlayer pong;

OscP5 oscP5;
NetAddress dest;
PeasyCam cam;  // PeasyCam 선언

ArrayList<Ball> balls;  // Ball 클래스의 ArrayList
boolean gameStarted = false;

PFont myFont;
float type;

PImage[] allos = new PImage[4];
PImage[] sogangi = new PImage[4];
PImage logo;

int timerDuration = 5; // Timer duration in seconds
int timerStartTime;      // Start time of the timer

int elapsedTime = 0;
int remainingTime = 0;

//모션 시간 차 계산용 변수
int lastTime;  // 마지막으로 동작이 실행된 시간을 저장
int currentTime; //현재 시간 저장

int pongs = 0;  // 공 잘 넘겼는 지 확인하는 변수
int stacks = 0;  // 연속으로 성공한 변수
int stacks_bad = 0;
int allos_img = 0;

//  점수
int score = 0;
int coach = 0;

void setup() {
  size(960, 540, P3D);
  
  // load all sources---------------------
  myFont = createFont("Giants-Inline.otf", 32);
  textFont(myFont);
  minim = new Minim(this);
  bgm = minim.loadFile("bgm.mp3");
  ping = minim.loadFile("ping.mp3");
  pong = minim.loadFile("pong.mp3");
  bgm.loop();
  for(int i=0;i<4;i++){
    allos[i] = loadImage("al"+i+".png");
    allos[i].resize(1000,1500);
  }
  for(int i=0;i<4;i++){
    sogangi[i] = loadImage("so"+i+".png");
    sogangi[i].resize(1000,1500);
  }
  logo = loadImage("logo.png");
  logo.resize(238,342);
  //--------------------------------------
  
  // set the frame rate
  frameRate(60);
  
  oscP5 = new OscP5(this, 12000);
  dest = new NetAddress("127.0.0.1", 6448);

  // PeasyCam 초기화
  cam = new PeasyCam(this, width / 2);
  cam.setRotations(PI / 15, 0, 0);  // X축을 기준으로 시점 설정

  balls = new ArrayList<Ball>();  // ArrayList 초기화

}

void draw() {
  background(255);
  
  draw_sogangi();
  draw_object();

  if (gameStarted) {  // 게임이 시작되면 모든 Ball을 업데이트하고 시작
    draw_timer();
    for (Ball ball : balls) {
      ball.update();
      ball.display();
    }
    motion();
    score();
    coaching();
    draw_stacks();
    draw_allos();
    if (remainingTime == 0) {
      if (score > 0) {
        success();
      } else {
        fail();
      }
    }
  } else {  // 게임이 시작되지 않았으면 메시지 표시
    displayStartMessage();
  } 
}


class Ball {
  float x, y, z;
  float speedX, speedY, speedZ;
  float gravity;

  Ball(float speedX) {
    this.x = 0;
    this.y = -30;
    this.z = -150;
    this.speedX = speedX;
    this.speedY = 0;
    this.speedZ = 10;
    this.gravity = 0.1;
  }

  void update() {
    speedY += gravity;
    x += speedX;
    y += speedY;
    z += speedZ;

    // 탁구대와의 충돌 체크
    if (y > -5 && y < 5 && z > -137 && z < 137 && x > -76 && x < 76) {
      allos_img = 0;
      // 충돌 발생 시 y 속도를 반대로 변경
      speedY = -speedY;
      if(z > 0 && z < 137){
        
        ping.rewind();
        ping.play();
        pongs = 0;
        coach = 3;
        
      } else {  // 잘 받아쳐서 상대 탁구대에 공이 닿았을 때
        
        pong.rewind();
        pong.play();
        if(stacks < 10){  // 스택은 최대 10개까지 
          stacks += 1;
          stacks_bad = 0;
        }
        pongs = 1;
        if(stacks > 5){
          score += 3;
        }else if(stacks > 3){
          score += 2;
        }else{
          score += 1;
        }
        coach = 1;
      }
      
    }
    
    // 알로스 리시브
    if (z < -151 && y < 0 && y > -50 && x > -76 && x < 76) {
      if(pongs == 1){ 
        x = 0;
        y = -30;
        z = -150;
        speedX = (random(2) > 1) ? 1 : -1;
        speedY = 0;
        speedZ = 10;
        allos_img = 1;
      } else {
        coach = 2;
      }
    }
    
    if (y > 76) {
      allos_img = 1;
      x = 0;
      y = -30;
      z = -150;
      speedX = (random(2) > 1) ? 1 : -1;
      speedY = 0;
      speedZ = 10;
      stacks = 0;
      pongs = 0;
      stacks_bad +=1;
    }
  }

  void display() {
    pushMatrix(); // 현재 변환 상태 저장

    translate(x, y, z);

    fill(255, 127, 0);
    noStroke();
    sphere(4); // 지름이 15인 3D 구

    popMatrix(); // 이전 변환 상태로 복원
  }
}

void displayStartMessage() {
  cam.beginHUD(); // HUD 모드 시작
  fill(255,255,255,160);
  rect(0,0,960,540);
  textAlign(CENTER, CENTER);
  fill(0);
  textSize(50);
  text("PINGPONG\nwithALLOS",width / 2, 200);
  textSize(24);
  text("press [SPACE] to start!", width / 2, 400);
  textSize(15);
  text("It can be moved around the screen with the mouse. Press [ENTER] to return to the original composition.", width / 2, 450);
  text("Fall 2023 Semester [AAT3008] Creative Algorithms - Final Project 20201127 LEE CHANG HYUN", width / 2, 500);
  cam.endHUD(); // HUD 모드 종료
}

void keyPressed() {
  if (key == ' ') {
    // 스페이스바를 누르면 새로운 공 추가
    int direction = (balls.size() % 2 == 0) ? 1 : -1;  // 번갈아가며 방향 설정
    Ball newBall = new Ball(direction);
    balls.add(newBall);
    gameStarted = true;
    
    timerStartTime = millis();
  } else if (key == ENTER) {
    // Enter 키를 누르면 초기 각도로 카메라를 설정
    cam.setRotations(PI / 15, 0, 0);
  }
}

void score(){
  cam.beginHUD(); // HUD 모드 시작
  fill(0);
  textSize(24);
  textAlign(CENTER,CENTER);
  text("SCORE",width/2,20);
  textSize(50);
  text(score,width/2,70);
  cam.endHUD(); // HUD 모드 종료
}

void coaching(){
  cam.beginHUD();
  if(coach == 1){
    text("Good!",width*5/8,height*2/5);
  } else if (coach == 2){
    text("FAST!",width*5/8,height*2/5);
  } else if (coach == 3){
    text("SLOW!",width*5/8,height*2/5);
  } else{
    
  }
  cam.endHUD();
}

void draw_stacks(){
  cam.beginHUD(); // HUD 모드 시작
  fill(0);
  textSize(24);
  textAlign(CENTER,CENTER);
  text("STACKS",width/4,20);
  textSize(50);
  if(stacks > 7){
    fill(255,0,0);
  } else if (stacks > 5){
    fill(200,0,0);
  } else if (stacks > 3){
    fill(150,0,0);
  }
  text(stacks,width/4,70);
  cam.endHUD(); // HUD 모드 종료
}

void draw_allos(){
  translate(10,-20,-150);
  image(allos[allos_img],-25,-37.5,50,75);
  translate(-10,20,150);
}

void draw_timer(){
  
  elapsedTime = millis() - timerStartTime;
  remainingTime = max(0, timerDuration - int(elapsedTime / 1000));
  
  cam.beginHUD();
  fill(0);
  textSize(24);
  textAlign(CENTER, CENTER);
  text("TIMER", width*3/4,20);
  textSize(50);
  if(remainingTime < 11){
    fill(255,0,0);
  }
  text(nf(remainingTime, 2) + "s", width*3/4, 70);
  cam.endHUD();
}

void success() {
  cam.beginHUD();
  fill(255,255,255,160);
  rect(0,0,960,540);
  image(allos[2],-100,-250, 600,900);
  fill(0);
  textSize(80);
  textAlign(CENTER, CENTER);
  text("SUCCESS!", width*2/3, height / 3);
  textSize(24);
  text("The timer has exceeded 100 seconds!\nPress [R] to restart or [Q] to exit", width*2/3, height*2/3);
  cam.endHUD();

  // 사용자 입력 확인
  if (keyPressed) {
    if (key == 'R' || key == 'r') {
      resetGame();
      println("reset");
    } else if (key == 'Q' || key == 'q') {
      exit();
    }
  }
}

void fail() {
  cam.beginHUD();
  fill(255,255,255,160);
  rect(0,0,960,540);
  image(allos[3],-100,-250, 600,900);
  fill(0);
  textSize(80);
  textAlign(CENTER, CENTER);
  text("FAIL", width*2/3, height / 3);
  textSize(24);
  text("The timer has exceeded 100 seconds!\nPress [R] to restart or [Q] to exit.", width*2/3, height*2/3);
  cam.endHUD();

  // 사용자 입력 확인
  if (keyPressed) {
    if (key == 'R' || key == 'r') {
      resetGame();
      println("reset");
    } else if (key == 'Q' || key == 'q') {
      exit();
    }
  }
}

void resetGame() {
  score = 0;
  balls.clear();  // 모든 공 제거
  gameStarted = false;
  timerStartTime = millis();  // 타이머 재설정
}

void draw_sogangi(){
  cam.beginHUD();
  int mood = 0;
  if(stacks>4){
    mood = 3;
  }else if(stacks >2){
    mood = 1;
  }else if(stacks_bad > 2){
    mood = 2;
  }
  image(sogangi[mood],0,0, 400,600);
  
  cam.endHUD();
}

//OSC MESSAGE
void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/wek/outputs"))
  {
    msg.print();
    type = msg.get(0).floatValue();
    currentTime = millis();
  } else {
    //msg.print();
  }
}

void motion(){
  if (type == 1) {
    // 클래스 0에 대한 동작 수행
  } else if (type == 2 && currentTime - lastTime > 800) {
    // 클래스 1에 대한 동작 수행
    // 마지막으로 생성된 공의 조작
    if (balls.size() > 0) {
      Ball lastBall = balls.get(balls.size() - 1);
      if (lastBall.speedX > 0 && lastBall.speedY < 0) {
        // speedX가 양수이고 speedY가 음수인 경우
        lastBall.speedX *= -1;
        lastBall.speedZ *= -1;
      }
    }
    lastTime = currentTime;
  } else if (type == 3 && currentTime - lastTime > 800) {
    // 클래스 1에 대한 동작 수행
    // 마지막으로 생성된 공의 조작
    if (balls.size() > 0) { 
      Ball lastBall = balls.get(balls.size() - 1);
      if (lastBall.speedX < 0 && lastBall.speedY < 0) {
        // speedX가 음수이고 speedY가 음수인 경우
        lastBall.speedX *= -1;
        lastBall.speedZ *= -1;
      }
    }
    lastTime = currentTime;
  }
}

/* 탁구대 그리기 */
void draw_object(){
  
  fill(230);
  //센터라인
  box(0.5,2.5,270);
  //흰 테두리
  translate(75.25, 0, 0);
  box(2, 5, 270);
  translate(-75.25,0, 0);
  translate(-75.25, 0, 0);
  box(2, 5, 270);
  translate(75.25,0, 0);
  translate(0, 0, 136);
  box(152.5, 5, 2);
  translate(0, 0, -136);
  translate(0, 0, -136);
  box(152.5, 5, 2);
  translate(0, 0, 136);
  // 상판
  translate(37.25, 0, 0);
  fill(22, 30, 93);
  box(74, 2.5, 270);
  translate(-37.25,0, 0);
  translate(-37.25, 0, 0);
  fill(22, 30, 93);
  box(74, 2.5, 270);
  translate(37.25,0, 0);
  //다리
  fill(100);
  translate(60, 38, 110);
  box(5, 76, 10);
  translate(-60, -38, -110);
  translate(-60, 38, 110);
  box(5, 76, 10);
  translate(60, -38, -110);
  translate(60, 38, -110);
  box(5, 76, 10);
  translate(-60, -38, 110);
  translate(-60, 38, -110);
  box(5, 76, 10);
  translate(60, -38, 110);
  
  translate(60, 38, 27);
  box(5, 76, 10);
  translate(-60, -38, -27);
  translate(-60, 38, 27);
  box(5, 76, 10);
  translate(60, -38, -27);
  translate(60, 38, -27);
  box(5, 76, 10);
  translate(-60, -38, 27);
  translate(-60, 38, -27);
  box(5, 76, 10);
  translate(60, -38, 27);
  
  translate(0, 38, -110);
  box(120, 10, 5);
  translate(0, -38, 110);
  translate(0, 38, 110);
  box(120, 10, 5);
  translate(0, -38, -110);
  //네트
  translate(83.875,0, 0);
  box(15.25, 3, 3);
  translate(-83.875,0, 0);
  translate(-83.875,0, 0);
  box(15.25, 3, 3);
  translate(83.875, 0, 0);
  translate(93, -6.875, 0);
  box(3, 16.75, 3);
  translate(-93, 6.875, 0);
  translate(-93, -6.875, 0);
  box(3, 16.75, 3);
  translate(93, 6.875, 0);
  
  fill(230);
  translate(0, -14.25, 0);
  box(183, 2, 1);
  translate(0, 14.25, 0);
  
  fill(0);
  for ( int i=-90; i <=90; i +=3){
    translate(i, -7, 0);
    box(0.5, 14, 0.5);
    translate(-i, 7, 0);
  }
  for ( int i=2; i <=15; i +=3){
    translate(0, -i, 0);
    box(183, 0.5, 0.5);
    translate(0, i, 0);
  }
  //코트
  pushMatrix();
  fill(179,0,0);
  rotateX(radians(90));
  translate(0, 0, -76);
  rect(-350, -700, 700, 1400);
  popMatrix();
  
  pushMatrix();
  fill(125,0,0);
  translate(0, 0, -700);
  rect(-350, 0, 700, 76);
  popMatrix();
  
  pushMatrix();
  fill(125,0,0);
  translate(0, 0, 700);
  rect(-350, 0, 700, 76);
  popMatrix();
  
  pushMatrix();
  fill(125,0,0);
  rotateY(radians(90));
  translate(0, 0, 350);
  rect(-700, 0, 1400, 76);
  popMatrix();
  
  pushMatrix();
  fill(125,0,0);
  rotateY(radians(90));
  translate(0, 0, -350);
  rect(-700, 0, 1400, 76);
  popMatrix();
  
  pushMatrix();
  rotateX(radians(90));
  translate(0, 300, -75);
  image(logo,-119,-171,238,342);
  popMatrix();
  
  pushMatrix();
  rotateX(radians(90));
  translate(0, 520, -74);
  fill(125,0,0);
  textAlign(CENTER,CENTER);
  text("Fall 2023 Semester\n[AAT3008] Creative Algorithms\n20201127 Lee Changhyun\n[탁구 도사 알로스]",0,0);
  popMatrix();
  
}
