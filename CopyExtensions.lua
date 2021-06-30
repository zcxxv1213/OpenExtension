local json = require 'cjson'
--local bjson = BestHTTP.JSON.Json
local jsonSplit = JsonSplit;
local GameObject = UnityEngine.GameObject
local playerPrefs = UnityEngine.PlayerPrefs;
local mHTTPRequest = BestHTTP.HTTPRequest;
local httpStates = BestHTTP.HTTPRequestStates;
local mUri = System.Uri;
local globalHelper = GlobalHelper;
local stringHelper = StringHelper;
local htmlHelper = HtmlHelper;
local magicMethod = MagicMethod;
local mangaRequest;
local mangaData = MangaData;
local pageAllData = PageAllData;
local mangaDetail = MangaDetail;
local chapterList = ChapterList;
local chapterData = ChapterData;
local mHttpProxy = BestHTTP.HTTPProxy;
local pageCount = 50;
local CopyExtensions = {};
local proxyPort = 0;
function CopyExtensions.GetVersion()
	return 1;
end

function CopyExtensions.GetType()
	return 0;
end

function CopyExtensions.GetExtensionNum()
	return "6696312508930833206";
end

function CopyExtensions.GetExtensionName()
	return "拷贝漫画";
end

function CopyExtensions.Init()
	if not mangaRequest then
		mangaRequest = mHTTPRequest(nil);
		print("Mozilla/5.0 (X11; Linux x86_64) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/56.0.2924.87 " ..
		"Safari/537.36 ");
		mangaRequest:SetHeader("User-Agent","Mozilla/5.0 (X11; Linux x86_64) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/56.0.2924.87 " ..
		"Safari/537.36 ");

		mangaRequest:SetHeader("Referer", "https://www.copymanga.com");
	end

	if playerPrefs.HasKey("CopyPort") then
		proxyPort = playerPrefs.GetInt("CopyPort")
	end
end

