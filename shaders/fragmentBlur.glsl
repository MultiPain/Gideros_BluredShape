#define STEPS 20

uniform lowp vec4 fColor;
uniform lowp sampler2D fTexture;
uniform int fRad;
uniform mediump vec2 fTexelSize;
varying mediump vec2 fTexCoord;
uniform lowp vec4 fColorTransform;

void main() {
	lowp vec4 frag=vec4(0,0,0,0);
	int ext=2*fRad+1;	
	mediump vec2 tc=fTexCoord-fTexelSize*float(fRad);
	for (int v=0;v<STEPS;v++)	
	{
		if (v<ext)
			frag=frag+texture2D(fTexture, tc);
		tc+=fTexelSize;
	}
	frag=frag/float(ext);
	if (frag.a==0.0) discard;
	gl_FragColor = frag * fColorTransform;
}
