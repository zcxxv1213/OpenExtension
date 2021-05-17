local json = require 'cjson'
--local bjson = BestHTTP.JSON.Json
local jsonSplit = JsonSplit;
local GameObject = UnityEngine.GameObject
--local WebRequest = UnityEngine.Networking.UnityWebRequest;
--local TextureRequest = UnityEngine.Networking.UnityWebRequestTexture;
local mHTTPRequest = BestHTTP.HTTPRequest;
local httpStates = BestHTTP.HTTPRequestStates;
local mUri = System.Uri;
local globalHelper = GlobalHelper;
local mangaRequest;
local mangaData = MangaData;
local pageAllData = PageAllData;
local mangaDetail = MangaDetail;
local chapterList = ChapterList;
local chapterData = ChapterData;
--local mList = System.Collections.Generic.List<MangaData>;
local pageSize = 20
local MhrExtensions = {};

function MhrExtensions.GetVersion()
	return 1;
end

function MhrExtensions.GetType()
	return 0;
end

function MhrExtensions.GetExtensionNum()
	return "3616827811449702173";
end

function MhrExtensions.GetExtensionName()
	return "漫画人";
end

function MhrExtensions.Init()

end

function MhrExtensions.RequestPopularManga(page)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		local list = {};
		print(resq.Response.DataAsText)

		local info = json.decode(resq.Response.DataAsText)
		if info["errorResponse"] ~=nil then 
			print(info["errorResponse"] )
			return
		end
		print(info["response"]["mangas"])
		for k,v in ipairs(info["response"]["mangas"]) do
			local tempData = mangaData.New();
			tempData.id = v["mangaId"].. "";
			tempData.title = v["mangaName"]
			tempData.authors = v["mangaAuthor"]
			--tempData.status = v["status"]
			tempData.cover = v["mangaCoverimageUrl"]
			--tempData.types = v["types"]
			--
			--local _, _, y, m, d, _hour, _min, _sec = string.find(v["mangaNewestTime"], "(%d+)-(%d+)-(%d+)%s*(%d+):(%d+):(%d+)");
			--local timestamp = os.time({year=y, month = m, day = d, hour = _hour, min = _min, sec = _sec});
			--tempData.last_updatetime = timestamp;
			--tempData.num = v["num"]
			tempData.url = string.format("http://mangaapi.manhuaren.com/v1/manga/getDetail?mangaId=%s", v.id)
			tempData.source = "3616827811449702173";
			table.insert(list,tempData);
		end
		--var li = MangaFromJson(_mangaRequest.downloadHandler.text);
		print(list)
		globalHelper.OnJsonPhraseComplete(list)
	end
	print(page)
	--[[mangaRequest:Dispose();
	mangaRequest:Clear();
	mangaRequest.Uri = mUri(string.format("http://v2.api.dmzj.com/classify/0/0/%d.json",page - 1));
	--mangaRequest = WebRequest.Get(string.format("http://v2.api.dmzj.com/classify/0/0/%d.json",page - 1));
	mangaRequest.Callback=callBack;
	mangaRequest:Send();--]]
	local tempTable = {};

	table.insert(tempTable,{["subCategoryType"]="0"});
	table.insert(tempTable,{["subCategoryId"]="0"});
	table.insert(tempTable,{["start"]=string.format("%s",pageSize*(page - 1))});
	table.insert(tempTable,{["limit"]=string.format("%s",pageSize)});
	table.insert(tempTable,{["sort"]="0"});

	local extra = MhrExtensions.GenerateExtraInfo(tempTable);
	--local extra_2 = MhrExtensions.UrlEncode(extra);
	print(string.format("http://mangaapi.manhuaren.com/v2/manga/getCategoryMangas?%s",extra));
	local request = MhrExtensions.GetRequest(string.format("http://mangaapi.manhuaren.com/v2/manga/getCategoryMangas?%s",extra));
	request.Callback=callBack;
	request:Send();

end