function CopyExtensions.RequestMangaDetail(url)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			print("Error")
			return;
		end
		print(resq.Response.DataAsText)
		local detailData = mangaDetail.New();
		local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
		local selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-title-right > ul > li");
		detailData.title = selectElement[0].TextContent;
		
		detailData.url = url;
		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-title-left img");
		detailData.cover = selectElement[0]:GetAttribute("data-src");

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-synopsis p.intro");
		detailData.description = selectElement[0].TextContent;

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-title-right > ul > li > span");
		detailData.authors = stringHelper.TrimStr(selectElement[2].TextContent);
		local times = Split(selectElement[5].TextContent,"-");
		local timestamp = os.time({day=times[3],month=times[2],year=times[1], hour =0, min = 0, sec =0});
		detailData.last_updatetime = timestamp
		detailData.status = selectElement[7].TextContent;

		detailData.source = "6696312508930833206";

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.disposableData");
		local disposableData = selectElement[0]:GetAttribute("disposable");

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.disposablePass");
		local disposablePass = selectElement[0]:GetAttribute("disposable");
		local prePart = string.sub(disposableData,1,16); 
		local postPart = string.sub(disposableData,17,#disposableData);
		local datas = magicMethod.hexToBytes(postPart);
		local chapterJsonString = magicMethod.AesDecrypt(datas,disposablePass,prePart);
		local isJson = jsonSplit.IsJson(chapterJsonString);
		print(chapterJsonString)
		if isJson == false then
			return nil;
		end
		local info = json.decode(chapterJsonString)
		local tempKey={}
		for k,v in pairs(info) do
			table.insert(tempKey,k);
		end
		--local rTable = ReverseTable(tempKey);

		for k,v in pairs(tempKey) do
			print(k,v)
			if info[v]["groups"]~=nil then
				if info[v]["groups"]["全部"]~=nil then
					local tempChapter = chapterList();
					detailData.chapters:Add(tempChapter)
					local data = info[v]["groups"]["全部"];
					for i = #info[v]["groups"]["全部"],1 , -1 do
						print(i)
						
						local tempData = chapterData();
						tempData.chapter_id = data[i]["comic_id"].."";
						tempData.chapter_title = data[i]["name"];
						local times = Split(data[i]["datetime_created"],"-");
						local timestamp = os.time({day=times[3],month=times[2],year=times[1], hour =0, min = 0, sec =0});
						tempData.updatetime = timestamp;
						tempData.url = string.format("/comic/%s/chapter/%s", data[i]["comic_path_word"], data[i]["uuid"])
						tempChapter.data:Add(tempData);
						print(tempData.url ,tempData.chapter_id,tempData.updatetime);
					end
				end
			end
		end

		detailData.chapters:Reverse();
		globalHelper.OnMangaDetailPhraseComplete(detailData)
	end

	print(url)
	local request = CopyExtensions.GetRequest(string.format("https://www.copymanga.com%s",url));
	request.Callback=callBack;
	request:Send();
end

function CopyExtensions.AesDecrypt(datas,disposablePass,prePart)
	
end

function CopyExtensions.RequestSearchManga(query)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		local iter = resq.Response.Headers:GetEnumerator();
		local checkValue;
		while iter:MoveNext() do
			if iter.Current.Key == "content-type" then
				checkValue = iter.Current.Value;
			end                          
		end
		local checkBool = false;
		if checkValue ~= nil then
			checkValue:ForEach(function(ss)
				if string.find(ss,"json") then
					checkBool = true;
				end
			end)

			if checkBool then
				local info = json.decode(resq.Response.DataAsText)
				local list={};
				if info["results"]["list"] ~=nil then
					local comicArray = info["results"]["list"];
					for k,v in ipairs(comicArray) do
						local tempData = mangaData.New();
						tempData.title = v["name"]
						local authorTemp = ""
						for t,l in ipairs(v["author"]) do
							authorTemp = authorTemp..l["name"] .."  "
						end
						tempData.authors = authorTemp
						tempData.status = "Unknown"
						tempData.cover = v["cover"]
						tempData.url = string.format("/comic/%s", v["path_word"])
						tempData.source = "6696312508930833206";
						table.insert(list,tempData);
					end
				end
				globalHelper.OnSearch("6696312508930833206",list)
			else 
				local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
				local mangaList = htmlHelper.DocumentQuerySelectItems(document,"div.exemptComicList div.exemptComicItem");
				local list={};
				mangaList:ForEach(function(v)
					local tempData = mangaData.New();
					local selectElement = htmlHelper.ElementQuerySelect(v,"div.exemptComicItem-txt > a");
					--[[selectElement:ForEach(function(s)
						if s:GetAttribute("href")~=nil then
							tempData.url = s:GetAttribute("href");
						end
					end);--]]
					tempData.url = selectElement[0]:GetAttribute("href");
					selectElement = htmlHelper.ElementQuerySelect(v,"div.exemptComicItem-txt > a > p");
					tempData.title = selectElement[0].TextContent;

					selectElement = htmlHelper.ElementQuerySelect(v,"div.exemptComicItem-img > a > img");
					tempData.cover = selectElement[0]:GetAttribute("data-src");
					tempData.source = "6696312508930833206";
					table.insert(list,tempData);
				end);

				globalHelper.OnSearch("6696312508930833206",list)
			end
		else
			
		end
	end
	print(string.format("https://www.copymanga.com/api/kb/web/search/comics?limit=%s&offset=%s&platform=2&q=%s&q_type=",30,0,query));
	local request = CopyExtensions.GetRequest(string.format("https://www.copymanga.com/api/kb/web/search/comics?limit=%s&offset=%s&platform=2&q=%s&q_type=",30,0,query));
	request.Callback=callBack;
	request:Send();
end

function CopyExtensions.GetRequest(url)
	local mangaTextureRequest = mHTTPRequest(mUri(url));
	mangaTextureRequest:SetHeader("User-Agent","Mozilla/5.0 (X11; Linux x86_64) " ..
		"AppleWebKit/537.36 (KHTML, like Gecko) " ..
		"Chrome/56.0.2924.87 " ..
		"Safari/537.36 ");

	mangaTextureRequest:SetHeader("Referer", "https://www.copymanga.com");
	mangaTextureRequest.Tag = url;

	if proxyPort ~= 0 then
		local proxyUri = mUri(string.format("http://localhost:%d",proxyPort));
		mangaTextureRequest.Proxy = mHttpProxy(proxyUri)
	end

	return mangaTextureRequest;
end

function CopyExtensions.GetTextureRequest(url)
	return CopyExtensions.GetRequest(url);
end
function CopyExtensions.RequestGenreManga(url,page)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText)
		local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
		local mangaList = htmlHelper.DocumentLinqSelectItems(document,"exemptComicItem");
		local list={};
		mangaList:ForEach(function(v)
			local tempData = mangaData.New();
			local selectElement = htmlHelper.ElementQuerySelect(v,"div.exemptComicItem-txt > a");
			--[[selectElement:ForEach(function(s)
				if s:GetAttribute("href")~=nil then
					tempData.url = s:GetAttribute("href");
				end
			end);--]]
			print(selectElement[0]:GetAttribute("href"))
			tempData.url = selectElement[0]:GetAttribute("href");
			selectElement = htmlHelper.ElementQuerySelect(v,"div.exemptComicItem-txt > a > p");
			tempData.title = selectElement[0].TextContent;

			selectElement = htmlHelper.ElementQuerySelect(v,"div.exemptComicItem-img > a > img");
			tempData.cover = selectElement[0]:GetAttribute("data-src");
			print(tempData.cover)
			tempData.source = "6696312508930833206";
			--[[selectElement:ForEach(function(ss)
				print(ss.TextContent);
			end);--]]
			table.insert(list,tempData);
		end);
		globalHelper.OnGenreRequestComplete(list)
	end
	print(string.format(url,(page - 1)*pageCount,pageCount))
	local request = CopyExtensions.GetRequest(string.format(url,(page - 1)*pageCount,pageCount));
	request.Callback=callBack;
	request:Send();
