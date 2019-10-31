uniform lowp vec4 fColor;
uniform lowp sampler2D fTexture;
varying mediump vec2 fTexCoord;
varying mediump vec4 fColorTransform;
varying vec2 vTexCoord;

varying vec2 v_blurTexCoords[14];

vec4 blur(in sampler2D texture)
{
	mediump vec4 outColor = vec4(0.0);
	outColor += texture2D(texture, v_blurTexCoords[ 0])*0.0044299121055113265;
    outColor += texture2D(texture, v_blurTexCoords[ 1])*0.00895781211794;
    outColor += texture2D(texture, v_blurTexCoords[ 2])*0.0215963866053;
    outColor += texture2D(texture, v_blurTexCoords[ 3])*0.0443683338718;
    outColor += texture2D(texture, v_blurTexCoords[ 4])*0.0776744219933;
    outColor += texture2D(texture, v_blurTexCoords[ 5])*0.115876621105;
    outColor += texture2D(texture, v_blurTexCoords[ 6])*0.147308056121;
    outColor += texture2D(texture, fTexCoord          )*0.159576912161;
    outColor += texture2D(texture, v_blurTexCoords[ 7])*0.147308056121;
    outColor += texture2D(texture, v_blurTexCoords[ 8])*0.115876621105;
    outColor += texture2D(texture, v_blurTexCoords[ 9])*0.0776744219933;
    outColor += texture2D(texture, v_blurTexCoords[10])*0.0443683338718;
    outColor += texture2D(texture, v_blurTexCoords[11])*0.0215963866053;
    outColor += texture2D(texture, v_blurTexCoords[12])*0.00895781211794;
    outColor += texture2D(texture, v_blurTexCoords[13])*0.0044299121055113265;
	return outColor;
}

void main() {
	vec4 outColor = blur(fTexture);
	float v1 = v_blurTexCoords[0].x;
	float v2 = v_blurTexCoords[0].y;
	gl_FragColor =  outColor;//vec4(v1,v2,0,1);
	//texture2D(fTexture, v_blurTexCoords[ 0])*0.0044299121055113265;
	//texture2D(fTexture, fTexCoord);//outColor ;
}