function MhrExtensions.RequestMangaDetail(url)
	local callBack = function( resq,resp)
		print(resq.State)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			print("Error")
			return;
		end
		print(resq.Response.DataAsText);
		local info = json.decode(resq.Response.DataAsText)
		if info["errorResponse"] ~=nil then 
			print(info["errorResponse"] )
			return
		end

		local detailData = mangaDetail.New();
		detailData.id = info["response"]["mangaId"];
		detailData.title = info["response"]["mangaName"];
		detailData.cover = info["response"]["mangaPicimageUrl"];
		detailData.url = string.format("/v1/manga/getRead?mangaId=%s", detailData.id) 
		local _, _, y, m, d, _hour, _min, _sec = string.find(info["response"]["mangaNewestTime"], "(%d+)-(%d+)-(%d+)%s*(%d+):(%d+):(%d+)");
		local timestamp = os.time({year=y, month = m, day = d, hour = _hour, min = _min, sec = _sec});
		detailData.last_updatetime = timestamp;
		detailData.source = "3616827811449702173";

		detailData.authors = info["response"]["mangaAuthor"];

		detailData.types = info["response"]["mangaTheme"];
		for k,v in pairs(info["response"]["mangaWords"]) do
			local tempChapter = chapterList();
			tempChapter.title = v["sectionTitle"];
			detailData.chapters:Add(tempChapter)

			local tempData = chapterData();
			tempData.chapter_id = v["sectionId"].."";
			if v["isMustPay"] == 1 then
				tempData.chapter_title = "付费"..v["sectionName"];

			else
				tempData.chapter_title = v["sectionName"];
			end

			local _, _, y, m, d = string.find(v["releaseTime"], "(%d+)-(%d+)-(%d+)%s*");
			local timestamp = os.time({year=y, month = m, day = d});

			tempData.updatetime = timestamp;
			--tempData.filesize = s["filesize"];
			tempData.chapter_order = v["sectionSort"];
			tempData.url = string.format("/v1/manga/getRead?mangaSectionId=%s", v["sectionId"]) 
			tempChapter.data:Add(tempData);
		end
		for k,v in pairs(info["response"]["mangaRolls"]) do
			local tempChapter = chapterList();
			tempChapter.title = v["sectionTitle"];
			detailData.chapters:Add(tempChapter)

			local tempData = chapterData();
			tempData.source = "3616827811449702173";
			tempData.chapter_id = v["sectionId"].."";
			if v["isMustPay"] == 1 then
				tempData.chapter_title = "付费"..v["sectionName"];

			else
				tempData.chapter_title = v["sectionName"];
			end

			local _, _, y, m, d = string.find(v["releaseTime"], "(%d+)-(%d+)-(%d+)%s*");
			local timestamp = os.time({year=y, month = m, day = d});

			tempData.updatetime = timestamp;
			--tempData.filesize = s["filesize"];
			tempData.chapter_order = v["sectionSort"];
			tempData.url = string.format("/v1/manga/getRead?mangaSectionId=%s", v["sectionId"]) 
			tempChapter.data:Add(tempData);
		end
		for k,v in pairs(info["response"]["mangaEpisode"]) do
			local tempChapter = chapterList();
			tempChapter.title = v["sectionTitle"];
			detailData.chapters:Add(tempChapter)

			local tempData = chapterData();
			tempData.source = "3616827811449702173";
			tempData.chapter_id = v["sectionId"].."";
			if v["isMustPay"] == 1 then
				tempData.chapter_title = "付费"..v["sectionName"];

			else
				tempData.chapter_title = v["sectionName"];
			end

			local _, _, y, m, d = string.find(v["releaseTime"], "(%d+)-(%d+)-(%d+)%s*");
			local timestamp = os.time({year=y, month = m, day = d});

			tempData.updatetime = timestamp;
			--tempData.filesize = s["filesize"];
			tempData.chapter_order = v["sectionSort"];
			tempData.url = string.format("/v1/manga/getRead?mangaSectionId=%s", v["sectionId"]) 
			tempChapter.data:Add(tempData);
		end
		globalHelper.OnMangaDetailPhraseComplete(detailData)
	end
	print(url)

	local strs = Split(url,"=");
	local tempTable = {};
	table.insert(tempTable,{["mangaId"]=string.format("%s",strs[2])});

	local extra = MhrExtensions.GenerateExtraInfo(tempTable);
	--local extra_2 = MhrExtensions.UrlEncode(extra);
	print(string.format("http://mangaapi.manhuaren.com/v1/manga/getDetail?%s",extra));
	local request = MhrExtensions.GetRequest(string.format("http://mangaapi.manhuaren.com/v1/manga/getDetail?%s",extra));

	--local request = MhrExtensions.GetRequest(url);
	request.Callback=callBack;
	request:Send();
