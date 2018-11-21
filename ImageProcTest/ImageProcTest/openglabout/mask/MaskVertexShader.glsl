attribute vec2 position;
attribute vec2 texCoord;
attribute vec2 position2;
attribute vec2 texCoord2;

varying vec2 texCoordVarying;
varying vec2 texCoordVarying2;
void main()
{
    gl_Position = vec4(position.x,position.y,0,1);
    texCoordVarying = texCoord;
    texCoordVarying2 = texCoord2;
}
