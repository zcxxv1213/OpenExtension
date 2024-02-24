local json = require 'cjson'
local ZeroExtensions = {};
local playerPrefs = UnityEngine.PlayerPrefs;
local mHttpProxy = BestHTTP.HTTPProxy;
local source = "4444190037559093788";
local proxyPort = 0;
local mUri = System.Uri;
local mHTTPRequest = BestHTTP.HTTPRequest;
local httpStates = BestHTTP.HTTPRequestStates;
local htmlHelper = HtmlHelper;
local mangaData = MangaData;
local globalHelper = GlobalHelper;
local mangaDetail = MangaDetail;
local chapterList = ChapterList;
local chapterData = ChapterData;
local pageAllData = PageAllData;
local stringHelper = StringHelper;
local formUsage = BestHTTP.Forms.HTTPFormUsage;
local httpMethod = BestHTTP.HTTPMethods;
local uiHelper = UIHelper;
local ifLoginSuccess = false;
local playerPrefs = UnityEngine.PlayerPrefs;
local cookiseResultStr = "";
function ZeroExtensions.GetVersion()
	return 2;
end

function ZeroExtensions.GetType()
	return 0;
end

function ZeroExtensions.GetExtensionNum()
	return source;
end

function ZeroExtensions.GetExtensionName()
	return "Zero搬运";
end
function ZeroExtensions.Init()
	if playerPrefs.HasKey("ZeroCookies") then
		local tempCookies = playerPrefs.GetString("ZeroCookies")
		ZeroExtensions.PhraseCookies(tempCookies);
		ifLoginSuccess = true;
	end

	if playerPrefs.HasKey("ZeroPort") then
		proxyPort = playerPrefs.GetInt("ZeroPort")
	end
end

function ZeroExtensions.PhraseCookies(cookStrings)
	print(cookStrings)
	local strs = stringHelper.RexMatchAll(cookStrings,"cutline","cutend");
	local cookiesTable = {};
	for i = 0, strs.Count-  1, 1 do
		local result = stringHelper.Replace(strs[i],"cutline","");
		result = stringHelper.Replace(result,"cutend","");
		table.insert(cookiesTable,result);
		if i ~= 0 then
			cookiseResultStr = cookiseResultStr..";";
		end
		cookiseResultStr = cookiseResultStr..result;
	end
end

function ZeroExtensions.CheckIfLoginSuccess()
	return ifLoginSuccess;
end

function ZeroExtensions.IfCanLogin()
	return true;
end

function ZeroExtensions.Login(mail,pass)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			uiHelper.ShowTipsUI("登录失败");
			print(resq.Response.DataAsText)
			return;
		end
		print(resq.Response.DataAsText)
		local result = string.find(resq.Response.DataAsText,mail);
		if result then
			print(resq.Response.Cookies:ToString())
			ZeroExtensions.SaveCookies(resq.Response.Cookies)
			uiHelper.ShowTipsUI("登录成功");
			return;
		end

		local regexStrs = stringHelper.RexMatchAll(resq.Response.DataAsText,"loginhash=","\">");
		local loginHashResult = "";
		local loginFormhash = "";
		for i = 0, regexStrs.Count - 1, 1 do
			print(regexStrs[i])
			local temp = stringHelper.Replace(regexStrs[i],"loginhash=","");
			temp = stringHelper.Replace(temp,">","");
			temp = stringHelper.Replace(temp,"\"","");
			loginHashResult = temp;
			break;
		end

		local regexStrs = stringHelper.RexMatchAll(resq.Response.DataAsText,"name=\"formhash\"",">");
		for i = 0, regexStrs.Count - 1, 1 do
			local valueText = stringHelper.RexMatchAll(regexStrs[i],"value=\"","\"");
			local temp = stringHelper.Replace(valueText[0],"value=\"","");
			temp = stringHelper.Replace(temp,"\"","");
			loginFormhash = temp;
			break;
		end
		ZeroExtensions.DoLogin(mail,pass,loginHashResult,loginFormhash);
		print(loginHashResult,loginFormhash)
	end
	print(1)
	local request = ZeroExtensions.GetRequest("http://www.zerobywns.com/member.php?mod=logging&action=login&infloat=yes&frommessage&inajax=1&ajaxtarget=messagelogin");
	request.Callback=callBack;
	request:Send();
	return request;
