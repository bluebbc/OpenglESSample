varying highp vec2 texCoordVarying;
precision mediump float;

uniform sampler2D SamplerRGBA1;
uniform sampler2D SamplerRGBA2;

void main()
{
    vec4 tmp = texture2D(SamplerRGBA1, texCoordVarying);
    gl_FragColor = texture2D(SamplerRGBA1, texCoordVarying);
}
