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
local stringHelper = StringHelper;
local mangaRequest;
local mangaData = MangaData;
local pageAllData = PageAllData;
local mangaDetail = MangaDetail;
local chapterList = ChapterList;
local chapterData = ChapterData;
--local mList = System.Collections.Generic.List<MangaData>;

local DmzjExtensions = {};

function DmzjExtensions.GetVersion()
	return 2;
end

function DmzjExtensions.GetType()
	return 0;
end

function DmzjExtensions.GetExtensionNum()
	return "2884190037559093788";
end

function DmzjExtensions.GetExtensionName()
	return "动漫之家";
end

function DmzjExtensions.Init()
	print("HotFix")
	print("Init")
	print("ooo")
	if not mangaRequest then
		mangaRequest = mHTTPRequest(nil);
		print(mangaRequest);
		print("Mozilla/5.0 (X11; Linux x86_64) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/56.0.2924.87 " ..
		"Safari/537.36 "..
		"Tachiyomi/1.0");
		mangaRequest:SetHeader("User-Agent","Mozilla/5.0 (X11; Linux x86_64) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/56.0.2924.87 " ..
		"Safari/537.36 "..
		"Tachiyomi/1.0");

		mangaRequest:SetHeader("referer", "http://www.dmzj1.com/");
	end
end

function DmzjExtensions.RequestPopularManga(page)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		local list = {};
		local isJson = jsonSplit.IsJson(resq.Response.DataAsText);
		print(isJson);
		if isJson == false then
			return nil;
		end
		local info = json.decode(resq.Response.DataAsText)
		print(info)
		for k,v in ipairs(info) do
			local tempData = mangaData.New();
			tempData.id = v["id"].. "";
			tempData.title = v["title"]
			tempData.authors = v["authors"]
			tempData.status = v["status"]
			tempData.cover = v["cover"]
			tempData.types = v["types"]
			tempData.last_updatetime = v["last_updatetime"]
			tempData.num = v["num"]
			tempData.url = string.format("http://v3api.dmzj1.com/comic/comic_%d.json?version=2.7.019", v.id)
			tempData.source = "2884190037559093788";
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

	local request = DmzjExtensions.GetRequest(string.format("https://v3api.dmzj1.com/classify/0/0/%d.json",page - 1));
	request.Callback=callBack;
	request:Send();

end

function DmzjExtensions.RequestMangaDetail(url)
	local callBack = function( resq,resp)
		print(resq.State)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			print("Error")
			return;
		end
		local info = json.decode(resq.Response.DataAsText)
		print(resq.Response.DataAsText);
		local detailData = mangaDetail.New();
		print(info["data"])
		local info_1 = info["data"]["info"];
		detailData.id = info_1["id"];
		detailData.title = info_1["title"];
		detailData.url = url;
		detailData.cover = info_1["cover"];
		
		detailData.last_updatetime = (info_1["last_updatetime"]+0)*1000;
		detailData.source = "2884190037559093788";
		print(info_1["last_update_chapter_name"])
		--detailData.last_update_chapter_id = info_1["last_update_chapter_name"];
		detailData.authors = info_1["authors"];
		detailData.status = info_1["status"];
		detailData.types = info_1["types"];
		detailData.description = info_1["description"]
		local info_2 = info["data"]["list"]
		local tempChapter = chapterList();
		detailData.chapters:Add(tempChapter)
		for k,v in ipairs(info_2) do
			local tempData = chapterData();
			tempData.chapter_id = v["id"].. "";
			tempData.chapter_title = v["chapter_name"];
			tempData.updatetime = v["updatetime"];
			tempData.filesize = v["filesize"];
			tempData.source = "2884190037559093788";
			tempData.chapter_order = v["chapter_order"];
			tempData.url = string.format("https://api.m.dmzj1.com/comic/chapter/%d/%d.html", detailData.id,tempData.chapter_id) 
			tempChapter.data:Add(tempData);
		end
		globalHelper.OnMangaDetailPhraseComplete(detailData)
	end
	--url = stringHelper.Replace(url,"?version=2.7.019","")
	print(url)
	local cid = string.match(url, "%d+")
	print(string.format("https://api.dmzj.com/dynamic/comicinfo/%s",cid .. ".json"))
	local request = DmzjExtensions.GetRequest(string.format("https://api.dmzj.com/dynamic/comicinfo/%s",cid .. ".json"));
	request.Callback=callBack;
	request:Send();