end

function ZeroExtensions.SaveCookies(cookie)
	local cookiesText = "";
	for i = 0, cookie.Count -1, 1 do
		cookiesText = cookiesText .. "cutline"..cookie[i]:ToString().."cutend";
		print(cookiesText)
	end
	playerPrefs.SetString("ZeroCookies",cookiesText);

	ZeroExtensions.PhraseCookies(cookiesText);
end

function ZeroExtensions.DoLogin(mail,pass,loginHashResult,loginFormhash)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			uiHelper.ShowTipsUI("登录失败");
			print(resq.Response.DataAsText)
			return;
		end
		print(resq.Response.DataAsText)
		ZeroExtensions.SaveCookies(resq.Response.Cookies)
		uiHelper.ShowTipsUI("登录成功");
		--[[local jsonStr = json.decode(resq.Response.DataAsText)
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
		end--]]
	end
	local mangaTextureRequest = mHTTPRequest(nil,httpMethod.Post);
	mangaTextureRequest.FormUsage = formUsage.UrlEncoded;
	mangaTextureRequest:AddField("formhash",loginFormhash)
	mangaTextureRequest:AddField("loginfield","username")

	mangaTextureRequest:AddField("username",mail)
	mangaTextureRequest:AddField("password",pass)
	mangaTextureRequest:AddField("questionid","0")
	mangaTextureRequest:AddField("answer","")

	mangaTextureRequest:AddField("referer","http://www.zerobywns.com/home.php?mod=spacecp&ac=usergroup")
	mangaTextureRequest:SetHeader("Content-Type", "application/x-www-form-urlencoded");
	mangaTextureRequest:SetHeader("Content-Length", "178");
	mangaTextureRequest:SetHeader("User-Agent","okhttp/3.8.1");
	mangaTextureRequest:SetHeader("Cookie","Ckng_2132_sid=YgvGIe; Ckng_2132_saltkey=Fw1BW1QJ; Ckng_2132_lastvisit=1682344319; Ckng_2132__refer=%252Fhome.php%253Fmod%253Dspacecp%2526ac%253Dusergroup; Ckng_2132_sendmail=1; Ckng_2132_lastact=1682347919%09member.php%09logging");
	mangaTextureRequest:SetHeader("Host","www.zerobywns.com");
	mangaTextureRequest:SetHeader("Origin","www.zerobywns.com");

	mangaTextureRequest:SetHeader("referer", "http://www.zerobywns.com/home.php?mod=spacecp&ac=usergroup");
	local url = string.format("http://www.zerobywns.com/member.php?mod=logging&action=login&loginsubmit=yes&frommessage&loginhash=%s&inajax=1",loginHashResult)
	local uri = mUri(url);
	print(url)
	mangaTextureRequest.Uri = uri;
	local jsonTable = {
		formhash = loginFormhash,
		referer= "http://www.zerobywns.com/home.php?mod=spacecp&ac=usergroup",
		loginfield =  "username",
		username = mail ,
		password = pass ,
		questionid=0,
		answer="",
	}
	local jsonStr = json.encode(jsonTable);
	print(jsonStr)
	mangaTextureRequest.Callback = callBack;
	mangaTextureRequest:Send();
end

function ZeroExtensions.UrlEncode(s)  
	s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
   return string.gsub(s, " ", "+")  
end  

function ZeroExtensions.GetRequest(url)
	local mangaTextureRequest = mHTTPRequest(mUri(url));
	print(cookiseResultStr)
	if cookiseResultStr then
		mangaTextureRequest:SetHeader("Cookie",cookiseResultStr);
	end
	mangaTextureRequest.Tag = url;
	print(url)
	if proxyPort ~= 0 then
		local proxyUri = mUri(string.format("http://localhost:%d",proxyPort));
		mangaTextureRequest.Proxy = mHttpProxy(proxyUri)
	end

	return mangaTextureRequest;
end

function ZeroExtensions.GetTextureRequest(url)
	return ZeroExtensions.GetRequest(url);
