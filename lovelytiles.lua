local lovelytiles = {
_VERSION = '0.1',
_DESCRIPTION = 'Tiled map importation in Löve2d',
_URL = 'https://github.com/sprvrn/lovely-tiles',
_LICENSE = [[
MIT License

Copyright (c) 2020 sprvrn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
}

local Object = require "classic"

local Map = Object:extend()
local Tileset = Object:extend()
local TilesetTile = Object:extend()
local Layer = Object:extend()
local Tile = Object:extend()

local lg,lf = love.graphics,love.filesystem

local ASSET_DIR = "assets"

local function clamp(val, lower, upper)
    return math.max(lower, math.min(upper, val))
end
local function contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end
local function colorconversion(color)
	for i=1,#color do
		color[i] = color[i] / 255
	end
	return color
end

function Map:__tostring()
	return "Map"
end

function Map:new(data, startx, starty, width, height, layers, initObj)
	if type(data) == "string" then
	    data = lf.load(data)()
	end

	assert(data)

	self.tilesets = {}

	self.startx = startx or 0
	self.starty = starty or 0

	for k,v in pairs(data) do
		if k == "tilesets" then
			for _,tileset in pairs(v) do
				table.insert(self.tilesets, Tileset(tileset))
			end
		elseif k ~= "layers" then
		    self[k] = v
		end
	end

	self.mapWidth = width or self.width
	self.mapHeight = height or self.height

	self.mapWidth = self.mapWidth + 1
	self.mapHeight = self.mapHeight + 1

	self.mapWidth = clamp(self.mapWidth,1,self.width)
	self.mapHeight = clamp(self.mapHeight,1,self.height)

	self.startx = clamp(self.startx,1,self.mapWidth)
	self.starty = clamp(self.starty,1,self.mapHeight)

	local layersTiles = {}
	for _,layer in pairs(data.layers) do

		layersTiles[layer.id] = {}

		for x=1,self.width do
			layersTiles[layer.id][x] = {}
			for y=1,self.height do
				layersTiles[layer.id][x][y] = nil
			end
		end
	
		local x,y = 1,1
		layer.data = layer.data or {}

		for k,tile in pairs(layer.data) do
			layersTiles[layer.id][x][y] = tile
			x = x + 1
			if x == self.width + 1 then
			    x = 1
			    y = y + 1
			end
		end
	end

	self.layers = {}

	for _,layerData in pairs(data.layers) do
		if (layers == nil or (type(layers))=="table" and #layers==0 ) or
		 	(type(layers) == "table" and contains(layers,layerData.name)) then
		    table.insert(self.layers, Layer(self,layerData,layersTiles[layerData.id],initObj))
		end
	end
	self.backgroundcolor = self.backgroundcolor or {255,255,255,255}
	self.backgroundcolor = colorconversion(self.backgroundcolor)
end

function Map:update(dt)
	for _,layer in pairs(self.layers) do
		layer:update(dt)
	end
end

function Map:draw()
	self:drawBackgroundColor()
	for _,layer in pairs(self.layers) do
		layer:draw()
	end
end

function Map:drawBackgroundColor()
	lg.setColor(self.backgroundcolor)
	local x,y = self:origin()
	love.graphics.rectangle("fill", x, y, self.tilewidth * self.mapWidth, self.tileheight * self.mapHeight)
	lg.setColor(1,1,1,1)
end

function Map:pixelToCoord( x,y )
	return math.floor( x/self.tilewidth ), math.floor( y/self.tileheight )
end

function Map:coordToPixel( x,y )
	return x*self.tilewidth , y*self.tileheight
end

function Map:origin()
	return -(self.startx - 1) * self.tilewidth, -(self.starty - 1) * self.tileheight
end

function Map:inMap(e)
	local mx1,my1 = self:coordToPixel(self.startx-1,self.starty-1)
	local mx2,my2 = mx1+self.width*self.tilewidth,my1+self.height*self.tileheight

	local ex1,ey1 = e.x,e.y
	local ex2,ey2 = ex1+e.width,ey1+e.height

	return mx1<ex2 and mx2>ex1 and my1<ey2 and my2>ey1
end

function Map:getObjectGroups()
	local t = {}
	for _,layer in pairs(self.layers) do
		if layer.type == "objectgroup" then
		    table.insert(t, layer)
		end
	end
	return t
end

function Tileset:__tostring()
	return "Tileset"
end

function Tileset:new(tilesetData)
	local tilesData = nil
	for k,v in pairs(tilesetData) do
		if k == "image" then
			local path = string.gsub(v, "%.%.", ASSET_DIR)
		    self.image = lg.newImage(path)
		elseif k == "tiles" then
		    tilesData = v
		else
			self[k] = v
		end
	end

	self.tiles = {}

	local gid = self.firstgid
	local tstileid = 0

	for y=0,(self.imageheight / self.tileheight) - 1 do
		for x=0,(self.imagewidth / self.tilewidth) - 1 do

			local tileData = self:getTileData(tilesData,tstileid)

			table.insert(self.tiles, gid, TilesetTile(gid,self,tileData,x,y,self.tilewidth,self.tileheight,self.imagewidth,self.imageheight))

			gid = gid + 1
			tstileid = tstileid + 1
		end
	end
end

function Tileset:getTileData(tiles,id)
	for _,tile in pairs(tiles) do
		if id == tile.id then
		    return tile
		end
	end
	return {}
end

function TilesetTile:__tostring()
	return "TilesetTile"
end

function TilesetTile:new(gid,tileset,tileData,x,y,tw,th,imgw,imgh)
	tileData = tileData or {}

	self.gid = gid
	self.tileset = tileset

	for k,v in pairs(tileData) do
		self[k] = v

		if k == "animation" then
		    for key,frame in pairs(v) do
		    	frame.tileid = frame.tileid + tileset.firstgid
		    	frame.duration = tonumber(frame.duration)
		    end
		end
	end

	self.quad = lg.newQuad( x*tw, y*th, tw, th, imgw, imgh )
end

function Layer:__tostring()
	return "Layer"
end

function Layer:new(map,layerData,tiles,initObj)

	self.map = map

	self.animated = {}

	if layerData~= nil and tiles ~= nil then
		for k,v in pairs(layerData) do
			self[k] = v
		end

		self.tintcolor = self.tintcolor or {255,255,255,255}

		self.tintcolor = colorconversion(self.tintcolor)

		self.batches = {}

		if self.type == "tilelayer" then
			self.tiles = {}

		    for x=map.startx,map.startx+map.mapWidth - 1 do
				self.tiles[x] = {}
				for y=map.starty,map.starty+map.mapHeight - 1 do
					self.tiles[x][y] = nil
				end
			end

			for k,v in pairs(layerData) do
				if k == "data" then
				    for x=map.startx,map.startx+map.mapWidth - 1 do
						for y=map.starty,map.starty+map.mapHeight - 1 do
							if x <= map.width and y <= map.height then
							    self.tiles[x][y] = Tile(self,tiles[x][y],x,y)
							end
						end
					end
				else
				    self[k] = v
				end
			end
			self:setBatches()

		elseif self.type == "objectgroup" then
		    local temp = self.objects
		    self.objects = {}

		    for _,obj in pairs(temp) do
		    	if map:inMap(obj) then
		    	    table.insert(self.objects, obj)

		    	    if type(initObj) == "table" then
		    	    	for _,v in pairs(initObj) do
		    	    		if v.type == obj.type then
		    	    		    v.call(obj, obj.x, obj.y, map, self)
		    	    		end
		    	    	end
		    	    end
		    	end
		    end
		elseif self.type == "imagelayer" then
			local path = string.gsub(self.image, "%.%.", ASSET_DIR)
		    self.image = lg.newImage(path)
		    self.imagepath = path
		end
	end
end

function Layer:setBatches()
	if self.type == "tilelayer" then
	    for x,t in pairs(self.tiles) do
	    	for y,tile in pairs(t) do
	    		if tile.gid ~= 0 and not tile.tileset.properties.hidden and not tile:hidden() then
	    		    local tid = tile.tileset.name
	    			self.batches[tid] = self.batches[tid] or lg.newSpriteBatch(tile.tileset.image)
	    			tile.batchTileId = self.batches[tid]:add(tile.data.quad,(x-1)*tile.tileset.tilewidth,(y-1)*tile.tileset.tileheight)
	    		end
	    	end
	    end
	end
end

function Layer:draw()
	if self.visible then
		lg.setColor(self.tintcolor)
		local layerx, layery = self.map:origin()
		layerx = layerx + self.offsetx
	    layery = layery + self.offsety
	    for _,batch in pairs(self.batches) do
	    	lg.draw(batch, layerx, layery)
	    end
	    if self.image then
	        lg.draw(self.image, layerx, layery)
	    end
	    lg.setColor(1,1,1,1)
	end
end

function Layer:update(dt)
	for _,tile in pairs(self.animated) do
		tile:update(dt)
	end
end

function Layer:removeTile(x,y)
	local t = self.tiles[x][y]
	self.batches[t.tileset.name]:set(t.batchTileId,0,0,0,0,0)

	t = nil
end

function Tile:__tostring()
	return "Tile"
end

function Tile:new(layer,gid,x,y)
	self.layer = layer

	self.gid = gid

	self.x,self.y = x,y

	self.tileset,self.data = self:getTileInfo()

	if self.data then
	    self.properties = self.data.properties
	end

	if self.data and self.data.animation then
		self.animation = self.data.animation
	    self.frame = 1
		self.time = 0

		table.insert(self.layer.animated, self)
	end
end

function Tile:update(dt)
	if self.animation and self.layer.batches then
	    self.time = self.time + dt * 1000

	    if self.time >= self.animation[self.frame].duration then
	        self.time = 0
	        self.frame = self.frame + 1

	        if self.frame > #self.animation then
	        	self.frame = 1
	        end

	        local t = self.tileset.tiles[self.animation[self.frame].tileid]

	        if self.layer.batches[self.tileset.name] then
	            self.layer.batches[self.tileset.name]:set(
	        	self.batchTileId,
		        	t.quad,
		        	(self.x-1)*self.tileset.tilewidth,
		        	(self.y-1)*self.tileset.tileheight
		        )
	        end
	    end
	end
end

function Tile:getTileInfo()
	for _,tileset in pairs(self.layer.map.tilesets) do
		if self.gid >= tileset.firstgid then
		    for _,tile in pairs(tileset.tiles) do
		    	if tile.gid == self.gid then
		    	    return tileset,tile
		    	end
		    end
		end
	end
end

function Tile:hidden()
	if self.data and self.data.properties then
	    return self.data.properties.hidden
	end
end

function lovelytiles.new(...)
	return Map(...)
end

return lovelytiles