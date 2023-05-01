-- Mostly by Dark-Assassin

local quotepattern = '([' .. ("%^$().[]*+-?"):gsub("(.)", "%%%1") .. '])'
string.quote = function(str)
	return str:gsub(quotepattern, "%%%1")
end

string.clean = function(str)
	str = string.gsub(str, '\r*\n%s*', '\r\n')
	str = string.gsub(str, '%s*\r*\n', '\r\n')
	str = string.gsub(str, '^%s*(.-)%s*$', '%1')
	str = string.gsub(str, '\t', '    ')
	str = string.gsub(str, ' +', ' ')
	return str
end

string.pad = function(str, pad)
	str = string.gsub(str, '^', pad)
	str = string.gsub(str, "\n", "\n" .. pad)
	return str
end

local separator = function(length, char)
	if (length == nil) then
		length = 128
	end
	if (char == nil) then
		char = "="
	end
	return string.rep(char, length)
end

local header = function(text, length, char)
	if (length == nil) then
		length = 128
	end
	if (char == nil) then
		char = "="
	end
	text = string.rep(char, 2) .. " " .. text .. " " .. string.rep(char, 2)
	return text .. string.rep(char, length - string.len(text))
end

script = {
	prepend = function(code, insert_before, file, output)
		if (output == nil) then
			output = file
		end
		local matched = false
		code = tostring(code)
		insert_before = tostring(insert_before)
		file = tostring(file)
		if (code ~= nil) then
			if (insert_before ~= nil) then
				if (file ~= nil) then
					local script = ModTextFileGetContent(file)
					if (script ~= nil) then
						local oinsert_before = insert_before
						local ocode = code
						script = string.clean(script)
						insert_before = string.clean(insert_before)
						code = string.clean(code)
						local content = ""
						local i, j = string.find(script, string.quote(insert_before))
						if (i ~= nil and j ~= nil) then
							content = string.gsub(script, string.quote(insert_before), code .. "\n" .. insert_before)
							matched = true
						else
							print("\n" .. header("Error: Unable to find in " .. file) .. "\n" .. string.pad(oinsert_before, "| ") .. "\n" .. separator())
						end
						if (matched) then
							ModTextFileSetContent(output, content)
							print("\n" .. header("Inserted in " .. file) .. "\n" .. string.pad(ocode, "| ") .. "\n" .. header("Before") .. "\n" .. string.pad(oinsert_before, "| ") .. "\n" .. separator())
						end
					else
						error("Error: Unable to find file " .. file .. " for script.prepend!")
					end
				else
					error("Error: No file defined for script.prepend!")
				end
			else
				error("Error: No insertbefore line defined for script.prepend!")
			end
		else
			error("Error: No code defined for script.prepend!")
		end
	end,
	append = function(code, insert_after, file, output)
		if (output == nil) then
			output = file
		end
		local matched = false
		code = tostring(code)
		insert_after = tostring(insert_after)
		file = tostring(file)
		if (code ~= nil) then
			if (insert_after ~= nil) then
				if (file ~= nil) then
					local script = ModTextFileGetContent(file)
					if (script ~= nil) then
						local oinsert_after = insert_after
						local ocode = code
						script = string.clean(script)
						insert_after = string.clean(insert_after)
						code = string.clean(code)
						local content = ""
						local i, j = string.find(script, string.quote(insert_after))
						if (i ~= nil and j ~= nil) then
							content = string.gsub(script, string.quote(insert_after), insert_after .. "\n" .. code)
							matched = true
						else
							print("\n" .. header("Error: Unable to find in " .. file) .. "\n" .. string.pad(oinsert_after, "| ") .. "\n" .. separator())
						end
						if (matched) then
							ModTextFileSetContent(output, content)
							print("\n" .. header("Inserted in " .. file) .. "\n" .. string.pad(ocode, "| ") .. "\n" .. header("After") .. "\n" .. string.pad(oinsert_after, "| ") .. "\n" .. separator())
						end
					else
						error("Error: Unable to find file " .. file .. " for script.append!")
					end
				else
					error("Error: No file defined for script.append!")
				end
			else
				error("Error: No insertafterline defined for script.append!")
			end
		else
			error("Error: No code defined for script.append!")
		end
	end,
	replace = function(code, replace, file, output)
		if (output == nil) then
			output = file
		end
		local matched = false
		code = tostring(code)
		replace = tostring(replace)
		file = tostring(file)
		if (replace ~= nil) then
			if (file ~= nil) then
				local script = ModTextFileGetContent(file)
				if (script ~= nil) then
					local oreplace = replace
					local ocode = code
					script = string.clean(script)
					replace = string.clean(replace)
					code = string.clean(code)
					local content = ""
					local i, j = string.find(script, string.quote(replace))
					if (i ~= nil and j ~= nil) then
						content = string.gsub(script, string.quote(replace), code)
						matched = true
					else
						print("\n" .. header("Error: Unable to find in " .. file) .. "\n" .. string.pad(oreplace, "| ") .. "\n" .. separator())
					end
					if (matched) then
						ModTextFileSetContent(output, content)
						print("\n" .. header("Replaced in " .. file) .. "\n" .. string.pad(oreplace, "| ") .. "\n" .. header("With") .. "\n" .. string.pad(ocode, "| ") .. "\n" .. separator())
					end
				else
					error("Error: Unable to find file " .. file .. " for script.replace!")
				end
			else
				error("Error: No file defined for script.replace!")
			end
		else
			error("Error: No replace line defined script.replace!")
		end
	end,
	dump = function(file)
		file = tostring(file)
		if (file == nil) then
			print("Error: No file defined script.dump!")
		else
			local script = ModTextFileGetContent(file)
			print("\n" .. header("File Dump for " .. file) .. "\n" .. script .. "\n" .. separator())
		end
	end
}
