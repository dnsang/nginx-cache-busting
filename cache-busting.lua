

-- feed external resource data (eg: js or css)
local function fetch_external_data(request_uri,num_retries)
	ngx.log(ngx.INFO," start fetch " .. request_uri)	
	local http = require "resty.http"
	local httpc = http.new()
	httpc:set_timeout(1000)
	local res, err = nil
	while(num_retries > 0 and res == nil)
	do
		ngx.log(ngx.INFO, "try " .. num_retries)
		res, err = httpc:request_uri(request_uri, {
		    method = "GET",   
		    headers = {
		    	["scheme"] = "http",
		    	["accept"] = "*/*",
		    	-- ["accept-encoding"] = "gzip",
		    	["cache-control"] = "no-cache",
		    	["pragma"] = "no-cache",
			} ,            
		})
		num_retries = num_retries - 1 
		ngx.log(ngx.INFO, "Num Retries: " .. num_retries)
		ngx.log(ngx.INFO, "Res is nill " .. string.format("%s",res == nil))
	end

	http:close()

	if res == nil then 
		return nil
	end
	return res.body
end

local function get_uri()
	local request_uri = string.sub(ngx.var.request_uri,2)
	
	local url_pattern = "(https?://.+)"
	local version_pattern = "(_[%d]+)%."
	local url = request_uri:match(url_pattern)
	if url == nil then 
		return nil 
	end
	local version = url:match(version_pattern)
	
	if version == nil then
		return url
	else
		return string.gsub(url,url:match(version_pattern),"")
	end
end




local function process(cache_name)	
	local uri = get_uri()
	local num_retries = 3
	local expire_in_second = 60*5
	if uri == nill then		
		ngx.exit(404)		
	else
		local data = ngx.shared[cache_name]:get(uri)
		local is_hit_cache = true
		-- ensure data
		if data == nill then 
			local fetch_data = fetch_external_data(uri,num_retries)		
			if fetch_data == nil then
				ngx.exit(404)
			end
			ngx.shared[cache_name]:set(uri,fetch_data,expire_in_second)	
			data = fetch_data
			is_hit_cache = false
		end
		ngx.header["Hit"] =string.format("%s",is_hit_cache)
		ngx.header["Source"] = uri
		ngx.say(data)
		
	end
end

return process