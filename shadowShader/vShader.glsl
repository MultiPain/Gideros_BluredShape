attribute highp vec3 vVertex;
attribute mediump vec2 vTexCoord;
uniform highp mat4 vMatrix;
varying mediump vec2 fTexCoord;
uniform vec2 am;

varying vec2 v_blurTexCoords[14];

void main() {
	vec4 vertex = vec4(vVertex,1.0);
	gl_Position = vMatrix*vertex;
	fTexCoord=vTexCoord;	
    v_blurTexCoords[ 0] = vTexCoord + vec2(-0.028 * am.x, -0.028 * am.y);
    v_blurTexCoords[ 1] = vTexCoord + vec2(-0.024 * am.x, -0.024 * am.y);
    v_blurTexCoords[ 2] = vTexCoord + vec2(-0.020 * am.x, -0.020 * am.y);
    v_blurTexCoords[ 3] = vTexCoord + vec2(-0.016 * am.x, -0.016 * am.y);
    v_blurTexCoords[ 4] = vTexCoord + vec2(-0.012 * am.x, -0.012 * am.y);
    v_blurTexCoords[ 5] = vTexCoord + vec2(-0.008 * am.x, -0.008 * am.y);
    v_blurTexCoords[ 6] = vTexCoord + vec2(-0.004 * am.x, -0.004 * am.y);
    v_blurTexCoords[ 7] = vTexCoord + vec2( 0.004 * am.x,  0.004 * am.y);
    v_blurTexCoords[ 8] = vTexCoord + vec2( 0.008 * am.x,  0.008 * am.y);
    v_blurTexCoords[ 9] = vTexCoord + vec2( 0.012 * am.x,  0.012 * am.y);
    v_blurTexCoords[10] = vTexCoord + vec2( 0.016 * am.x,  0.016 * am.y);
    v_blurTexCoords[11] = vTexCoord + vec2( 0.020 * am.x,  0.020 * am.y);
    v_blurTexCoords[12] = vTexCoord + vec2( 0.024 * am.x,  0.024 * am.y);
    v_blurTexCoords[13] = vTexCoord + vec2( 0.028 * am.x,  0.028 * am.y);
}