end

function MhrExtensions.RequestSearchManga(query)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		local info = json.decode(resq.Response.DataAsText)
		if info["errorResponse"] ~=nil then 
			print(info["errorResponse"] )
			return
		end
		print(info["response"]["result"])
		local list = {};
		for k,v in ipairs(info["response"]["result"]) do
			local tempData = mangaData.New();
			tempData.id = v["mangaId"].. "";
			tempData.title = v["mangaName"]
			tempData.authors = v["mangaAuthor"]
			tempData.cover = v["mangaCoverimageUrl"]
			tempData.url = string.format("/v1/manga/getDetail?mangaId=%s", tempData.id)
			tempData.source = "3616827811449702173";
			table.insert(list,tempData);
		end
		
		globalHelper.OnSearch("3616827811449702173",list)
	end
	local tempTable = {};

	table.insert(tempTable,{["keywords"]=query});
	local extra = MhrExtensions.GenerateExtraInfo(tempTable);
	print(string.format("http://mangaapi.manhuaren.com/v1/search/getSearchManga?%s",extra))
	local request = MhrExtensions.GetRequest(string.format("http://mangaapi.manhuaren.com/v1/search/getSearchManga?%s",extra));
	request.Callback=callBack;
	request:Send();
end

--[[function CleanStr(url)
	if string.find(url, "//") ~= 1 then
		return url
	else
		return "http:"+url;
	end
end00]]

function MhrExtensions.GetRequest(url)
	local uri = mUri(url);
	print(uri);
	local mangaRequest = mHTTPRequest(nil);
	mangaRequest.Uri = uri;
	mangaRequest:SetHeader("X-Yq-Yqci", "{\"le\": \"zh\"}");
	
	mangaRequest:SetHeader("User-Agent","okhttp/3.11.0");
	mangaRequest:SetHeader("clubReferer", "http://mangaapi.manhuaren.com/");

	mangaRequest:SetHeader("referer", "http://www.dm5.com/dm5api/");
	mangaRequest.Tag = uri;
	return mangaRequest;
end

function MhrExtensions.GenerateExtraInfo(queryTable)
	local extable = {};
	--[[table["start"] = "9";
	table["limit"] = "9";
	table["gsm"] = "md5";
	table["gft"] = "json";
	table["gts"] = os.date("%Y-%m-%d+%H:%M:%S");
	table["gak"] = "android_manhuaren2";
	table["gat"] = "";
	table["gaui"] = "191909801";
	table["gui"] = "191909801";
	table["gut"] = "0";--]]
	for key,value in pairs(queryTable) do
		for i,j in pairs(value)do

			table.insert(extable,{[string.format("%s",i)]=string.format("%s",j)});
	
		end
		
	end
	--[[table.insert(extable,{["start"]="9"});
	table.insert(extable,{["limit"]="9"});--]]
	table.insert(extable,{["gsm"]="md5"});
	table.insert(extable,{["gft"]="json"});
	table.insert(extable,{["gts"]=os.date("%Y-%m-%d+%H:%M:%S")});
	table.insert(extable,{["gak"]="android_manhuaren2"});
	table.insert(extable,{["gat"]=""});
	table.insert(extable,{["gaui"]="191909801"});
	table.insert(extable,{["gui"]="191909801"});
	table.insert(extable,{["gut"]="0"});
	local exT = {};
	for key,value in pairs(extable) do
		
		for s,j in pairs(value) do 
			exT[s] = j;
		end
	end

	local gsn = MhrExtensions.GenerateGSNHash(exT);
	table.insert(extable,{["gsn"]=gsn});
	local str = "";

	for k,v in pairs(extable)do
		for s,j in pairs(v)do
			str = str..s;
			str = str.."=";
			if s == "gts" then
				str = str ..MhrExtensions.UrlEncode(j);
			else
				str = str ..j;
			end
			
			str = str .."&";
		end
	end

	local export = string.sub(str,1,#str - 1); 
	--[[str = "start".."="..table["start"].."&".."limit".."="..table["limit"].."&".."gsm".."="..table["gsm"]
	.."&".."gft".."="..table["gft"].."&".."gts".."="..MhrExtensions.UrlEncode(os.date("%Y-%m-%d+%H:%M:%S")).."&"
	.."gak".."="..table["gak"].."&".."gat".."="..table["gat"].."&".."gaui".."="..table["gaui"].."&"
	.."gui".."="..table["gui"].."&".."gut".."="..table["gut"].."&".."gsn".."="..table["gsn"];--]]
	return export;
end
function MhrExtensions.UrlEncode(s)  
     s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
    return string.gsub(s, " ", "+")  
end  

function urlDecode(s)  
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)  
    return s  
