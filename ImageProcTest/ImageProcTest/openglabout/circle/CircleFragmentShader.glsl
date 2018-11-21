varying highp vec2 texCoordVarying;
precision mediump float;

uniform sampler2D SamplerRGBA;
void main()
{
#if 0
    vec2 center = vec2(0.5);
    float d = distance(texCoordVarying, center);
    if(d<0.25){
        gl_FragColor = texture2D(SamplerRGBA, texCoordVarying);
    }
    else{
        gl_FragColor = vec4(0);
    }
#else
    float x = texCoordVarying.x;
    float y = texCoordVarying.y;
    if(x<0.75 && x>0.25 && y<0.75 && y>0.25){
        gl_FragColor = texture2D(SamplerRGBA, texCoordVarying);
    }else{
        gl_FragColor = vec4(0);
    }
#endif
}