end

function DmzjExtensions.RequestSearchManga(query)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		local tempStr = resq.Response.DataAsText;
		print(tempStr)
		local startIndex = string.find(tempStr,"=");
		local endIndex = string.find(tempStr,";");
		local subStr = string.sub(tempStr,startIndex + 1,endIndex-1);

		subStr = stringHelper.TrimStr(subStr);
		print(subStr)
		local isJson = jsonSplit.IsJson(subStr);
		if isJson == false then
			return nil;
		end
		local info = json.decode(subStr)
		--local info = json.decode(subStr)
		local list = {};
		for k,v in ipairs(info) do
			local tempData = mangaData.New();
			tempData.id = v["id"].. "";
			tempData.title = v["comic_name"]
			tempData.authors = v["comic_author"]
			--tempData.status = v["status"]
			print(CleanStr(v["comic_cover"]));
			tempData.cover = CleanStr(v["comic_cover"])
			--tempData.types = v["types"]
			--tempData.last_updatetime = v["last_updatetime"]
			--tempData.num = v["num"]
			
			tempData.url = string.format("/comic/comic_%d.json?version=2.7.019", v.id)
			tempData.source = "2884190037559093788";
			table.insert(list,tempData);
		end
		globalHelper.OnSearch("2884190037559093788",list)
	end
	local request = DmzjExtensions.GetRequest(string.format("http://s.acg.dmzj1.com/comicsum/search.php?s=%s",query));
	request.Callback=callBack;
	request:Send();
end

function CleanStr(url)
	if string.find(url, "//") ~= 1 then
		return url
	else
		return "http:"+url;
	end
end

function DmzjExtensions.GetRequest(url)
	local mangaTextureRequest = mHTTPRequest(mUri(url));
	mangaTextureRequest:SetHeader("User-Agent","Mozilla/5.0 (Linux; Android 10) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/88.0.4324.93 " ..
		"Mobile Safari/537.36"..
		"Tachiyomi/1.0");

	mangaTextureRequest:SetHeader("referer", "https://www.dmzj1.com/");
	mangaTextureRequest.Tag = url;
	return mangaTextureRequest;
end

function DmzjExtensions.GetTextureRequest(url)
	return DmzjExtensions.GetRequest(url);
	--[[local mangaTextureRequest = TextureRequest.GetTexture(url,false);
	mangaTextureRequest:SetRequestHeader("User-Agent","Mozilla/5.0 (X11; Linux x86_64) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/56.0.2924.87 " ..
		"Safari/537.36 "..
		"Tachiyomi/1.0");

	mangaTextureRequest:SetRequestHeader("referer", "http://www.dmzj.com/");
	return mangaTextureRequest;--]]
end
function DmzjExtensions.RequestGenreManga(url,page)
	local callBack = function( resq,resp)
		print(resq,resp)
		print(resq.State)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText);
		
		local isJson = jsonSplit.IsJson(resq.Response.DataAsText);
		print(isJson);
		--if isJson == false then
		--	return nil;
		--end
		local info = json.decode(resq.Response.DataAsText)
		local list = {};
		for k,v in ipairs(info) do
			local tempData = mangaData.New();
			tempData.id = v["id"].. "";
			tempData.title = v["name"]
			tempData.authors = v["authors"]
			tempData.status = v["status"]
			tempData.cover = string.format("https://images.dmzj1.com/%s",v["cover"])
			tempData.types = v["types"]
			tempData.last_updatetime = v["last_updatetime"]
			--tempData.num = v["num"]
			
			tempData.url = string.format("/comic/comic_%d.json?version=2.7.019", v.id)
			tempData.source = "2884190037559093788";
			table.insert(list,tempData);
		end
		globalHelper.OnGenreRequestComplete(list)
	end
	local request = nil;
	if string.find(url,"rank") ~= -1 then
		print(string.format(url,page - 1),page)
		request = DmzjExtensions.GetRequest(string.format(url,page - 1));
	else
		request = DmzjExtensions.GetRequest(string.format(url,page));
	end
	request.Callback=callBack;
	request:Send();
end

