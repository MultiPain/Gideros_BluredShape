local desc = {
	blur = {
		{
			{name="vMatrix",type=Shader.CMATRIX,sys=Shader.SYS_WVP,vertex=true},
			{name="fColor",type=Shader.CFLOAT4,sys=Shader.SYS_COLOR,vertex=false},
			{name="fTexture",type=Shader.CTEXTURE,vertex=false},
			{name="fTexelSize",type=Shader.CFLOAT2,vertex=false},
			{name="fColorTransform",type=Shader.CFLOAT4,vertex=false},
			{name="fRad",type=Shader.CINT,vertex=false},
		},
		{
			{name="vVertex",type=Shader.DFLOAT,mult=3,slot=0,offset=0},
			{name="vColor",type=Shader.DUBYTE,mult=4,slot=1,offset=0},
			{name="vTexCoord",type=Shader.DFLOAT,mult=2,slot=2,offset=0},
		}
	},
	shadow = {
		{
			{name="vMatrix",type=Shader.CMATRIX,sys=Shader.SYS_WVP,vertex=true},
			{name="fColor",type=Shader.CFLOAT4,sys=Shader.SYS_COLOR,vertex=false},
			{name="fTexture",type=Shader.CTEXTURE,vertex=false},
			{name="am",type=Shader.CFLOAT2,vertex=false},
			{name="fColorTransform",type=Shader.CFLOAT4,vertex=false},
		},
		{
			{name="vVertex",type=Shader.DFLOAT,mult=3,slot=0,offset=0},
			{name="vColor",type=Shader.DUBYTE,mult=4,slot=1,offset=0},
			{name="vTexCoord",type=Shader.DFLOAT,mult=2,slot=2,offset=0},
		}
	}
}
local function smoothstep(t,a,b)
    local a,b = a or 0,b or 1
    local t = math.min(1,math.max(0,(t-a)/(b-a)))
    return t * t * (3 - 2 * t)
end


GShape = Core.class(Sprite)

-- params (table):
--		name (string): circle, rect or rrect [optional, default "rrect"]
--		shape (table) - params for shape
--			w (number): width of the shape (for "rect" and "rrect")
--			h (number): height of the shape (for "rect" and "rrect")
--			r (number): radius of the shape (for "rrect" - corner radius, for "circle" - circle radius) [optional, default 12]
--			r1 (number): radius of the top left corner (for "rrect" only) [optional, default 0]
--			r2 (number): radius of the top right corner (for "rrect" only) [optional, default 0]
--			r3 (number): radius of the bottom left corner (for "rrect" only) [optional, default 0]
--			r4 (number): radius of the bottom right corner (for "rrect" only) [optional, default 0]
--		ax (number): anchor x [optional, default 0.5]
--		ay (number): anchor y [optional, default 0.5]
--		blur (bool): enable bg blur [optional, default false]
--		blurLevel (number): amount of blur [optional, default 1]
--		shadow (bool): enable shadow drop [optional, default false]
--		shadowLevel (number): amount of shadow [optional, default 0.5]
--		shadowAlpha (number): shadow alpha [optional, default 0.5]
--		shadowOX (number): shadow x offset [optional, default 2]
--		shadowOY (number): shadow y offset [optional, default 2]
-- style (table):
--		color [optional, default black]
--		alpha [optional, default 1]
--		outline (table):
--			color [optional, default black]
--			alpha [optional, default 1]
--			width [optional, default 1]
--			feather [optional, default 0.2]
--	
local defaultRadius = 12
local blurLevel = 1
local shadowLevel = 0.5
local shadowAlpha = 0.5
local shadowOX = 2
local shadowOY = 2

function GShape:init(params, style)
	self.name = params.name or "rrect"
	self.ax = params.ax or 0.5
	self.ay = params.ay or 0.5
	self.style = style
	
	self[self.name](self, params.shape, style)
	self:addChild(self.shape)
	
	if (params.shadow) then 
		self.haveShadow = true
		self.shadowShader = Shader.new("shadowShader/vShader", "shadowShader/fShader", 0, 
			desc.shadow[1], desc.shadow[2]
		)
		self:initShadowShader(
			params.shadowLevel or shadowLevel,
			params.shadowAlpha or shadowAlpha,
			params.shadowOX or shadowOX,
			params.shadowOY or shadowOY
		)
	end
	
	if (params.blur) then 
		self.haveBlur = true
		self.blurShader = Shader.new("blurShader/vShader","blurShader/fShader", 0, 
			desc.blur[1], desc.blur[2]
		)
		self:initBlurShader(params.blurLevel or blurLevel)
	end
