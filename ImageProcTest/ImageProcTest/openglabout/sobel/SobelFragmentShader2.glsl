varying highp vec2 texCoordVarying;
precision mediump float;

uniform sampler2D SamplerRGBA;
void main()
{
    vec2 center = vec2(0.5);
    float d = distance(texCoordVarying, center);
    if(d<0.25){
        gl_FragColor = texture2D(SamplerRGBA, texCoordVarying);
    }
    else{
        gl_FragColor = vec4(0);
    }
}