end  
function MhrExtensions.GenerateGSNHash(extraTable)
	local t = extraTable;
	table.sort(t)
	local c = "4e0a48e1c0b54041bce9c8f0e036124d";
	local s = c .."GET";

	local key_table = {}
	for key,value in pairs(t) do
		
		table.insert(key_table,key)  
	end
	table.sort(key_table)
	for key,value in pairs(key_table) do  
		print(key,value,t[value])
		if value ~="gsn" then
			s = s..value;
			local temp = WebUtility.UrlEncode(t[value]);
			local temp_2 = string.gsub(temp,"*","%2A");
			s = s .. temp_2;
		end
	end  
	s = s..c;
	return MathUtils.ToHexMd5Hash(s);
end

function MhrExtensions.GetTextureRequest(url)
	return MhrExtensions.GetRequest(url);
	--[[local mangaTextureRequest = TextureRequest.GetTexture(url,false);
	mangaTextureRequest:SetRequestHeader("User-Agent","Mozilla/5.0 (X11; Linux x86_64) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/56.0.2924.87 " ..
		"Safari/537.36 "..
		"Tachiyomi/1.0");

	mangaTextureRequest:SetRequestHeader("referer", "http://www.dmzj.com/");
	return mangaTextureRequest;--]]
end
function MhrExtensions.RequestGenreManga(url,page)
	local callBack = function( resq,resp)
		print(resq,resp)
		print(resq.State)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText);
		
		--[[local isJson = jsonSplit.IsJson(resq.Response.DataAsText);
		print(isJson);
		if isJson == false then
			return nil;
		end--]]

		local info = json.decode(resq.Response.DataAsText)
		if info["errorResponse"] ~=nil then 
			print(info["errorResponse"] )
			return
		end
		local list = {};
		print(info["response"]["mangas"])
		for k,v in ipairs(info["response"]["mangas"]) do
			local tempData = mangaData.New();
			tempData.id = v["mangaId"].. "";
			tempData.title = v["mangaName"]
			tempData.authors = v["mangaAuthor"]
			tempData.cover = v["mangaCoverimageUrl"]
			tempData.url = string.format("/v1/manga/getDetail?mangaId=%s",tempData.id)
			--tempData.url = tempData.id;
			tempData.source = "3616827811449702173";
			table.insert(list,tempData);
		end
		globalHelper.OnGenreRequestComplete(list)
	end

	local tempTable = {};
	local strs = Split(url,"_");
	for i=1,#strs/2 do
		local index = (i-1)*2

		table.insert(tempTable,{[string.format("%s",strs[index + 1])]= string.format("%s",strs[index+2])});
		--print(strs[index + 1],strs[index+2]);
	end
	
	--table.insert(tempTable,{["subCategoryId"]="0"});
	table.insert(tempTable,{["start"]=string.format("%s",pageSize*(page - 1))});
	table.insert(tempTable,{["limit"]=string.format("%s",pageSize)});
	table.insert(tempTable,{["sort"]="0"});

	local extra = MhrExtensions.GenerateExtraInfo(tempTable);
	--local extra_2 = MhrExtensions.UrlEncode(extra);
	print(string.format("http://mangaapi.manhuaren.com/v2/manga/getCategoryMangas?%s",extra));
	local request = MhrExtensions.GetRequest(string.format("http://mangaapi.manhuaren.com/v2/manga/getCategoryMangas?%s",extra));
	request.Callback=callBack;
	request:Send();
