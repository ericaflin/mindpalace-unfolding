// Music by Podington Bear: https://freemusicarchive.org/music/Podington_Bear
import processing.sound.*;
SoundFile file;
//replace the sample.mp3 with your audio file name here
String[] songpaths = {
  "music/05 Podington Bear - Memory Wind.mp3",
  "music/07 Podington Bear - Satellite Bloom.mp3",
  "music/11 Podington Bear - Three Colors.mp3",
  "music/12 Podington Bear - Trinity Alps.mp3",
  "music/13 Podington Bear - Undersea Garden.mp3",
};
String path;

// Photo field
int PHOTO_BOUNDARY = 300;
int PHOTO_SPACING = 50;
int[][][] PHOTO_BRANCHES = {
  {{0,0,0},{0,1,1},{0,2,0},{0,3,0},{0,4,0},{0,5,0}},
  {{0,5,1},{0,5,2},{0,5,3},{0,5,4},{0,5,5},{0,5,6},{0,5,7}},
  {{1,6,8},{2,6,8},{3,6,8},{4,6,8},{5,6,8},{6,6,8},{7,6,8},{8,6,8},{9,6,8}},
  {{3,7,8},{3,8,8},{3,9,8}},
  {{6,7,8},{6,8,8},{6,9,8},{6,10,8},{6,11,8},{6,12,8}},
};
int cur_num_branches = 1;

// Glove
float NEUTRAL_GLOVE_ROTATE_X_AXIS = -PI/4; // neutral for open glove obj
float NEUTRAL_GLOVE_ROTATE_Y_AXIS = PI; // neutral for open glove obj
float NEUTRAL_GLOVE_ROTATE_Z_AXIS = PI; // neutral for open glove obj
PShape glove, open_glove, pointing_glove, fist_glove;
float glove_rotate_x_axis, glove_rotate_y_axis, glove_rotate_z_axis;
float glove_position_x = 100;
float glove_position_y = 600;
float glove_position_z = 0;
float fist_delay_time = 500;

int FIST_DELAY_TIME = 500;
PShape prior_glove;
float prior_x, prior_y, prior_z;
int fist_start;

// Camera
float eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ;
float camera_speed = 1;

void setup() {
  size(1200, 800, P3D);
  // Music
  int random_song = floor(random(0, songpaths.length));
  path = sketchPath(songpaths[random_song]);
  file = new SoundFile(this, path);
  file.play();
  
  // Glove
  open_glove = loadShape("open_hand.obj");
  pointing_glove = loadShape("pointing_hand.obj");
  fist_glove = loadShape("fist_hand.obj");
  glove = open_glove;
  glove_rotate_x_axis = NEUTRAL_GLOVE_ROTATE_X_AXIS;
  glove_rotate_y_axis = NEUTRAL_GLOVE_ROTATE_Y_AXIS;
  glove_rotate_z_axis = NEUTRAL_GLOVE_ROTATE_Z_AXIS;
  
  // Camera
  eyeX = width/2.0;
  eyeY = height/2.0;
  eyeZ = (height/2.0) / tan(PI*30.0 / 180.0);
  centerX = width/2.0;
  centerY = height/2.0;
  centerZ = 0;
  upX = 0;
  upY = 1;
  upZ = 0;
}

