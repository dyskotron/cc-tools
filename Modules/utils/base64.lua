-- Base64 encoding/decoding in ComputerCraft
-- By Anavrins
-- For help and details, you can DM me on Discord (Anavrins#4600)
-- MIT License
-- Pastebin: https://pastebin.com/TEtna4tX
-- Last updated: Nov 4 2021

local base64 = {}
local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
local charAt, indexOf = {}, {}

local blshift = bit32 and bit32.lshift or bit.blshift
local brshift = bit32 and bit32.rshift or bit.brshift
local band = bit32 and bit32.band or bit.band
local bor = bit32 and bit32.bor or bit.bor

for i = 1, #base64chars do
	local char = base64chars:sub(i,i)
	charAt[i-1] = char
	indexOf[char] = i-1
end

function base64.encode(data)
	local data = type(data) == "table" and data or {tostring(data):byte(1,-1)}

	local out = {}
	local b
	for i = 1, #data, 3 do
		b = brshift(band(data[i], 0xFC), 2) -- 11111100
		out[#out+1] = charAt[b]
		b = blshift(band(data[i], 0x03), 4) -- 00000011
		if i+0 < #data then
			b = bor(b, brshift(band(data[i+1], 0xF0), 4)) -- 11110000
			out[#out+1] = charAt[b]
			b = blshift(band(data[i+1], 0x0F), 2) -- 00001111
			if i+1 < #data then
				b = bor(b, brshift(band(data[i+2], 0xC0), 6)) -- 11000000
				out[#out+1] = charAt[b]
				b = band(data[i+2], 0x3F) -- 00111111
				out[#out+1] = charAt[b]
			else out[#out+1] = charAt[b].."="
			end
		else out[#out+1] = charAt[b].."=="
		end
	end
	return table.concat(out)
end

function base64.decode(data)
--	if #data%4 ~= 0 then error("Invalid base64 data", 2) end

	local decoded = {}
	local inChars = {}
	for char in data:gmatch(".") do
		inChars[#inChars+1] = char
	end
	for i = 1, #inChars, 4 do
		local b = {indexOf[inChars[i]],indexOf[inChars[i+1]],indexOf[inChars[i+2]],indexOf[inChars[i+3]]}
		decoded[#decoded+1] = bor(blshift(b[1], 2), brshift(b[2], 4))%256
		if b[3] < 64 then decoded[#decoded+1] = bor(blshift(b[2], 4), brshift(b[3], 2))%256
			if b[4] < 64 then decoded[#decoded+1] = bor(blshift(b[3], 6), b[4])%256 end
		end
	end
	return decoded
end

return base64