end

function Split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end
    
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function MhrExtensions.RequestMangaPageList(url,detail,chapterDa)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		--[[local isJson = jsonSplit.IsJson(resq.Response.DataAsText);
		print(isJson);
		if isJson == false then
			return nil;
		end--]]
		print(resq.Response.DataAsText)
		local info = json.decode(resq.Response.DataAsText)
		if info["errorResponse"] ~=nil then 
			print(info["errorResponse"] )
			return
		end
		print(info)
		local tempData = pageAllData.New();
		tempData.source = "3616827811449702173";
		local data = PageData.New();
		tempData.chapter = data;
		print(info["response"]["hostList"][1])
		local host = info["response"]["hostList"][1];
		local query = info["response"]["query"]
		data.chapter_name = info["response"]["shareContent"];
		for k,v in ipairs ( info["response"]["mangaSectionImages"]) do 
			print(host..v..query)
			data.page_url:Add(host..v..query);
		end
		globalHelper.OnMangaPagesPhraseComplete(url,tempData,detail,chapterDa)
	end
	--[[mangaRequest:Abort();
	mangaRequest = WebRequest.Get(url);
	local request = mangaRequest:SendWebRequest();
	request.completed=request.completed+callBack;--]]
	print(url)
	local strs = Split(url,"=");
	local tempTable = {};
	table.insert(tempTable,{["mangaSectionId"]=string.format("%s",strs[2])});
	table.insert(tempTable,{["netType"]=4});
	table.insert(tempTable,{["loadreal"]=1});
	table.insert(tempTable,{["imageQuality"]=2});
	local extra = MhrExtensions.GenerateExtraInfo(tempTable);

	print(string.format("http://mangaapi.manhuaren.com/v1/manga/getRead?%s",extra))
	local request = MhrExtensions.GetRequest(string.format("http://mangaapi.manhuaren.com/v1/manga/getRead?%s",extra));
	request.Callback=callBack;
	request:Send();

	--[[mangaRequest:Dispose();
	mangaRequest:Clear();
	mangaRequest.Uri = mUri(url);
	mangaRequest.Callback=callBack;
	mangaRequest:Send();--]]
end

function MhrExtensions.StrightGetMangaDetail(mangaId)
	print(mangaId)
	MhrExtensions.RequestMangaDetail(string.format("mangaId=%s",mangaId))
end

function MhrExtensions.UpdateManga(url)
	local strs = Split(url,"=");
	local tempTable = {};
	table.insert(tempTable,{["mangaId"]=string.format("%s",strs[2])});
	local extra = MhrExtensions.GenerateExtraInfo(tempTable);
	print(string.format("http://mangaapi.manhuaren.com/v1/manga/getDetail?%s",extra));
	local request = MhrExtensions.GetRequest(string.format("http://mangaapi.manhuaren.com/v1/manga/getDetail?%s",extra));
	request:Send();
	return request;
end

