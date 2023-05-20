# Gideros GShape
A class for Gideros that allows you to create nice blured shapes with shadows

# Preview
![alt text]([[https://github.com/MultiPain/Gideros_BluredShape/blob/master/assets/Preview.jpg](123))

# Example

```lua
app @ application
local dx = app:getLogicalTranslateX() / app:getLogicalScaleX()
local dy = app:getLogicalTranslateY() / app:getLogicalScaleY()
local w = app:getContentWidth()
local h = app:getContentHeight()

SCREEN = {
	Left = -dx, Top = -dy,
	Right = w + dx, Bottom = h + dy,
	W = dx*2 + w,
	H = dy*2 + h,
	Center = {x = w / 2, y = h / 2}
}

-------------------------------------------------------------
-- You need to have a background to use GShape Blur effect --
-------------------------------------------------------------
local bgTex = RenderTarget.new(SCREEN.W, SCREEN.H)
bgTex:clear(app:getBackgroundColor(), 1)
local bg = Bitmap.new(bgTex)
bg:setPosition(SCREEN.Left, SCREEN.Top)
stage:addChild(bg)
-- Since we covering whole screen with solid color, we can 
-- disable background color draw call for better performance
stage:setClearColorBuffer(false)
-------------------------------------------------------------
-------------------------------------------------------------

local style = {
	color = 0xf9f8f8, alpha = 0.2, 
	outline = {color = 0x454545, alpha = 0.5, width = 4, feather = .3}
}
sh1 = GShape.new({name = "rrect", shape = {w = 720, h = 250, r1 = 64, r2 = 64},blur = true, shadow = true,}, style)
sh2 = GShape.new({name = "circle",shape = {r = 100},blur = true, }, style)
sh3 = GShape.new({name = "rect",shape = {w = 120, h = 320},}, style)

stage:addChild(sh1)
stage:addChild(sh2)
stage:addChild(sh3)

-- Blur needs to updated after shape is added to stage
sh1:updateBlur()
sh2:updateBlur()
sh3:updateBlur()
```
# GShape constructor arguments

To create this window use GShape class. 

```lua
GShape.new(params, style)

params (table):
		name (string): circle, rect or rrect [optional, default "rrect"]
		shape (table) - params for shape
			w (number): width of the shape (for "rect" and "rrect")
			h (number): height of the shape (for "rect" and "rrect")
			r (number): radius of the shape (for "rrect" - corner radius, for "circle" - circle radius) [optional, default 12]
			r1 (number): radius of the top left corner (for "rrect" only) [optional, default 0]
			r2 (number): radius of the top right corner (for "rrect" only) [optional, default 0]
			r3 (number): radius of the bottom left corner (for "rrect" only) [optional, default 0]
			r4 (number): radius of the bottom right corner (for "rrect" only) [optional, default 0]
		ax (number): anchor x [optional, default 0.5]
		ay (number): anchor y [optional, default 0.5]
		blur (bool): enable bg blur [optional, default false]
		blurLevel (number): amount of blur [optional, default 1]
		shadow (bool): enable shadow drop [optional, default false]
		shadowLevel (number): amount of shadow [optional, default 0.5]
		shadowAlpha (number): shadow alpha [optional, default 0.5]
		shadowOX (number): shadow x offset [optional, default 2]
		shadowOY (number): shadow y offset [optional, default 2]
style (table):
		color (color): shape fill color
		alpha (number): shape alpha value
		outline (table):
			color (color): shape outline color
			alpha (number): shape outline alpha
			width (number): shape outline width
			feather (number): shape outline feather
```