end
--
function GShape:setStyle(style)
	local outline = style.outline
	self.shape:setFillColor(style.color or 0, style.alpha or 1)
	self.shape:setLineColor(outline.color or 0, outline.alpha or 1)
	self.shape:setLineThickness(outline.width or 1, outline.feather or 0.2)
	self.shape:setAnchorPosition(self.ax*self.w, self.ay*self.h)
end
--
function GShape:initShadowShader(shadowLevel, shadowAlpha, shadowOX, shadowOY)
	
	local tw,th = self.shape:getSize()
	self.falloff = 1.3
	self.off = math.max(2, tw * 0.015, th * 0.015)
	
	local ww,hh = tw * self.falloff, th * self.falloff -- shadow image needs to be larger than the element casting the shadow, in order to capture the blurry shadow falloff
	self.ww, self.hh = ww,hh
	
	local d = math.max(ww, hh)
	local blurRad = smoothstep(d, math.max(SCREEN.W, SCREEN.H)*1.5, 60) * 1.5	
	local aspectX = d/ww * blurRad
	local aspectY = d/hh * blurRad

	local downSample = .3

	local dx = ww * downSample
	local dy = hh * downSample
	
	self.shadowShader:setConstant("am", Shader.CFLOAT2, 1, {0, 0})	
	self.shadowShader:setConstant("fColorTransform",Shader.CFLOAT4,1,{1,1,1,1})
	
	local textureA = RenderTarget.new(dx,dy,true)
	local textureB = RenderTarget.new(dx,dy,true)
	local bufferA = Bitmap.new(textureA)
	self.shadow = Bitmap.new(textureB)
	
	-- scale shape
	self.shape:setScale(downSample)
	-- make it black
	self.shape:setFillColor(0,shadowAlpha)
	self.shape:setLineColor(0,shadowAlpha)
	self.shape:setLineThickness(0, 0)
	textureA:draw(self.shape, 
		dx * self.ax,
		dy * self.ay
	)
	-- reset scale
	self.shape:setScale(1)
	-- reset colors
	self:setStyle(self.style)
	
	bufferA:setShader(self.shadowShader)
	self.shadowShader:setConstant("am", Shader.CFLOAT2, 1, {0, aspectY})
	self.shadow:setShader(self.shadowShader)
	textureB:draw(bufferA)
	self.shadowShader:setConstant("am", Shader.CFLOAT2, 1, {aspectX, 0})
	self.shadow:setScale(1/downSample)
	self.shadow:setAnchorPosition(
		dx * self.ax - shadowOX, 
		dy * self.ay - shadowOY
	)
	self.shadow.__dx = dx
	self.shadow.__dy = dy
	self.shadow.__shadowOX = shadowOX
	self.shadow.__shadowOY = shadowOY
	
	self:addChildAt(self.shadow,1)
end
--
function GShape:initBlurShader(blurLevel)
	local tw,th = self.w,self.h
	self.blurShader:setConstant("fRad",Shader.CINT,1,blurLevel)
	self.blurShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{1/tw,1/th})
	self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,{1,1,1,1})
	
	-- setup buffer for vertical blur
	self.textureA = RenderTarget.new(tw,th,false)
	self.bufferA = Bitmap.new(self.textureA)
	self.bufferA:setShader(self.blurShader)
		
	-- create texture for horizontal blur
	self.textureB = RenderTarget.new(tw,th,true)
	-- apply this texture to shape
	self.shape:setTexture(self.textureB)
	self.shape:setShader(self.blurShader)
end
--
function GShape:setBlurColor(r,g,b,a)
	r = r or 1
	g = g or 1
	b = b or 1
	a = a or 1
	self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,{r,g,b,a})