end
function ZeroExtensions.RequestGenreManga(url,page)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		--print(resq.Response.DataAsText)
		local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
		local selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.uk-card");
		--print(selectElement.Count)
		local list={};
		for i = 0, selectElement.Count - 1, 1 do
			local tempData = mangaData.New();
			local temp = htmlHelper.ElementQuerySelect(selectElement[i],"img");
			temp = temp[0]:GetAttribute("src")
			tempData.source = source;
			local temp1 = htmlHelper.ElementQuerySelect(selectElement[i],"p.mt5 > a");
			tempData.title = temp1[0].TextContent;
			tempData.cover = temp;
			
			--print(temp1[0]:GetAttribute("href"))
			tempData.url = temp1[0]:GetAttribute("href");
			table.insert(list,tempData);
		end
		
		globalHelper.OnGenreRequestComplete(list)
	end
	print(string.format(url,page))
	local request = ZeroExtensions.GetRequest(string.format(url,page));
	request.Callback=callBack;
	request:Send();
end
function ZeroExtensions.RequestMangaDetail(url)
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
		local selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.uk-width-medium > img");
		print(selectElement[0]:GetAttribute("src"))

		detailData.cover = selectElement[0]:GetAttribute("src");

		detailData.url = url;
		local result1 = htmlHelper.DocumentQuerySelectItems(document,"li > div.uk-alert");
		detailData.description = result1[0].TextContent;


		local author = htmlHelper.DocumentQuerySelectItems(document,"div.cl > a.uk-label");
		detailData.authors = author[0].TextContent;

		local regexStrs = stringHelper.RexMatchAll(resq.Response.DataAsText,"<title>","</title>");
		print(regexStrs[0])
		local result = stringHelper.Replace(regexStrs[0],"<title>","");
		result = stringHelper.Replace(result,"</title>","");
		detailData.title = result;

		local tempChapter = chapterList();
		detailData.chapters:Add(tempChapter)
		detailData.source = source;
		selectElement = htmlHelper.DocumentQuerySelectItems(document,"div.uk-grid-collapse > div.muludiv");
		print(selectElement.Count)
		for i = 0, selectElement.Count - 1, 1 do
			local tempData = chapterData();
			local temp = htmlHelper.ElementQuerySelect(selectElement[i],"a.uk-button-default");
			tempData.chapter_title = temp[0].TextContent;
			tempData.url = temp[0]:GetAttribute("href")
			tempData.source = source;
			tempChapter.data:Add(tempData);
		end
		tempChapter.data:Reverse();
		globalHelper.OnMangaDetailPhraseComplete(detailData)
	end
	print(string.format("http://www.zerobywns.com%s",url))
	local request = ZeroExtensions.GetRequest(string.format("http://www.zerobywns.com%s",url));
	request.Callback=callBack;
	request:Send();
end

function ZeroExtensions.RequestMangaPageList(url,detail,chapterDa)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText)
		local tempData = pageAllData.New();
		tempData.source = source;
		local data = PageData.New();
		tempData.chapter = data;
		data.chapter_name = "";

		local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
		local imageDatas = htmlHelper.DocumentQuerySelectItems(document,"div.uk-text-center > img");
		if imageDatas.Count ~= 0 then
			for i = 0, imageDatas.Count - 1, 1 do
				data.page_url:Add(imageDatas[i]:GetAttribute("src"));
			end
		end
		globalHelper.OnMangaPagesPhraseComplete(url,tempData,detail,chapterDa)
	end
	print(string.format("http://www.zerobywns.com%s",url))
	local request = ZeroExtensions.GetRequest(string.format("http://www.zerobywns.com%s",url));
	request.Callback=callBack;
	request:Send();
end

