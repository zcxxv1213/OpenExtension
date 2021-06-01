local json = require 'cjson'
local playerPrefs = UnityEngine.PlayerPrefs;
local mHTTPRequest = BestHTTP.HTTPRequest;
local httpStates = BestHTTP.HTTPRequestStates;
local systemGuid = System.Guid;
local mUri = System.Uri;
local mHttpProxy = BestHTTP.HTTPProxy;
local globalHelper = GlobalHelper;
local stringHelper = StringHelper;
local uiHelper = UIHelper;
local mangaData = MangaData;
local pageAllData = PageAllData;
local mangaDetail = MangaDetail;
local chapterList = ChapterList;
local chapterData = ChapterData;
local timeHelper = TimeHelper;
local magicMethod = MagicMethod;
local httpMethod = BestHTTP.HTTPMethods;
local token;
local ifLoginSuccess = false;
local api_key = "C69BAF41DA5ABD1FFEDC6D2FEA56B";
local BASE_URL = "picaapi.picacomic.com";
local secret_key = "~d}$Q7$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn";
local proxyPort = 0;
local PicaExtensions = {};
local sortType = "ua";
function PicaExtensions.GetVersion()
	return 1;
end

function PicaExtensions.GetType()
	return 0;
end

function PicaExtensions.GetExtensionNum()
	return "9988005021315885225";
end

function PicaExtensions.GetExtensionName()
	return "哔咔漫画";
end

function PicaExtensions.Init()
	if playerPrefs.HasKey("PicaToken") then
		token = playerPrefs.GetString("PicaToken")
		ifLoginSuccess = true;
	end

	if playerPrefs.HasKey("PicaSortType") then
		sortType = playerPrefs.GetString("PicaSortType")
	end

	if playerPrefs.HasKey("PicaPort") then
		proxyPort = playerPrefs.GetInt("PicaPort")
	end
end

function PicaExtensions.SetHeader(mangaRequest,nurl,method,nonce,timeStr)
	--mangaRequest:RemoveHeaders();
	mangaRequest:SetHeader("Content-Type", "application/json; charset=UTF-8");
	mangaRequest:SetHeader("Host", BASE_URL);
	mangaRequest:SetHeader("User-Agent","okhttp/3.8.1");
	mangaRequest:SetHeader("accept", "application/vnd.picacomic.com.v1+json");
	mangaRequest:SetHeader("api-key", api_key);
	mangaRequest:SetHeader("app-build-version", "44");
	mangaRequest:SetHeader("app-version", "2.2.1.3.3.4");
    mangaRequest:SetHeader("app-channel", "1");
    mangaRequest:SetHeader("app-platform", "android");
    mangaRequest:SetHeader("app-uuid", systemGuid.NewGuid():ToString());
    mangaRequest:SetHeader("nonce", nonce);
    --mangaRequest:SetHeader("sources", "Chrom11");
    mangaRequest:SetHeader("time", timeStr);
	local signature = PicaExtensions.CaculateSign(nurl,method,nonce,timeStr,api_key,secret_key);
    mangaRequest:SetHeader("signature", signature);
    mangaRequest:SetHeader("image-quality", "original");
end

function PicaExtensions.CaculateSign(nurl,method,nonce,timeStr,api_key,secret_key)
	local str = nurl  .. timeStr..nonce..method ..api_key;
	str = string.lower(str);
	local result = magicMethod.HMACSHA256Sinature(str,secret_key);
	return result;
end

function PicaExtensions.SetHeaderWithAuthorization(mangaRequest,nurl,method,nonce,timeStr)
	mangaRequest:SetHeader("authorization", token);
	PicaExtensions.SetHeader(mangaRequest,nurl,method,nonce,timeStr);
end

function PicaExtensions.IfCanLogin()
	return true;
end
function PicaExtensions.CheckIfLoginSuccess()
	return ifLoginSuccess;
end

