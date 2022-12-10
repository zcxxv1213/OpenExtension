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
	
	if playerPrefs.HasKey("ZeroPort") then
		proxyPort = playerPrefs.GetInt("ZeroPort")
	end
end

function ZeroExtensions.GetRequest(url)
	local mangaTextureRequest = mHTTPRequest(mUri(url));
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
	print(string.format("http://www.zerobywblac.com%s",url))
	local request = ZeroExtensions.GetRequest(string.format("http://www.zerobywblac.com%s",url));
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
	print(string.format("http://www.zerobywblac.com%s",url))
	local request = ZeroExtensions.GetRequest(string.format("http://www.zerobywblac.com%s",url));
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
	local request = ZeroExtensions.GetRequest(string.format("http://www.zerobywblac.com./plugin.php?id=jameson_manhua&a=search&c=index&keyword=%s&page=%s",query,1));
	request.Callback=callBack;
	request:Send();
end

function ZeroExtensions.GetGenreTable()
	return {
		First = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&&page=%s",
		卖肉 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=1&page=%s",
		日常 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=32&page=%s",
		后宫 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=6&page=%s",
		搞笑 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=13&page=%s",
		爱情 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=31&page=%s",
		冒险 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=22&page=%s",
		奇幻 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=23&page=%s",
		战斗 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=26&page=%s",
		体育 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=29&page=%s",
		机战 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=34&page=%s",
		职业 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=35&page=%s",
		汉化组跟上，不再更新 = "http://www.zerobywblac.com/plugin.php?id=jameson_manhua&c=index&a=ku&category_id=36&page=%s",
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