end
--
function GShape:renderBG()
	local x,y = self:getPosition()

	-- get object parent to find other childs that is above this object
	local par = self:getParent()
	if (not par) then return end
	local ind = par:getChildIndex(self)
	local l = par:getNumChildren()
	
	-- hide all childs that is ABOVE THIS object
	for i = ind, l do 
		local c = par:getChildAt(i)
		c:setVisible(false)
	end
	
	-- most importatn part, i guess :D
	-- draw the background that is overlaped by this shape (all objects above ignored
	-- so we dont get the recurseve rendering). Note, that this object will not be rendered ,
	-- because of previous loop, and shadow (if it exists) also will not be render, so thats how
	-- we got the shadow effect that is behind shape, but we dont see it on shape (only behind)
	self.textureA:draw(stage, -x + self.w * self.ax, -y + self.h * self.ay)
	
	--[[
	for i = ind, l do 
		local c = par:getChildAt(i)
		c:setVisible(true)
	end
	]]
end
--
function GShape:updateBlur()	
	if (self.haveBlur) then
		local tw,th = self.w,self.h
		--tw=2^(math.ceil(math.log(tw)/math.log(2)))
		--th=2^(math.ceil(math.log(th)/math.log(2)))		
		--print(tw,th)
		-- render shape 
		self:renderBG()	
		-- apply vertical blur
		self.blurShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{0,1/th})
		-- render verticaly blured shape
		self.textureB:draw(self.bufferA)
		-- apply horizontal blur
		self.blurShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{1/tw,0,})
	end
end
--
function GShape:circle(params, style)
	self.r = params.r
	self.w = self.r * 2
	self.h = self.r * 2
	local r = self.r
	self.shape = Path2D.new()
	local ms="MAAZ"
	--local mp={-r,0, r,r,0,0,0,r,0, r,r,0,0,0,-r,0} -- anchor in center 
	local mp = {0,r, r,r,0,0,1,2*r,r, r,r,0,0,1,0,r} -- anchor in top left corner
	self.shape:setPath(ms,mp)
	
	self.w=r*2
	self.h=r*2
	self:setStyle(style)
end
--
function GShape:rect(params, style)
	self.w = params.w
	self.h = params.h
	
	self.shape = Path2D.new()
	local ms="MHVHVZ"
	local mp={0,0, self.w, self.h, 0, 0}
	self.shape:setPath(ms,mp)
	
	self:setStyle(style)
	--self.shape:setAnchorPoint(self.ax, self.ay)
end
--
function GShape:rrect(params, style)
	self.w = params.w
	self.h = params.h
	--self.r = params.r or 16
	local r1,r2,r3,r4 = 0,0,0,0
	if (params.r1 or params.r2 or params.r3 or params.r4) then 
		r1 = params.r1 or 1
		r2 = params.r2 or 1
		r3 = params.r3 or 1
		r4 = params.r4 or 1
	else
		local mr = params.r
		if (mr) then 
			r1,r2,r3,r4 = mr,mr,mr,mr
		else
			r1,r2,r3,r4 = defaultRadius,defaultRadius,defaultRadius,defaultRadius
		end
	end
	
	self.shape = Path2D.new()
	local ms="MALALALAZ"
	local mp = {0,r1, 
		r1,r1,0,0,1,r1,0, self.w-r2,0, 
		r2,r2,0,0,1,self.w,r2, self.w,self.h-r3, 
		r3,r3,0,0,1,self.w-r3,self.h, r4,self.h, 
		r4,r4,0,0,1,0,self.h-r4
	}
	self.shape:setPath(ms,mp)
	
	self:setStyle(style)
end
--------------------------------------------------------
------------- OVERIDE SOME PARENT METHODS --------------
--------------------------------------------------------
function GShape:hitTestPoint(x, y)
	local tx,ty,w,h=self.shape:getBounds(stage)
	if (self.name ~= "circle") then		
		return not (x < tx or y < ty or x > tx + w or y > ty +h)
	end
	tx += self.r
	ty += self.r
	return (tx-x)^2+(ty-y)^2 <= self.r ^ 2
end
--
function GShape:setAnchorPoint(x, y)
	self.ax = x
	self.ay = y
	self.shape:setAnchorPoint(self.ax, self.ay)
	if (self.haveShadow) then 
		self.shadow:setAnchorPosition(
			self.shadow.__dx * self.ax - self.shadow.__shadowOX, 
			self.shadow.__dy * self.ay - self.shadow.__shadowOY 
		)
	end
end