function PicaExtensions.Login(mail,pass)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			uiHelper.ShowTipsUI("登录失败");
			print(resq.Response.DataAsText)
			return;
		end
		local jsonStr = json.decode(resq.Response.DataAsText)
		if jsonStr["code"] ~= 200 then
			print("错误代码" .. jsonStr["code"]);
			ifLoginSuccess = false;
			uiHelper.ShowTipsUI("登录失败");
		else
			token = jsonStr["data"]["token"];
			print("LoginToken"..token)
			playerPrefs.SetString("PicaToken",token);
			print("Success")
			uiHelper.ShowTipsUI("登录成功");
			ifLoginSuccess = true;
		end
	end
	local request = PicaExtensions.GetLoginPostRequest("auth/sign-in");
	local jsonTable = {
		email = mail,
		password = pass,
	}
	local jsonStr = json.encode(jsonTable);
	request.RawData = stringHelper.GetStringUTF8Byte(jsonStr);
	request.Callback = callBack;
	request:Send();
	return request;
end

function PicaExtensions.RequestMangaDetail(url)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			print("Error")
			return;
		end
		print(resq.Response.DataAsText);
		local info = json.decode(resq.Response.DataAsText)
		if info["code"] ~= 200 then
			print("错误代码" .. info);
			ifLoginSuccess = false;
			uiHelper.ShowTipsUI("错误代码" .. info["code"]);
		else
			local detailData = mangaDetail.New();
			detailData.id = info["data"]["comic"]["_id"];
			detailData.title = info["data"]["comic"]["title"];
			print(info["data"]["comic"]["title"])
			detailData.url = url;
			detailData.cover = info["data"]["comic"]["thumb"]["path"];
			detailData.last_updatetime =  PicaExtensions.CaculateTime(info["data"]["comic"]["updated_at"]);
			detailData.source = "9988005021315885225";
			detailData.authors = info["data"]["comic"]["author"];
			detailData.description = info["data"]["comic"]["description"]
			if info["data"]["comic"]["finished"] == true then
				detailData.status = "完结";
			else
				detailData.status = "连载";
			end
			detailData.types = info["data"]["comic"]["categories"][0];
			PicaExtensions.GetChapterInfos(detailData,1,info["data"]["comic"]["epsCount"] + 0)
		end
	end
	print(url)
	local request = PicaExtensions.GetRequest(url);
	request.Callback = callBack;
	request:Send();
end

function PicaExtensions.GetChapterInfos(mangaDetail,startIndex,page)
	if startIndex <= page  then
		local callBack = function( resq,resp)
			if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
			or  resq.State == httpStates.TimedOut 
			then
				print("Error")
				return;
			end
			print(resq.Response.DataAsText);
			local info = json.decode(resq.Response.DataAsText)
			if info["code"] ~= 200 then
				print("错误代码" .. info);
				ifLoginSuccess = false;
				uiHelper.ShowTipsUI("错误代码" .. info["code"]);
			else
				local tempChapter = chapterList();
				mangaDetail.chapters:Add(tempChapter)
				for k,v in ipairs(info["data"]["eps"]["docs"]) do
					local tempData = chapterData();
					print(v["order"]);
					tempData.chapter_id = v["order"].. "";
					tempData.chapter_title = v["title"];
					tempData.updatetime = PicaExtensions.CaculateTime(v["updated_at"]);
					tempData.source = "9988005021315885225";
					tempData.url = string.format("comics/%s/order/%s/pages?page=%d",mangaDetail.id,v["order"].. "",info["data"]["eps"]["page"]) 
					tempChapter.data:Add(tempData);
				end
				if startIndex == page then
					globalHelper.OnMangaDetailPhraseComplete(mangaDetail)
				else
					PicaExtensions.GetChapterInfos(mangaDetail,startIndex +1,page)
				end
	
			end
		end
		local exUrl = string.format("/eps?page=%d",startIndex)
		--print(mangaDetail)
		--print(mangaDetail.url..exUrl);

		local request = PicaExtensions.GetRequest(mangaDetail.url..exUrl);
		request.Callback = callBack;
		request:Send();
	end
end


function PicaExtensions.CaculateTime(picaTime)
	local _, _, y, m, d = string.find(picaTime, "(%d+)-(%d+)-(%d+)%s*");
	print(y,m,d)
	local timestamp = os.time({year=y, month = m, day = d});
	return timestamp;
end