function DmzjExtensions.RequestMangaPageList(url,detail,chapterDa)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			DmzjExtensions.OnNewChapterApiFail(url,detail,chapterDa)
			return;
		end
		print(resq.Response.DataAsText)
		local info = json.decode(resq.Response.DataAsText)
		print(info)
		local tempData = pageAllData.New();
		tempData.source = "2884190037559093788";
		local data = PageData.New();
		tempData.chapter = data;
		print(info["chapter"])

		data.chapter_name = info["chapter"]["chapter_name"];
		for k,v in ipairs ( info["chapter"]["page_url"]) do 
			print(v)
			data.page_url:Add(v);
		end
		globalHelper.OnMangaPagesPhraseComplete(url,tempData,detail,chapterDa)
	end
	print(url)
	local request = DmzjExtensions.GetRequest(url);
	request.Callback = callBack;
	request:Send();
end

function DmzjExtensions.OnNewChapterApiFail(url,detail,chapterDa)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText)
		local info = json.decode(resq.Response.DataAsText)
		local tempData = pageAllData.New();
		tempData.source = "2884190037559093788";
		local data = PageData.New();
		tempData.chapter = data;

		data.chapter_name = info["chapter_name"];
		for k,v in ipairs ( info["page_url"]) do 
			print(v)
			data.page_url:Add(v);
		end
		globalHelper.OnMangaPagesPhraseComplete(url,tempData,detail,chapterDa)
	end
	print(url,chapterDa)
	local tempUrl = string.format("https://m.dmzj.com/chapinfo/%s/%s.html",detail.id,chapterDa.chapter_id)
	local request = DmzjExtensions.GetRequest(tempUrl);
	request.Callback = callBack;
	request:Send();

end

function DmzjExtensions.StrightGetMangaDetail(mangaId)
	print(mangaId)
	DmzjExtensions.RequestMangaDetail(string.format("/comic/comic_%d.json?version=2.7.019", mangaId));
end

function DmzjExtensions.UpdateManga(url)

	local cid = string.match(url, "%d+")
	local request = DmzjExtensions.GetRequest(string.format("https://api.dmzj.com/dynamic/comicinfo/%s",cid .. ".json"));
	--local request = DmzjExtensions.GetRequest(string.format("http://v3api.dmzj1.com/%s",url));
	--request.Callback=callBack;
	request:Send();
	return request;
end

function DmzjExtensions.Update(resq,url)
	if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			print("OnError")
			return;
		end
		local info = json.decode(resq.Response.DataAsText)
		local detailData = mangaDetail.New();
		local info_1 = info["data"]["info"];
		detailData.id = info_1["id"];
		detailData.title = info_1["title"];
		detailData.url = url;
		detailData.cover = info_1["cover"];
		
		detailData.last_updatetime = (info_1["last_updatetime"]+0)*1000;
		detailData.source = "2884190037559093788";
		--detailData.last_update_chapter_id = info_1["last_update_chapter_name"];
		detailData.authors = info_1["authors"];
		detailData.status = info_1["status"];
		detailData.types = info_1["types"];
		detailData.description = info_1["description"]
		local info_2 = info["data"]["list"]
		local tempChapter = chapterList();
		detailData.chapters:Add(tempChapter)
		for k,v in ipairs(info_2) do
			local tempData = chapterData();
			tempData.chapter_id = v["id"].. "";
			tempData.chapter_title = v["chapter_name"];
			tempData.updatetime = v["updatetime"];
			tempData.filesize = v["filesize"];
			tempData.source = "2884190037559093788";
			tempData.chapter_order = v["chapter_order"];
			tempData.url = string.format("https://api.m.dmzj1.com/comic/chapter/%d/%d.html", detailData.id,tempData.chapter_id) 
			tempChapter.data:Add(tempData);
		end
	return detailData;
end

function DmzjExtensions.GetGenreTable()
	return {
		全部 = "https://m.dmzj1.com/classify/0-0-0-0-0-%s.json",
		连载 = "https://m.dmzj1.com/classify/0-0-1-0-0-%s.json",
		完结 = "https://m.dmzj1.com/classify/0-0-2-0-0-%s.json",
		最新 = "https://m.dmzj1.com/latest/%s.json",
		人气日榜 = "https://m.dmzj1.com/rank/0-0-0-%s.json",
	};
end

return DmzjExtensions;
