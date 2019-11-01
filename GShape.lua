local _PACKAGE = (...):match("(.-)([^\\/]-%.?([^%.\\/]*))$")

local desc = {
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
}

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
local blurLevel = 2

local shadowLevel = 2
local shadowAlpha = 1
local shadowOX = 0
local shadowOY = 0

local falloff = 1.4 
local downSample = 0.45

function GShape:init(params, style)
	self.name = params.name or "rrect"
	self.ax = params.ax or 0.5
	self.ay = params.ay or 0.5
	self.style = style
	self.drawX = 0
	self.drawY = 0
	
	self[self.name](self, params.shape, style)
	self.shapeW = self.shape:getWidth()
	self.shapeH = self.shape:getHeight()
	self:addChild(self.shape)
	
	if (params.shadow) then 
		self.haveShadow = true
		
		self.shadowShader = Shader.new(_PACKAGE.."shaders/vertexBlur", _PACKAGE.."shaders/fragmentBlur", 0, desc[1], desc[2])
		self:initShadowShader(
			params.shadowLevel or shadowLevel,
			params.shadowAlpha or shadowAlpha,
			params.shadowOX or shadowOX,
			params.shadowOY or shadowOY
		)
	end
	
	if (params.blur) then 
		self.haveBlur = true
		self.blurShader = Shader.new(_PACKAGE.."shaders/vertexBlur",_PACKAGE.."shaders/fragmentBlur", 0, desc[1], desc[2])
		
		self:initBlurShader(params.blurLevel or blurLevel)
	end
	self:setAnchorPoint(self.ax, self.ay)
end
--
function GShape:initShadowShader(shadowLevel, shadowAlpha, shadowOX, shadowOY)		
	local dw = self.w * downSample
	local dh = self.h * downSample
	
	local dx = dw * falloff -- size of RT, that used for blur, it must be bigger than down sampled shape
	local dy = dh * falloff
	
	self.shadowShader:setConstant("fRad",Shader.CINT,1,shadowLevel)
	self.shadowShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{1/dx,1/dy})
	self.shadowShader:setConstant("fColorTransform",Shader.CFLOAT4,1,{0,0,0,shadowAlpha})
	
	local textureA = RenderTarget.new(dx,dy, true)
	local bufferA = Bitmap.new(textureA)
	local textureB = RenderTarget.new(dx,dy, true)
	self.shadow = Bitmap.new(textureB)	
	
	self.shape:setScale(downSample)
	self.shape:setFillColor(0,1)
	self.shape:setLineColor(0,1)
	--self.shape:setLineThickness(0,0)
	textureA:draw(self.shape,
		(dx - self.w*downSample)/2,
		(dy - self.h*downSample)/2
	)
	self:setStyle(self.style)
	self.shape:setScale(1)
	
	bufferA:setShader(self.shadowShader)
	self.shadowShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{1/dx,0})
	self.shadow:setShader(self.shadowShader)
	textureB:draw(bufferA)
	self.shadowShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{0,1/dy})
	self.shadow:setScale(1/downSample)
	self.shadow:setAnchorPosition(
		(dx - dw)/2 - shadowOX + dw * self.ax,
		(dy - dh)/2 - shadowOY + dh * self.ay
	)
	self.shadow.__dx = dx
	self.shadow.__dy = dy
	self.shadow.__dw = dw
	self.shadow.__dh = dh
	self.shadow.__shadowOX = shadowOX
	self.shadow.__shadowOY = shadowOY
	
	self:addChildAt(self.shadow, 1)
end
--
function GShape:initBlurShader(blurLevel)
	-- the idea absolutly same as shadowing (see "initShadowShader"), except
	-- wee need to draw the background that is overlaped by this shape somehow (see "renderBG")
	
	self.blurColor = {1,1,1,1}
	self.blurShader:setConstant("fRad",Shader.CINT,1,blurLevel)
	self.blurShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{1/self.w,1/self.h})
	self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,self.blurColor)
	
	-- setup buffer for vertical blur
	self.textureA = RenderTarget.new(self.w,self.h,false)
	self.bufferA = Bitmap.new(self.textureA)
	self.bufferA:setShader(self.blurShader)
	
	-- create texture for horizontal blur
	-- apply this texture to shape
	self.textureB = RenderTarget.new(self.w,self.h,true)
	
	self.shape:setTexture(self.textureB)
	self.shape:setShader(self.blurShader)