function PicaExtensions.RequestSearchManga(query)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		local jsonStr = json.decode(resq.Response.DataAsText)
		local list = {};
		if jsonStr["code"] ~= 200 then
			print("错误代码" .. jsonStr);
			ifLoginSuccess = false;
			uiHelper.ShowTipsUI("错误代码" .. jsonStr["code"]);
		else
			for k,v in ipairs(jsonStr["data"]["comics"]["docs"]) do
				local tempData = mangaData.New();
				tempData.id = v["_id"].. "";
				tempData.title = v["title"]
				tempData.authors = v["author"]
				tempData.cover = v["thumb"]["path"]
				tempData.url = string.format("comics/%s", v["_id"].. "")
				tempData.source = "9988005021315885225";
				table.insert(list,tempData);
				globalHelper.OnSearch("9988005021315885225",list)
			end
		end
	end
	local request = PicaExtensions.GetPostRequest("comics/advanced-search?page=1");
	local jsonTable = {
		keyword = query,
	}
	local jsonStr = json.encode(jsonTable);
	request.RawData = stringHelper.GetStringUTF8Byte(jsonStr);
	request.Callback = callBack;
	request:Send();
end

function PicaExtensions.GetLoginPostRequest(nurl)
	local timeStr =  math.floor( (tostring(timeHelper.ClientNow()) + 0)/1000);
	local nonce = systemGuid.NewGuid():ToString();
	nonce = stringHelper.Replace(nonce,"-","");
	local mangaTextureRequest = mHTTPRequest(nil,httpMethod.Post);
	PicaExtensions.SetHeader(mangaTextureRequest,nurl,"POST",nonce,timeStr);
	local url = "https://picaapi.picacomic.com/" .. nurl;
	local uri = mUri(url);
	mangaTextureRequest.Uri = uri;
	if proxyPort ~= 0 then
		local proxyUri = mUri(string.format("http://localhost:%d",proxyPort));
		mangaTextureRequest.Proxy = mHttpProxy(proxyUri)
	end
	return mangaTextureRequest;
end

function PicaExtensions.GetPostRequest(nurl)
	local timeStr =  math.floor( (tostring(timeHelper.ClientNow()) + 0)/1000);
	local nonce = systemGuid.NewGuid():ToString();
	nonce = stringHelper.Replace(nonce,"-","");
	local mangaTextureRequest = mHTTPRequest(nil,httpMethod.Post);
	PicaExtensions.SetHeader(mangaTextureRequest,nurl,"POST",nonce,timeStr);
	mangaTextureRequest:SetHeader("authorization", token);
	local url = "https://picaapi.picacomic.com/" .. nurl;
	local uri = mUri(url);
	mangaTextureRequest.Uri = uri;
	if proxyPort ~= 0 then
		local proxyUri = mUri(string.format("http://localhost:%d",proxyPort));
		mangaTextureRequest.Proxy = mHttpProxy(proxyUri)
	end
	return mangaTextureRequest;
end

function PicaExtensions.GetRequest(nurl)
	if ifLoginSuccess == false then
		uiHelper.ShowTipsUI("登录失败");
		return nil;
	end
	local timeStr =  math.floor((tostring(timeHelper.ClientNow()) + 0)/1000) ;
	print(timeStr)
	local nonce = systemGuid.NewGuid():ToString();
	nonce = stringHelper.Replace(nonce,"-","");
	local mangaTextureRequest = mHTTPRequest(nil,httpMethod.Get);
	PicaExtensions.SetHeaderWithAuthorization(mangaTextureRequest,nurl,"GET",nonce,timeStr);
	local url = "https://picaapi.picacomic.com/" .. nurl;
	local uri = mUri(url);
	mangaTextureRequest.Uri = uri;
	if proxyPort ~= 0 then
		local proxyUri = mUri(string.format("http://localhost:%d",proxyPort));
		mangaTextureRequest.Proxy = mHttpProxy(proxyUri)
	end
	return mangaTextureRequest;
end

