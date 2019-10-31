ShapeRender = Core.class(Sprite)

function ShapeRender:init(shapes)
	for k,v in ipairs(shapes) do 
		self:addChild(v)
	end
	
	self.dx = 0
	self.dy = 0
	self.drag = false
	self.dragID = -1
	self.current = nil
	
	self:addEventListener(Event.TOUCHES_END, self.dragEnd, self)
	self:addEventListener(Event.TOUCHES_MOVE, self.dragMove, self)
	self:addEventListener(Event.TOUCHES_BEGIN, self.dragStart, self)
end
--
function ShapeRender:update()
	local l   = self:getNumChildren()
	for i = 1,l do 
		local c = self:getChildAt(i)
		c:updateBlur()
		c:setVisible(true)
	end
end
--
function ShapeRender:getTop()
	local l = self:getNumChildren()
	return self:getChildAt(l)
end
--
function ShapeRender:pushToTop(shape)
	return self:addChild(shape)
end
--
function ShapeRender:pushToBottom(shape)
	return self:addChild(shape, 1)
end
--
function ShapeRender:getByIndex(ind)
	return self:getChildAt(ind)
end
--
function ShapeRender:dragStart(e)
	if (self.dragID == -1) then
		local x,y = e.touch.x, e.touch.y
		self.current = nil
		
		local l   = self:getNumChildren()
		for i = l,1,-1 do 
			local c = self:getChildAt(i)
			if (c:hitTestPoint(x, y)) then
				self.current = c
				e:stopPropagation()
				break
			end
		end
		
		if (self.current) then 
			self.dragID = e.touch.id
			self.drag = true
			local cx,cy = self.current:getPosition()
			self:addChild(self.current) -- push to top
			self:update()
			
			self.dx = cx - x
			self.dy = cy - y
		end
	end
end
--
function ShapeRender:dragEnd(e)
	if (self.drag) then 
		self.drag = false
		self.dragID = -1
	end
end
--
function ShapeRender:dragMove(e)
	local x,y = e.touch.x, e.touch.y
	if (self.drag and e.touch.id == self.dragID) then 
		self.current:setPosition(x+self.dx,y+self.dy)
		self:update()
	end
end