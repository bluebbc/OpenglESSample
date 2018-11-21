varying highp vec2 texCoordVarying;
precision mediump float;

uniform sampler2D SamplerRGBA;
void main()
{
    gl_FragColor = texture2D(SamplerRGBA, texCoordVarying);
}