function PicaExtensions.GetPicRequest(nurl)
	if ifLoginSuccess == false then
		uiHelper.ShowTipsUI("登录失败");
		return nil;
	end
	local timeStr =  math.floor((tostring(timeHelper.ClientNow()) + 0)/1000) ;
	local nonce = systemGuid.NewGuid():ToString();
	nonce = stringHelper.Replace(nonce,"-","");
	local mangaTextureRequest = mHTTPRequest(nil,httpMethod.Get);
	PicaExtensions.SetHeaderWithAuthorization(mangaTextureRequest,nurl,"GET",nonce,timeStr);
	local url = "https://storage1.picacomic.com/static/" .. nurl;
	local uri = mUri(url);
	mangaTextureRequest.Uri = uri;
	if proxyPort ~= 0 then
		local proxyUri = mUri(string.format("http://localhost:%d",proxyPort));
		mangaTextureRequest.Proxy = mHttpProxy(proxyUri)
	end
	return mangaTextureRequest;
end

function PicaExtensions.GetTextureRequest(url)
	return PicaExtensions.GetPicRequest(url);
end
function PicaExtensions.RequestGenreManga(url,page)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText);
		local jsonStr = json.decode(resq.Response.DataAsText)
		if jsonStr["code"] ~= 200 then
			print("错误代码" .. jsonStr);
			ifLoginSuccess = false;
			uiHelper.ShowTipsUI("错误代码" .. jsonStr["code"]);
		else
			local list = {};
			for k,v in ipairs(jsonStr["data"]["comics"]["docs"]) do
				local tempData = mangaData.New();
				tempData.id = v["_id"].. "";
				tempData.title = v["title"]
				tempData.authors = v["author"]
				tempData.cover = v["thumb"]["path"]
				tempData.url = string.format("comics/%s", v["_id"].. "")
				tempData.source = "9988005021315885225";
				table.insert(list,tempData);
			end
			globalHelper.OnGenreRequestComplete(list)
		end	
	end
	local encodeUrl = PicaExtensions.UrlEncode(url);
	local nurl = string.format("comics?page=%d&c=%s&s=%s",page,encodeUrl,sortType)
	local request = PicaExtensions.GetRequest(nurl);
	request.Callback = callBack;
	request:Send();
end

function PicaExtensions.UrlEncode(s)  
	s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
   return string.gsub(s, " ", "+")  
end  

function PicaExtensions.RequestMangaPageList(url,detail,chapterDa)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText);
		local info = json.decode(resq.Response.DataAsText)
		if info["code"] ~= 200 then
			print("错误代码" .. info);
			ifLoginSuccess = false;
			uiHelper.ShowTipsUI("错误代码" .. info["code"]);
		else
			local tempData = pageAllData.New();
			tempData.source = "9988005021315885225";
			local data = PageData.New();
			tempData.chapter = data;
			data.chapter_name = info["data"]["ep"]["title"];
			for k,v in ipairs ( info["data"]["pages"]["docs"]) do
				data.page_url:Add(v["media"]["path"]);
			end
			globalHelper.OnMangaPagesPhraseComplete(url,tempData,detail,chapterDa)
		end
	end
	print(url)
	local request = PicaExtensions.GetRequest(url);
	request.Callback=callBack;
	request:Send();
end

function PicaExtensions.StrightGetMangaDetail(mangaId)
	PicaExtensions.RequestMangaDetail(string.format("comics/%s", mangaId));
end

function PicaExtensions.UpdateManga(url)
	print(url);
	local request = PicaExtensions.GetRequest(url);
	request:Send();
	return request;
end

function PicaExtensions.Update(resq,url)
	if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			print("OnError")
			return;
		end
	local info = json.decode(resq.Response.DataAsText)
	if info["code"] ~= 200 then
		print("错误代码" .. info);
		ifLoginSuccess = false;
		uiHelper.ShowTipsUI("错误代码" .. info["code"]);
		return nil;
	else
		local detailData = mangaDetail.New();
		detailData.id = info["data"]["comic"]["_id"];
		detailData.title = info["data"]["comic"]["title"];
		print(info["data"]["comic"]["title"])
		detailData.url = url;
		detailData.cover = info["data"]["comic"]["thumb"]["path"];
		detailData.last_updatetime =  PicaExtensions.CaculateTime(info["data"]["comic"]["updated_at"]);
		detailData.source = "9988005021315885225";
		detailData.authors = info["data"]["comic"]["author"];
		detailData.description = info["data"]["comic"]["description"]
		if info["data"]["comic"]["finished"] == true then
			detailData.status = "完结";
		else
			detailData.status = "连载";
		end
		detailData.types = info["data"]["comic"]["categories"][0];
		PicaExtensions.GetChapterInfosWithoutEvent(detailData,1,info["data"]["comic"]["epsCount"] + 0)
		return detailData;
	end	
