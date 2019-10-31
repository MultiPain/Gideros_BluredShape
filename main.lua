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
local default = {
	color = 0xf9f8f8, alpha = 0.2, 
	outline = {color = 0x454545, alpha = 0.5, width = 4, feather = .3}
}
local tex = Texture.new("bg2.jpg", true)
local bg = Bitmap.new(tex)
bg:setPosition(SCREEN.Left, SCREEN.Top)
bg:setScale(SCREEN.W / tex:getWidth(), SCREEN.H / tex:getHeight())
stage:addChild(bg)

sh1 = GShape.new({shape = {w = 720, h = 250, r1 = 64, r2 = 64},blur = true, shadow = true,}, default)
sh2 = GShape.new({name = "rect",shape = {w = 100, h = 100},blur = true, shadow = true,}, default)
sh3 = GShape.new({name = "circle",shape = {r = 100},blur = true, shadow = true,}, default)
sh4 = GShape.new({name = "rrect",shape = {w = 120, h = 320, r1 = 50, r3=40},blur = true,}, default)
sh5 = GShape.new({name = "circle",shape = {r = 100},blur = true, }, default)

sh1:setPosition(SCREEN.Center.x, SCREEN.Center.y)
sh2:setPosition(SCREEN.Center.x, SCREEN.Top)
sh3:setPosition(SCREEN.Center.x, SCREEN.Bottom)
sh4:setPosition(SCREEN.Left, SCREEN.Center.y)
sh5:setPosition(SCREEN.Right, SCREEN.Center.y)

local shapeRender = ShapeRender.new{sh1,sh2,sh3,sh4,sh5}
stage:addChild(shapeRender)
shapeRender:update()