void draw() {
  background(0);
  
  // Field of photos
  translate(width * 0.5, height * 0.5, PHOTO_BOUNDARY * -2);
  for (int branch = 0; branch < cur_num_branches; branch++) {
    for (int[] photo: PHOTO_BRANCHES[branch]) {
        int x = -PHOTO_BOUNDARY + (PHOTO_SPACING * photo[0]);
        int y = -PHOTO_BOUNDARY + (PHOTO_SPACING * photo[1]);
        int z = -PHOTO_BOUNDARY + (PHOTO_SPACING * photo[2]);
        
        pushMatrix();
        translate(x, y, z);
        fill(getPhotoColor(x), getPhotoColor(y), 
          getPhotoColor(z));
        box(20, 30, 10);
        popMatrix();
    }
  }

  // Glove
  if (
    glove == fist_glove
    && millis() - fist_start >= fist_delay_time
  ) {
    glove = prior_glove;
    glove_rotate_x_axis = prior_x;
    glove_rotate_y_axis = prior_y;
    glove_rotate_z_axis = prior_z;
  }
  
  translate(glove_position_x, glove_position_y, glove_position_z);
  scale(10);
  rotateX(glove_rotate_x_axis);
  rotateY(glove_rotate_y_axis);  
  rotateZ(glove_rotate_z_axis);
  shape(glove);
  
  // Camera
  camera(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ);
  // If still pointing, keep moving in that direction
  if (glove == pointing_glove) {
    moveInGloveDirection();
  }
}

// Clicking changes glove gesture
void mousePressed() {
  if (glove == open_glove) {
    glove = pointing_glove;
    glove_rotate_x_axis = getOpenToPointerXRotation(glove_rotate_x_axis);
    moveInGloveDirection();
  }
  else {
    glove = open_glove;
    glove_rotate_x_axis = getPointerToOpenXRotation(glove_rotate_x_axis);
  }
}

// Moving mouse moves hand, and if pointing, moves camera too
void mouseMoved() {
  float glove_horizontal_rotation =  ((mouseX - (width * 0.5))/(width)) * PI/2;
  float glove_vertical_rotation =  ((mouseY - (height * 0.5))/(height)) * PI/2;
  
  // Rotate glove
  if (glove == open_glove) {
    glove_rotate_x_axis = NEUTRAL_GLOVE_ROTATE_X_AXIS + glove_vertical_rotation;
    glove_rotate_y_axis = NEUTRAL_GLOVE_ROTATE_Y_AXIS - glove_horizontal_rotation;
  }
  else { // pointing glove
      glove_rotate_x_axis = getOpenToPointerXRotation(NEUTRAL_GLOVE_ROTATE_X_AXIS) + glove_vertical_rotation;
      glove_rotate_z_axis = NEUTRAL_GLOVE_ROTATE_Y_AXIS + glove_horizontal_rotation;
  }

  // If glove is pointing, move in that direction
  if (glove == pointing_glove) {
    moveInGloveDirection();
  }
}

void keyPressed() {
  // Fist gesture adds a photo branch
  if (
    cur_num_branches < PHOTO_BRANCHES.length
    && (key == 'p' || key == 'P')
  ) {
    // Fist gesture
    prior_glove = glove;
    prior_x = glove_rotate_x_axis;
    prior_y = glove_rotate_y_axis;
    prior_z = glove_rotate_z_axis;
    fist_start = millis();
    pushMatrix();
    glove = fist_glove;
    glove_rotate_x_axis = PI;
    glove_rotate_y_axis = PI;
    glove_rotate_z_axis = 3*PI/2;
    popMatrix();
    
    // Add branching branch
    cur_num_branches++;
  }
}

int getPhotoColor(int offset) {
  return (int) ((offset + PHOTO_BOUNDARY) / (2.0 * PHOTO_BOUNDARY) * 255);
}

float getOpenToPointerXRotation(float open_glove_x_rotation) {
  return open_glove_x_rotation - PI/2;
}  

float getPointerToOpenXRotation(float pointing_glove_x_rotation) {
  return pointing_glove_x_rotation + PI/2;
}  

void moveInGloveDirection() {
  float x_factor =  (mouseX - (width * 0.5))/(width); // [-1, 1]
  float y_factor =  (mouseY - (height * 0.5))/(height); // [-1, 1]
  float z_factor = sqrt(1 - pow(x_factor, 2) - pow(y_factor, 2)); // From equation of sphere with radius 1
  eyeX -= x_factor * camera_speed;
  eyeY -= y_factor * camera_speed;
  eyeZ -= z_factor * camera_speed;
}