end

function PicaExtensions.GetChapterInfosWithoutEvent(mangaDetail,startIndex,page)
	if startIndex <= page  then
		local callBack = function( resq,resp)
			if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
			or  resq.State == httpStates.TimedOut 
			then
				print("Error")
				return;
			end
			print(resq.Response.DataAsText);
			local info = json.decode(resq.Response.DataAsText)
			if info["code"] ~= 200 then
				print("错误代码" .. info);
				ifLoginSuccess = false;
				uiHelper.ShowTipsUI("错误代码" .. info["code"]);
			else
				local tempChapter = chapterList();
				mangaDetail.chapters:Add(tempChapter)
				for k,v in ipairs(info["data"]["eps"]["docs"]) do
					local tempData = chapterData();
					print(v["order"]);
					tempData.chapter_id = v["order"].. "";
					tempData.chapter_title = v["title"];
					tempData.updatetime = PicaExtensions.CaculateTime(v["updated_at"]);
					tempData.source = "9988005021315885225";
					tempData.url = string.format("comics/%s/order/%s/pages?page=%d",mangaDetail.id,v["order"].. "",info["data"]["eps"]["page"]) 
					tempChapter.data:Add(tempData);
				end
				if startIndex == page then
				else
					PicaExtensions.GetChapterInfos(mangaDetail,startIndex +1,page)
				end
	
			end
		end
		local exUrl = string.format("/eps?page=%d",startIndex)
		local request = PicaExtensions.GetRequest(mangaDetail.url..exUrl);
		request.Callback = callBack;
		request:Send();
	end
end

function PicaExtensions.GetGenreTable()
	return {
		嗶咔漢化 = "嗶咔漢化",
		全彩 = "全彩",
		長篇 = "長篇",
		同人 = "同人",
		短篇 = "短篇",
		圓神領域 = "圓神領域",
		碧藍幻想 = "碧藍幻想",
		CG雜圖 = "CG雜圖",
		生肉 = "生肉",
		純愛 = "純愛",
		百合花園 = "百合花園",
		耽美花園 = "耽美花園",
		偽娘哲學 = "偽娘哲學",
		後宮閃光 = "後宮閃光",
		扶他樂園 = "扶他樂園",
		單行本 = "單行本",
		姐姐系 = "姐姐系",
		妹妹系 = "妹妹系",
		SM = "SM",
		性轉換 = "性轉換",
		足の恋 = "足の恋",
		重口地帶 = "重口地帶",
		人妻 = "人妻",
		NTR = "NTR",
		強暴 = "強暴",
		非人類 = "非人類",
		艦隊收藏 = "艦隊收藏",
		Fate = "Fate",
		東方 = "東方",
		禁書目錄 = "禁書目錄",
		歐美 = "歐美",
	};
end

function PicaExtensions.GetSettingDic()
	local table = {
		list_sortype = {
			默认="ua",
			新到旧="dd",
			旧到新="da",
			最多爱心="ld",
			最多指名="vd",
		},
		text_proxy = 0;
	};
	return table;
end

function PicaExtensions.GetCurrentSettingValue(pa)
	if pa == "sortype" then
		return sortType  .. "";
	elseif pa == "proxy" then
		return proxyPort .. "";
	end
end

function PicaExtensions.SetSettingValue(key,value)
	if key == "sortype" then
		sortType = value;
		playerPrefs.SetString("PicaSortType",sortType)
	elseif key == "proxy" then
		proxyPort = value + 0 ;
		playerPrefs.SetInt("PicaPort",proxyPort)
	end
	print(key,value)
end

return PicaExtensions;