end

function CopyExtensions.RequestMangaPageList(url,detail,chapterDa)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print("1")
		local tempData = pageAllData.New();
		tempData.source = "6696312508930833206";
		local data = PageData.New();
		tempData.chapter = data;

		local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
		local selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.disposableData");
		local disposableData = selectElement[0]:GetAttribute("disposable");
		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.disposablePass");
		local disposablePass = selectElement[0]:GetAttribute("disposable");
		local prePart = string.sub(disposableData,1,16); 
		local postPart = string.sub(disposableData,17,#disposableData);
		local datas = magicMethod.hexToBytes(postPart);
		local chapterJsonString = magicMethod.AesDecrypt(datas,disposablePass,prePart);
		local isJson = jsonSplit.IsJson(chapterJsonString);
		if isJson == false then
			return nil;
		end
		local info = json.decode(chapterJsonString)

		print(info)
		data.chapter_name = "";
		for k,v in ipairs (info) do
			data.page_url:Add(v["url"]);
		end
		globalHelper.OnMangaPagesPhraseComplete(url,tempData,detail,chapterDa)
	end
	--[[mangaRequest:Abort();
	mangaRequest = WebRequest.Get(url);
	local request = mangaRequest:SendWebRequest();
	request.completed=request.completed+callBack;--]]
	print(url)
	local request = CopyExtensions.GetRequest(string.format("https://www.copymanga.com%s",url));
	request.Callback=callBack;
	request:Send();

	--[[mangaRequest:Dispose();
	mangaRequest:Clear();
	mangaRequest.Uri = mUri(url);
	mangaRequest.Callback=callBack;
	mangaRequest:Send();--]]
end

function CopyExtensions.StrightGetMangaDetail(mangaId)
	print(mangaId)
	CopyExtensions.RequestMangaDetail(string.format("https://www.copymanga.com/comic/%s", mangaId));
end

function CopyExtensions.UpdateManga(url)
	print(string.format("https://www.copymanga.com%s",url))
	local request = CopyExtensions.GetRequest(string.format("https://www.copymanga.com%s",url));
	request.Callback=callBack;
	request:Send();
	return request;
end

function CopyExtensions.Update(resq,url)
	print("____1")
	if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut or  resq.State == httpStates.TimedOut then
			print("OnError")
			return;
	end
		local detailData = mangaDetail.New();
		local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
		local selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-title-right > ul > li");
		detailData.title = selectElement[0].TextContent;
		

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-title-left img");
		detailData.cover = selectElement[0]:GetAttribute("data-src");

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-synopsis p.intro");
		detailData.description = selectElement[0].TextContent;

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.comicParticulars-title-right > ul > li > span");
		detailData.authors = stringHelper.TrimStr(selectElement[2].TextContent);
		local times = Split(selectElement[5].TextContent,"-");
		local timestamp = os.time({day=times[3],month=times[2],year=times[1], hour =0, min = 0, sec =0});
		detailData.last_updatetime = timestamp
		detailData.status = selectElement[7].TextContent;
		detailData.url = url;
		detailData.source = "6696312508930833206";

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.disposableData");
		local disposableData = selectElement[0]:GetAttribute("disposable");

		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.disposablePass");
		local disposablePass = selectElement[0]:GetAttribute("disposable");
		local prePart = string.sub(disposableData,1,16); 
		local postPart = string.sub(disposableData,17,#disposableData);
		local datas = magicMethod.hexToBytes(postPart);
		local chapterJsonString = magicMethod.AesDecrypt(datas,disposablePass,prePart);
		local isJson = jsonSplit.IsJson(chapterJsonString);
		if isJson == false then
			return nil;
		end
		local info = json.decode(chapterJsonString)
		local tempKey={}
		for k,v in pairs(info) do
			table.insert(tempKey,k);
		end
		--local rTable = ReverseTable(tempKey);

		for k,v in pairs(tempKey) do
			if info[v]["groups"]~=nil then
				if info[v]["groups"]["全部"]~=nil then
					local tempChapter = chapterList();
					detailData.chapters:Add(tempChapter)
					for j,s in pairs (info[v]["groups"]["全部"]) do
						
						local tempData = chapterData();
						tempData.chapter_id = s["comic_id"].."";
						tempData.chapter_title = s["name"];
						local times = Split(s["datetime_created"],"-");
						local timestamp = os.time({day=times[3],month=times[2],year=times[1], hour =0, min = 0, sec =0});
						tempData.updatetime = timestamp;
						tempData.url = string.format("/comic/%s/chapter/%s", s["comic_path_word"], s["uuid"])
						tempChapter.data:Add(tempData);
					end
				end
			end
		end	
	return detailData;
end

function CopyExtensions.GetGenreTable()
	return {
		热门 = "https://www.copymanga.com/comics?ordering=-popular&offset=%s&limit=%s",
		最新 = "https://www.copymanga.com/comics?ordering=-datetime_updated&offset=%s&limit=%s",
	};
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
function ReverseTable(reverseTab)
    local tmp = {}
    for i = 1, #reverseTab do
        local key = #reverseTab + 1 - i
        tmp[i] = reverseTab[key]
    end
    return tmp
end

function CopyExtensions.GetSettingDic()
	local table = {
		text_proxyPort = 0;
	};
	return table;
end

function CopyExtensions.GetCurrentSettingValue(pa)
	if pa == "sortype" then
		return sortType  .. "";
	elseif pa == "proxyPort" then
		return proxyPort .. "";
	end
end

function CopyExtensions.SetSettingValue(key,value)
	if key == "proxyPort" then
		proxyPort = value + 0 ;
		playerPrefs.SetInt("CopyPort",proxyPort)
	end
	print(key,value)
end

return CopyExtensions;