end
--------------------------------------------------------
---------------------- BLUR COLOR ----------------------
--------------------------------------------------------
function GShape:setBlurColor(r,g,b,a)
	if (self.haveBlur) then
		self.blurColor[1]=r
		self.blurColor[2]=g
		self.blurColor[3]=b
		self.blurColor[4]=a
		self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,self.blurColor)
	end
end
function GShape:setBlurR(r)
	if (self.haveBlur) then
		self.blurColor[1]=r
		self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,self.blurColor)
	end
end
function GShape:setBlurG(g)
	if (self.haveBlur) then
		self.blurColor[2]=g
		self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,self.blurColor)
	end
end
function GShape:setBlurB(b)
	if (self.haveBlur) then
		self.blurColor[3]=b
		self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,self.blurColor)
	end
end
function GShape:setBlurA(a)
	if (self.haveBlur) then
		self.blurColor[4]=a
		self.blurShader:setConstant("fColorTransform",Shader.CFLOAT4,1,self.blurColor)
	end
end
--------------------------------------------------------
--------------------------------------------------------
--------------------------------------------------------
function GShape:setStyle(style)
	local outline = style.outline
	self.shape:setFillColor(style.color, style.alpha)
	self.shape:setLineColor(outline.color, outline.alpha)
	self.shape:setLineThickness(outline.width, outline.feather)
	--self.shape:setAnchorPoint(self.ax, self.ay)
end
--
function GShape:renderBG()
	-- get object parent to find other childs that is above this object
	local par = self:getParent()
	if (not par) then print("Error rendering background, GShape dont have parent.") return end
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
	self.textureA:draw(stage, -self.drawX + self.w * self.ax, -self.drawY + self.h * self.ay)
	
	for i = ind, l do 
		local c = par:getChildAt(i)
		c:setVisible(true)
	end
end
--
function GShape:updateBlur()	
	if (self.haveBlur) then
		-- render shape 
		self:renderBG()	
		-- apply vertical blur
		self.blurShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{0,1/self.h})
		-- render verticaly blured shape
		self.textureB:draw(self.bufferA)
		-- apply horizontal blur
		self.blurShader:setConstant("fTexelSize",Shader.CFLOAT2,1,{1/self.w,0,})
	end
end
-- If GShape is a child of another object, call this to 
-- correctly blur background (if it is used)
function GShape:updateRelativeXY(x, y)
	self.drawX = x
	self.drawY = y
end
--
function GShape:updateRelativeX(x)
	self.drawX = x
end
--
function GShape:updateRelativeY(y)
	self.drawY = y
end
--------------------------------------------------------
--------------------- SHAPE FORMS ----------------------
--------------------------------------------------------
function GShape:circle(params, style)
	self.r = params.r
	local r = self.r
	self.w = r * 2
	self.h = self.w
	
	self.shape = Path2D.new()
	local ms="MAAZ"
	--local mp={-r,0, r,r,0,0,0,r,0, r,r,0,0,0,-r,0} -- anchor in center 
	local mp = {0,r, r,r,0,0,1,2*r,r, r,r,0,0,1,0,r} -- anchor in top left corner
	self.shape:setPath(ms,mp)
	
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
--
function GShape:setPosition(x, y)
	Sprite.setPosition(self, x, y)
	self.drawX = x
	self.drawY = y
	self:updateBlur()
end
--
function GShape:setX(x)
	Sprite.setX(self, x)
	self.drawX = x
	self:updateBlur()
end
--
function GShape:setY(y)
	Sprite.setY(self, y)
	self.drawY = y
	self:updateBlur()
end
--
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
	self.shape:setAnchorPosition(self.w * self.ax, self.h * self.ay)

	if (self.haveShadow) then 
		local s = self.shadow
		s:setAnchorPosition(
			(s.__dx - s.__dw)/2 - s.__shadowOX + s.__dw * self.ax,
			(s.__dy - s.__dh)/2 - s.__shadowOY + s.__dh * self.ay
		)
	end
end