function ZeroExtensions.RequestSearchManga(query)
	local callBack = function( resq,resp)
		if resq.State == httpStates.Aborted or resq.State == httpStates.Error or  resq.State == httpStates.ConnectionTimedOut 
		or  resq.State == httpStates.TimedOut 
		then
			return;
		end
		print(resq.Response.DataAsText)
		local document = htmlHelper.ParseHTMLStr(resq.Response.DataAsText);
		local selectElement = htmlHelper.DocumentQuerySelectItems(document,"a.uk-card, div.uk-card");
		print(selectElement.Count)
		local list={};
		for i = 0, selectElement.Count - 1, 1 do
			local tempData = mangaData.New();
			local temp = htmlHelper.ElementQuerySelect(selectElement[i],"p.mt5");
			print(temp[0].TextContent)
			tempData.title = temp[0].TextContent;
			tempData.source = source;

			local tempImg = htmlHelper.ElementQuerySelect(selectElement[i],"img");
			temp = tempImg[0]:GetAttribute("src")
			tempData.cover = temp;
			
			local tempUrl = htmlHelper.ElementQuerySelect(selectElement[i],"href");
			print(selectElement[i].OuterHtml)
			local regexStrs = stringHelper.RexMatchAll(selectElement[i].OuterHtml,"kuid",">");
			print(regexStrs[0])
			local temp = stringHelper.Replace(regexStrs[0],"kuid=","");
			temp = stringHelper.Replace(temp,"\"","");
			temp = stringHelper.Replace(temp,">","");
			tempData.url = string.format("/plugin.php?id=jameson_manhua&c=index&a=bofang&kuid=%s",temp)
			print(tempData.url)
			table.insert(list,tempData);
		end
		globalHelper.OnSearch(source,list)
	end
	print(query)
	print(globalHelper.GetCurrentSearchText())
 
	local utf8String = hexToUtf8String(globalHelper.GetCurrentSearchText())  
	print(utf8String)
	local request = ZeroExtensions.GetRequest(string.format("http://www.zerobywns.com/plugin.php?id=jameson_manhua&a=search&c=index&keyword=%s&page=%s",utf8String,1));
	request.Callback=callBack;
	request:Send();
end
function hexToUtf8Char(hexByte1, hexByte2)  
    -- 将每个十六进制数字转换为一个字节  
    local byte1 = tonumber(hexByte1, 16)  
    local byte2 = tonumber(hexByte2, 16)  
  
    -- 如果任一转换失败，返回nil  
    if byte1 == nil or byte2 == nil then  
        return nil  
    end  
  
    -- 返回由两个字节组成的字符串  
    return string.char(byte1, byte2)  
end  
  
function hexToUtf8String(hexStr)  
    -- 去除尾部的逗号（如果存在）  
    if hexStr:sub(-1) == "," then  
        hexStr = hexStr:sub(1, -2)  
    end  
  
    -- 按逗号分割字符串以获取每个字节对  
    local bytePairs = {}  
    for pair in hexStr:gmatch("(%w+),(%w+)") do  
        table.insert(bytePairs, pair)  
    end  
  
    -- 转换每个字节对到UTF-8并构建字符串  
    local utf8Str = ""  
    for i = 1, #bytePairs, 2 do  
        local hexByte1 = bytePairs[i]  
        local hexByte2 = bytePairs[i + 1]  
        local utf8Char = hexToUtf8Char(hexByte1, hexByte2)  
        if utf8Char then  
            utf8Str = utf8Str .. utf8Char  
        else  
            -- 如果转换失败，打印错误信息并跳过  
            print("Invalid hex pair: " .. hexByte1 .. "," .. hexByte2)  
        end  
    end  
  
    return utf8Str  
end  
function ZeroExtensions.GetGenreTable()
	return {
		First = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&&page=%s",
		卖肉 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=1&page=%s",
		日常 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=32&page=%s",
		后宫 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=6&page=%s",
		搞笑 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=13&page=%s",
		爱情 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=31&page=%s",
		冒险 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=22&page=%s",
		奇幻 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=23&page=%s",
		战斗 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=26&page=%s",
		体育 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=29&page=%s",
		机战 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=34&page=%s",
		职业 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=35&page=%s",
		汉化组跟上，不再更新 = "http://www.zerobywns.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=36&page=%s",
	};
end

function ZeroExtensions.GetSettingDic()
	local table = {
		text_proxyPort = 0;
	};
	return table;
end


function ZeroExtensions.GetCurrentSettingValue(pa)
	if pa == "proxyPort" then
		return proxyPort .. "";
	end
end


function ZeroExtensions.SetSettingValue(key,value)
	if key == "proxyPort" then
		proxyPort = value + 0 ;
		playerPrefs.SetInt("ZeroPort",proxyPort)
	end
	print(key,value)
end


return ZeroExtensions;
