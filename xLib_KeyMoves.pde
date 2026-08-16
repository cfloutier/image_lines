void keyPressed() {

  if (key == CODED) {
    if (keyCode == UP)
      set_key_move(new PVector(0, -1));
    else if (keyCode == DOWN)
      set_key_move(new PVector(0, 1));
    else if (keyCode == LEFT)
      set_key_move(new PVector(-1, 0));
    else if (keyCode == RIGHT)
      set_key_move(new PVector(1, 0));
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == UP)
      set_key_move(new PVector(0, 0));
    else if (keyCode == DOWN)
      set_key_move(new PVector(0, 0));
    else if (keyCode == LEFT)
      set_key_move(new PVector(0, 0));
    else if (keyCode == RIGHT)
      set_key_move(new PVector(0, 0));
  }
}

void set_key_move(PVector key_move)
{
  dataGui.set_key_move(key_move);
  //dataGui.tab_name = cp5.getWindow( ).getCurrentTab().getName();
  //print(data.tab_name);
}
