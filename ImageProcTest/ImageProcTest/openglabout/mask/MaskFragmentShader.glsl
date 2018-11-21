varying highp vec2 texCoordVarying;
varying highp vec2 texCoordVarying2;
precision mediump float;

uniform sampler2D SamplerRGBA1;
uniform sampler2D SamplerRGBA2;

void main()
{
    lowp vec4 textureColor = texture2D(SamplerRGBA1, texCoordVarying);
    lowp vec4 textureColor2 = texture2D(SamplerRGBA2, texCoordVarying2);
    lowp float newAlpha = dot(textureColor2.rgb, vec3(.33333334, .33333334, .33333334)) * textureColor2.a;
    
    gl_FragColor = vec4(textureColor.xyz, newAlpha);
}
