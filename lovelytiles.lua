local lovelytiles = {
_VERSION = '0.5',
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

local Map = {}
Map.__index = Map

local Tileset = {}
Tileset.__index = Tileset

local TilesetTile = {}
TilesetTile.__index = TilesetTile

local Layer = {}
Layer.__index = Layer

local Tile = {}
Tile.__index = Tile

local Object = {}
Object.__index = Object

local lg,lf = love.graphics,love.filesystem

local dir = (...):gsub('%.lovelytiles$', '')

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
local function strsplit(str, sep)
	local t={}
	local m = string.gmatch(str, "([^"..sep.."]+)")
	for s in m do
		table.insert(t, s)
	end
	return t
end
local function colorconversion(color)
	for i=1,#color do
		color[i] = color[i] / 255
	end
	return color
end
local function pathnormalize(path)
	local p = strsplit(path,"/")
	local temp = strsplit(path,"/")
	for i=1,#p do
		if p[i] == ".." then
			table.remove(temp,i)
			if i > 1 then
				table.remove(temp,i-1)
			end
		end
	end
	local s,n = "",""
	for i=1,#temp do
		s = s..n..temp[i]
		n = "/"
	end
	return s
end

local orientation = {
	orthogonal = function(x, y, maptilewidth, maptileheight, tileheight)
		local oy = 0

		if tileheight > maptileheight then
			oy = -(tileheight / 2)
		elseif tileheight < maptileheight then
			oy = (tileheight / 2)
		end

		return (x - 1) * maptilewidth, (y - 1) * maptileheight + oy
	end,
	isometric = function(x, y, tilewidth, tileheight)
		return (x - y) * (tilewidth / 2), (x + y) * (tileheight / 2)
	end
}

function Map:__tostring()
	return "Map"
end

function Map.new(data, startx, starty, width, height, layers, initObj)
	assert(data)
	local mapdir = ""
	if type(data) == "string" then
		local path = data
		data = lf.load(data)()

		local m = path:reverse():find("[/\\]") or ""
		if m ~= "" then
			m = path:sub(1, 1 + (#path - m))
		end

		mapdir = m
	end

	local map = {}
	setmetatable(map, Map)

	map.tilesets = {}

	map.dir = mapdir

	map.startx = startx or 0
	map.starty = starty or 0

	for k,v in pairs(data) do
		if k == "tilesets" then
			for _,tileset in pairs(v) do
				table.insert(map.tilesets, Tileset.new(tileset,map.dir))
			end
		elseif k ~= "layers" then
			map[k] = v
		end
	end

	map.mapWidth = width or map.width
	map.mapHeight = height or map.height

	map.mapWidth = clamp(map.mapWidth,1,map.width)
	map.mapHeight = clamp(map.mapHeight,1,map.height)

	map.startx = clamp(map.startx,1,map.width)
	map.starty = clamp(map.starty,1,map.height)

	local layersTiles = {}
	for _,layer in pairs(data.layers) do

		layersTiles[layer.id] = {}

		for x=1,map.width do
			layersTiles[layer.id][x] = {}
			for y=1,map.height do
				layersTiles[layer.id][x][y] = nil
			end
		end
	
		local x,y = 1,1
		layer.data = layer.data or {}

		for k,tile in pairs(layer.data) do
			layersTiles[layer.id][x][y] = tile
			x = x + 1
			if x == map.width + 1 then
				x = 1
				y = y + 1
			end
		end
	end

	map.layers = {}

	for _,layerData in pairs(data.layers) do
		if (layers == nil or (type(layers))=="table" and #layers==0) or
			(type(layers) == "table" and contains(layers,layerData.name)) then
			table.insert(map.layers, Layer.new(map,layerData,layersTiles[layerData.id],initObj))
		end
	end

	if map.backgroundcolor then
	    map.backgroundcolor = colorconversion(map.backgroundcolor)
	end
	
	return map
end

function Map:update(dt)
	for _,layer in ipairs(self.layers) do
		layer:update(dt)
	end
end

function Map:draw(x, y, r, sx, sy, ox, oy, kx, ky)
	x = x or 0
	y = y or 0
	r = r or 0
	sx = sx or 1
	sy = sy or 1
	ox = ox or 0
	oy = oy or 0
	kx = kx or 0
	ky = ky or 0
	self:drawBackgroundColor(x, y, sx, sy)
	for _,layer in ipairs(self.layers) do
		layer:draw(x, y, r, sx, sy, ox, oy, kx, ky)
	end
end

function Map:drawBackgroundColor(x, y, sx, sy)
	if not self.backgroundcolor then
	    return
	end
	lg.setColor(self.backgroundcolor)
	lg.rectangle("fill", x, y, self.tilewidth * self.mapWidth * sx, self.tileheight * self.mapHeight * sy)
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
	local mx2,my2 = mx1+(self.mapWidth * self.tilewidth),my1+(self.mapHeight * self.tileheight)

	local ex1,ey1 = e.x,e.y
	local ex2,ey2 = ex1+e.width,ey1+e.height

	return mx1 < ex2 and mx2 > ex1 and my1 < ey2 and my2 > ey1
end

function Map:getObjectGroups()
	local t = {}
	for _,layer in ipairs(self.layers) do
		if layer.type == "objectgroup" then
			table.insert(t, layer)
		end
	end
	return t
end

function Map:getLayer(layerName)
	for _,layer in ipairs(self.layers) do
		if layer.name == layerName then
			return layer
		end
	end
end

function Map:getTileset(tilesetName)
	for _,tileset in ipairs(self.tilesets) do
		if tileset.name == tilesetName then
			return tileset
		end
	end
end

function Map:foreach(t, call)
	assert(t=="layer" or t=="tile" or "object", "#1 type must be 'layer', 'tile' or 'object")
	assert(type(call) == "function", "#2 must be a function")

	if t == "layer" then
	    for _,layer in ipairs(self.layers) do
	    	call(self,layer)
	    end
	end

	if t == "tile" then
		for _,layer in ipairs(self.layers) do
			if layer.tiles then
			    for x,t in pairs(layer.tiles) do
		    		for y,tile in pairs(t) do
		    			if tile.tileset then
		    			    call(self,layer,tile,(x-1)*self.tilewidth,(y-1)*self.tileheight)
		    			end
			    	end
			    end
			end
		end
	end

	if t == "object" then
		for _,layer in ipairs(self.layers) do
			if layer.type == "objectgroup" then
				for _,obj in pairs(layer.objects) do
					call(self,layer,obj)
				end
			end
		end
	end
end

function Map:getTilesetTile(gid)
	for i=1,#self.tilesets do
		local tileset = self.tilesets[i]
		if gid >= tileset.firstgid then
			for _,tile in pairs(tileset.tiles) do
				if tile.gid == gid then
					return tile
				end
			end
		end
	end
end

function Tileset:__tostring()
	return "Tileset"
end

function Tileset.new(tilesetData,mapdir)
	local tileset = {}
	setmetatable(tileset, Tileset)

	local tilesData = nil

	for k,v in pairs(tilesetData) do
		if k == "image" then
			local path = pathnormalize(mapdir..v)
			tileset.image = lg.newImage(path)
		elseif k == "tiles" then
			tilesData = v
		else
			tileset[k] = v
		end
	end

	tileset.tiles = {}

	local gid = tileset.firstgid
	local tstileid = 0

	for y=0,(tileset.imageheight / tileset.tileheight) - 1 do
		for x=0,(tileset.imagewidth / tileset.tilewidth) - 1 do

			local tileData = tileset:getTileData(tilesData,tstileid)

			table.insert(tileset.tiles, gid, TilesetTile.new(gid,tileset,tileData,x,y,tileset.tilewidth,tileset.tileheight,tileset.imagewidth,tileset.imageheight))

			gid = gid + 1
			tstileid = tstileid + 1
		end
	end
	
	return tileset
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

function TilesetTile.new(gid,tileset,tileData,x,y,tw,th,imgw,imgh)
	local tilesettile = {}
	setmetatable(tilesettile, TilesetTile)
	
	tileData = tileData or {}

	tilesettile.gid = gid
	tilesettile.tileset = tileset

	tilesettile.x = x
	tilesettile.y = y

	for k,v in pairs(tileData) do
		tilesettile[k] = v

		if k == "animation" then
			for key,frame in pairs(v) do
				frame.tileid = frame.tileid + tileset.firstgid
				frame.duration = tonumber(frame.duration)
			end
		end
	end

	tilesettile.properties = tilesettile.properties or {}

	tilesettile.quad = lg.newQuad(tileset.margin + (x * tileset.spacing) + (x * tw), tileset.margin + (y * tileset.spacing) + (y * th), tw, th, imgw, imgh)

	return tilesettile
end

function Layer:__tostring()
	return "Layer"
end

function Layer.new(map,layerData,tiles,initObj)
	local layer = {}
	setmetatable(layer, Layer)

	layer.map = map

	layer.animated = {}

	if layerData~= nil and tiles ~= nil then
		for k,v in pairs(layerData) do
			layer[k] = v
		end

		layer.tintcolor = layer.tintcolor or {255,255,255,255}

		layer.tintcolor = colorconversion(layer.tintcolor)

		layer.batches = {}

		if layer.type == "tilelayer" then
			layer.tiles = {}

			for x=map.startx,map.startx+map.mapWidth - 1 do
				layer.tiles[x] = {}
				for y=map.starty,map.starty+map.mapHeight - 1 do
					layer.tiles[x][y] = nil
				end
			end

			for k,v in pairs(layerData) do
				if k == "data" then
					for x=map.startx,map.startx+map.mapWidth - 1 do
						for y=map.starty,map.starty+map.mapHeight - 1 do
							if x <= map.width and y <= map.height then
								layer.tiles[x][y] = Tile.new(layer,tiles[x][y],x,y)
							end
						end
					end
				else
					layer[k] = v
				end
			end
			layer:setBatches()

		elseif layer.type == "objectgroup" then
			local temp = layer.objects
			layer.objects = {}

			for _,obj in pairs(temp) do
				if map:inMap(obj) then
					table.insert(layer.objects, Object.new(obj, layer))

					if type(initObj) == "table" then
						for _,v in pairs(initObj) do
							if v.type == obj.type then
								v.call(obj, map, layer)
							end
						end
					end
				end
			end
		elseif layer.type == "imagelayer" and layer.image ~= "" then
			local path = pathnormalize(map.dir..layer.image)
			layer.image = lg.newImage(path)
			layer.imagepath = path
		end

		layer.width = map.mapWidth
		layer.height = map.mapHeight
	end

	return layer
end

function Layer:setBatches()
	if self.type == "tilelayer" then
		for x,t in pairs(self.tiles) do
			for y,tile in pairs(t) do
				if tile.gid ~= 0 and not tile.tileset.properties.hidden and not tile:hidden() then
					local tid = tile.tileset.name
					local tilesetoffset = tile.tileset.tileoffset
					local tilex, tiley = orientation[self.map.orientation](x,y,self.map.tilewidth,self.map.tileheight,tile.tileset.tileheight)
					tilex, tiley = tilex + tilesetoffset.x, tiley + tilesetoffset.y
					self.batches[tid] = self.batches[tid] or lg.newSpriteBatch(tile.tileset.image)
					tile.batchTileId = self.batches[tid]:add(tile.data.quad,tilex,tiley)
				end
			end
		end
	end
end

function Layer:draw(x, y, r, sx, sy, ox, oy, kx, ky)
	if self.visible and not self.properties.hidden then
		x = x or 0
		y = y or 0

		lg.setColor(self.tintcolor)
		local layerx, layery = self.map:origin()
		layerx = layerx + self.offsetx + x
		layery = layery + self.offsety + y
		for _,batch in pairs(self.batches) do
			lg.draw(batch, layerx, layery, r, sx, sy, ox, oy, kx, ky)
		end
		if self.image and type(self.image) ~= "string" then
			lg.draw(self.image, layerx, layery)
		end
		lg.setColor(1,1,1,1)
	end
end

function Layer:update(dt)
	for i=1,#self.animated do
		local tile = self.animated[i]
		tile:update(dt)
	end
end

function Layer:getTile(x,y)
	if self.tiles[x] and self.tiles[x][y] then
		return self.tiles[x][y]
	end
end

function Layer:removeTile(x,y)
	local t = self.tiles[x][y]
	t:remove()
end

function Tile:__tostring()
	return "Tile"
end

function Tile.new(layer,gid,x,y)
	local tile = {}
	setmetatable(tile, Tile)

	tile.layer = layer

	tile.gid = gid

	tile.x,tile.y = x,y

	tile.tileset,tile.data = tile:getTileInfo()

	if tile.data then
		tile.properties = tile.data.properties or {}
		tile.type = tile.data.type
		tile.objectGroup = tile.data.objectGroup
	end

	if tile.data and tile.data.animation then
		tile.animation = tile.data.animation
		tile.frame = 1
		tile.time = 0

		table.insert(tile.layer.animated, tile)
	end

	return tile
end

function Tile:update(dt)
	if not self:hidden() and self.animation and self.layer.batches then
		self.time = self.time + dt * 1000

		if self.time >= self.animation[self.frame].duration then
			self.time = 0
			self.frame = self.frame + 1

			if self.frame > #self.animation then
				self.frame = 1
			end

			local t = self.tileset.tiles[self.animation[self.frame].tileid]

			local tilesetoffset = self.tileset.tileoffset
			local tilex, tiley = orientation[self.layer.map.orientation](self.x,self.y,self.layer.map.tilewidth,self.layer.map.tileheight,self.tileset.tileheight)
			tilex, tiley = tilex + tilesetoffset.x, tiley + tilesetoffset.y

			if self.layer.batches[self.tileset.name] then
				self.layer.batches[self.tileset.name]:set(self.batchTileId,t.quad,tilex,tiley)
			end
		end
	end
end

function Tile:getTileInfo()
	for i=1,#self.layer.map.tilesets do
		local tileset = self.layer.map.tilesets[i]
		if self.gid >= tileset.firstgid then
			for _,tile in pairs(tileset.tiles) do
				if tile.gid == self.gid then
					return tileset,tile
				end
			end
		end
	end
end

function Tile:remove()
	self.layer.batches[self.tileset.name]:set(self.batchTileId,0,0,0,0,0)
end

function Tile:hidden()
	if self.data and self.data.properties then
		return self.data.properties.hidden
	end
end

function Object:__tostring()
	return "Object"
end

function Object.new(obj, layer)
	local object = {}
	setmetatable(object, Object)

	for k,v in pairs(obj) do
		object[k] = v
	end

	object.layer = layer

	if object.shape == "polygon" then
		local temp = {}

		for _,point in pairs(object.polygon) do
			table.insert(temp, point.x + object.x)
			table.insert(temp, point.y + object.y)
		end
		object.polygon = temp
		
	elseif object.shape == "ellipse" then
		object.width = object.width / 2
		object.height = object.height / 2
		object.x = object.x + object.width
		object.y = object.y + object.height
	end

	if object.gid then
		object.tile = object.layer.map:getTilesetTile(object.gid)
	end

	return object
end

function Object:getDrawArguments(mode)
	mode = mode or "fill"

	if self.shape == "point" then
		return self.x, self.y
	elseif self.shape == "rectangle" then
		return mode, self.x, self.y, self.width, self.height
	elseif self.shape == "ellipse" then
		return mode, self.x, self.y, self.width, self.height
	elseif self.shape == "polygon" then
		return mode, unpack(self.polygon)
	elseif self.shape == "text" then
		return self.text, self.x, self.y
	end
end

function lovelytiles.new(...)
	return Map.new(...)
end

return lovelytiles