function MhrExtensions.Update(resq,url)
	print(resq.State)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			print("Error")
			return;
		end
		print(resq.Response.DataAsText);
		local info = json.decode(resq.Response.DataAsText)
		if info["errorResponse"] ~=nil then 
			print(info["errorResponse"] )
			return
		end

		local detailData = mangaDetail.New();
		detailData.id = info["response"]["mangaId"];
		detailData.title = info["response"]["mangaName"];
		detailData.url = string.format("/v1/manga/getRead?mangaId=%s", detailData.id) 
		detailData.cover = info["response"]["mangaPicimageUrl"];
		local _, _, y, m, d, _hour, _min, _sec = string.find(info["response"]["mangaNewestTime"], "(%d+)-(%d+)-(%d+)%s*(%d+):(%d+):(%d+)");
		local timestamp = os.time({year=y, month = m, day = d, hour = _hour, min = _min, sec = _sec});
		detailData.last_updatetime = timestamp;
		detailData.source = "3616827811449702173";
		detailData.authors = info["response"]["mangaAuthor"];

		detailData.types = info["response"]["mangaTheme"];
		
		for k,v in pairs(info["response"]["mangaWords"]) do
			local tempChapter = chapterList();
			tempChapter.title = v["sectionTitle"];
			detailData.chapters:Add(tempChapter)

			local tempData = chapterData();
			tempData.chapter_id = v["sectionId"].. "";
			if v["isMustPay"] == 1 then
				tempData.chapter_title = "付费"..v["sectionName"];

			else
				tempData.chapter_title = v["sectionName"];
			end

			local _, _, y, m, d = string.find(v["releaseTime"], "(%d+)-(%d+)-(%d+)%s*");
			local timestamp = os.time({year=y, month = m, day = d});

			tempData.updatetime = timestamp;
			--tempData.filesize = s["filesize"];
			tempData.chapter_order = v["sectionSort"];
			tempData.source = "3616827811449702173";
			tempData.url = string.format("/v1/manga/getRead?mangaSectionId=%s", v["sectionId"]) 
			tempChapter.data:Add(tempData);
		end
		for k,v in pairs(info["response"]["mangaRolls"]) do
			local tempChapter = chapterList();
			tempChapter.title = v["sectionTitle"];
			detailData.chapters:Add(tempChapter)

			local tempData = chapterData();
			tempData.chapter_id = v["sectionId"].."";
			if v["isMustPay"] == 1 then
				tempData.chapter_title = "付费"..v["sectionName"];

			else
				tempData.chapter_title = v["sectionName"];
			end

			local _, _, y, m, d = string.find(v["releaseTime"], "(%d+)-(%d+)-(%d+)%s*");
			local timestamp = os.time({year=y, month = m, day = d});

			tempData.updatetime = timestamp;
			--tempData.filesize = s["filesize"];
			tempData.chapter_order = v["sectionSort"];
			tempData.source = "3616827811449702173";
			tempData.url = string.format("/v1/manga/getRead?mangaSectionId=%s", v["sectionId"]) 
			tempChapter.data:Add(tempData);
		end
		for k,v in pairs(info["response"]["mangaEpisode"]) do
			local tempChapter = chapterList();
			tempChapter.title = v["sectionTitle"];
			detailData.chapters:Add(tempChapter)

			local tempData = chapterData();
			tempData.chapter_id = v["sectionId"].."";
			if v["isMustPay"] == 1 then
				tempData.chapter_title = "付费"..v["sectionName"];

			else
				tempData.chapter_title = v["sectionName"];
			end

			local _, _, y, m, d = string.find(v["releaseTime"], "(%d+)-(%d+)-(%d+)%s*");
			local timestamp = os.time({year=y, month = m, day = d});

			tempData.updatetime = timestamp;
			--tempData.filesize = s["filesize"];
			tempData.chapter_order = v["sectionSort"];
			tempData.url = string.format("/v1/manga/getRead?mangaSectionId=%s", v["sectionId"]) 
			tempData.source = "3616827811449702173";
			tempChapter.data:Add(tempData);
		end
	return detailData;
end

function MhrExtensions.GetGenreTable()
	local allTable = {};
	table.insert(allTable,{["subCategoryType"]="0"});
	table.insert(allTable,{["subCategoryId"]="0"});
	return {
		全部 = "subCategoryType_0_subCategoryId_0",
		--[[连载 = "https://mangaapi.manhuaren.com/classify/0-0-1-0-0-%s.json",
		完结 = "https://mangaapi.manhuaren.com/classify/0-0-2-0-0-%s.json",--]]
	};
end

return MhrExtensions;