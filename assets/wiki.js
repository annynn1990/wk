let wikiData=[];

const categoryDescriptions={
  "國家":"國號、基本資料與整體概況","歷史":"歷史時期、事件與年表","政治":"政治制度、政黨與選舉",
  "政府":"政府機關、內閣與行政部門","法律與憲政":"憲法、法律與制度文件","皇室":"君主、皇室與宮廷制度",
  "人物":"重要人物與歷史人物","地理":"地區、城市與地理資料","地方":"省、特區與地方行政",
  "外交":"外交關係與國際交流","組織":"組織、團體與機構","經濟":"經濟制度與公共財政","貨幣":"黃名貨幣與金融制度",
  "文化":"文化、藝術與傳統","語言":"黃名文、國語與其他語言","國家象徵":"國旗、國徽、國歌與國家標誌",
  "軍事與安全":"安全、保安與軍事制度","宗教":"宗教與相關組織","媒體":"報刊、出版與新聞媒體",
  "科技與網路":"論壇、網站與數位社群","社會":"公民、人口與社會生活","活動":"節慶、紀念日與公共活動",
  "獎章榮典":"勳章、爵位與榮典","選舉":"選舉制度與政治參與","公民":"公民資格、權利與義務","微國家":"微型國家與相關社群"
};

async function loadWiki(){
  if(wikiData.length)return wikiData;
  const r=await fetch("data/articles.json",{cache:"no-store"});
  if(!r.ok)throw new Error("無法載入百科資料");
  wikiData=await r.json();
  return wikiData;
}
const load=loadWiki;

function esc(s){
  return String(s??"").replace(/[&<>"']/g,function(m){
    return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[m];
  });
}
const E=esc;

function articleById(id,d){return d.find(function(a){return a.id===id})||d[0];}
function stripHtml(s){return String(s||"").replace(/<[^>]*>/g," ").replace(/\s+/g," ");}

function searchArticles(q,d){
  q=(q||"").trim().toLowerCase();
  if(!q)return d;
  return d.filter(function(a){
    return (a.title+" "+a.summary+" "+(a.categories||[]).join(" ")+" "+stripHtml(a.content||"")).toLowerCase().includes(q);
  });
}

function articleUrl(id,action){
  return "article.html?id="+encodeURIComponent(id)+(action?"&action="+encodeURIComponent(action):"");
}

function bindWikiChrome(d){
  const layout=document.querySelector(".mw-layout");
  const menu=document.querySelector("#mwMenu");
  if(menu)menu.onclick=function(){if(layout)layout.classList.toggle("nav-open")};
  const random=document.querySelector("#randomEntry");
  if(random&&d.length)random.onclick=function(){
    location.href=articleUrl(d[Math.floor(Math.random()*d.length)].id);
  };
  document.querySelectorAll("[data-wiki-search]").forEach(function(input){
    input.addEventListener("keydown",function(e){
      if(e.key==="Enter"){
        const q=e.target.value.trim();
        location.href="articles.html"+(q?"?q="+encodeURIComponent(q):"");
      }
    });
  });
}

function buildInfobox(a){
  if(!a.infobox)return "";
  return '<aside class="mw-infobox">'+
    '<div class="mw-infobox-title">'+esc(a.title)+'</div>'+
    '<table>'+Object.entries(a.infobox).map(function(e){
      return '<tr><td>'+esc(e[0])+'</td><td>'+esc(e[1])+'</td></tr>';
    }).join("")+'</table></aside>';
}

function buildTocAndContent(html){
  const temp=document.createElement("div");
  temp.innerHTML=html||"";
  const hs=Array.from(temp.querySelectorAll("h2,h3"));
  if(hs.length<2)return {html:temp.innerHTML,toc:""};
  let h2=0,h3=0;
  const rows=[];
  hs.forEach(function(h){
    if(h.tagName==="H2"){h2++;h3=0;h.id="mw-sec-"+h2;rows.push({h:h,label:h2+". "+h.textContent})}
    else{h3++;h.id="mw-sec-"+h2+"-"+h3;rows.push({h:h,label:h2+"."+h3+" "+h.textContent})}
  });
  const toc='<div class="mw-toc"><div class="mw-toc-title">目錄</div>'+
    rows.map(function(r){return '<a class="'+(r.h.tagName==="H3"?"l3":"")+'" href="#'+r.h.id+'">'+esc(r.label)+'</a>'}).join("")+
    '</div>';
  return {html:temp.innerHTML,toc:toc};
}

function articleShell(a,activeTab){
  return '<div class="mw-breadcrumb"><a href="./">首頁</a> / <a href="articles.html">條目</a> / '+esc(a.title)+'</div>'+
    '<div class="mw-tabs-row">'+
      '<div class="mw-tabs"><a class="mw-tab '+(activeTab==="article"?"active":"")+'" href="'+articleUrl(a.id)+'">條目</a><a class="mw-tab '+(activeTab==="talk"?"active":"")+'" href="'+articleUrl(a.id,"talk")+'">討論</a></div>'+
      '<div class="mw-actions"><a class="mw-action" href="'+articleUrl(a.id)+'">閱讀</a><a class="mw-action" href="edit.html?article='+encodeURIComponent(a.id)+'">編輯</a><a class="mw-action" href="'+articleUrl(a.id,"history")+'">查看歷史</a></div>'+
    '</div>'+
    '<h1 class="mw-title">'+esc(a.title)+'</h1><div class="mw-subtitle">出自黃名帝國百科</div>';
}

function renderArticle(){
  loadWiki().then(function(d){
    const p=new URLSearchParams(location.search);
    const id=p.get("id")||"wongming-empire";
    const action=p.get("action")||"view";
    const a=articleById(id,d);
    document.title=a.title+"｜黃名帝國百科";
    const host=document.querySelector("#article");
    if(!host)return;

    let html=articleShell(a,action==="talk"?"talk":"article");

    if(action==="talk"){
      html+='<div class="mw-content-grid"><article class="mw-article">'+
        '<div class="classic-note"><b>討論頁</b><br>本百科目前採 GitHub Pages 架構，尚未內建 MediaWiki 式討論頁。條目修訂建議可透過本專案的 GitHub Issues 提出。</div>'+
        '<p>你可以返回條目閱讀內容，或進入編輯器修改本文。</p>'+
        '</article><aside><div class="mw-sidebox"><h3>本條目</h3><div class="inner"><a href="'+articleUrl(a.id)+'">閱讀</a><br><a href="edit.html?article='+encodeURIComponent(a.id)+'">編輯</a><br><a href="'+articleUrl(a.id,"history")+'">查看歷史</a></div></div></aside></div>';
      host.innerHTML=html;
      bindWikiChrome(d);
      return;
    }

    if(action==="history"){
      html+='<div class="mw-content-grid"><article class="mw-article">'+
        '<h2 style="margin-top:0">版本歷史</h2>'+
        '<div class="mw-history"><div class="mw-history-row"><b>目前版本</b><span>百科內容儲存在 data/articles.json，並透過 Git commit 保存。</span></div>'+
        '<div class="mw-history-row"><b>Git 版本紀錄</b><span><a target="_blank" rel="noopener" href="https://github.com/annynn1990/wk/commits/main/data/articles.json">查看資料檔完整版本紀錄</a></span></div></div>'+
        '</article><aside><div class="mw-sidebox"><h3>本條目</h3><div class="inner"><a href="'+articleUrl(a.id)+'">閱讀</a><br><a href="edit.html?article='+encodeURIComponent(a.id)+'">編輯</a></div></div></aside></div>';
      host.innerHTML=html;
      bindWikiChrome(d);
      return;
    }

    const toc=buildTocAndContent(a.content||"");
    const events=a.events&&a.events.length?
      '<h2>相關年表</h2><div class="mw-history">'+a.events.map(function(e){
        return '<div class="mw-history-row"><b>'+esc(e.date)+'</b><span>'+esc(e.text)+'</span></div>';
      }).join("")+'</div>':"";
    const sources=a.sources&&a.sources.length?
      '<h2>參考資料</h2><ol class="mw-source-list">'+a.sources.map(function(s){return '<li>'+esc(s)+'</li>'}).join("")+'</ol>':"";
    const cats=(a.categories||[]).map(function(c){
      return '<a class="mw-category" href="category.html?name='+encodeURIComponent(c)+'">'+esc(c)+'</a>';
    }).join(" · ");

    html+='<div class="mw-content-grid"><article class="mw-article">'+
      buildInfobox(a)+
      '<p class="mw-lead">'+esc(a.summary||"")+'</p>'+
      toc.toc+toc.html+
      events+sources+
      '<div class="mw-categories"><b>分類：</b> '+cats+'</div>'+
      '</article><aside>'+
      '<div class="mw-sidebox"><h3>本條目</h3><div class="inner"><a href="'+articleUrl(a.id)+'">閱讀</a><br><a href="'+articleUrl(a.id,"talk")+'">討論</a><br><a href="edit.html?article='+encodeURIComponent(a.id)+'">編輯</a><br><a href="'+articleUrl(a.id,"history")+'">查看歷史</a></div></div>'+
      '<div class="mw-sidebox"><h3>快速導覽</h3><div class="inner"><a href="articles.html">所有條目</a><br><a href="categories.html">分類</a><br><a href="timeline.html">大事記</a></div></div>'+
      '</aside></div>';
    host.innerHTML=html;
    bindWikiChrome(d);
  });
}

function renderSearch(){
  loadWiki().then(function(d){
    const q=new URLSearchParams(location.search).get("q")||"";
    const hits=searchArticles(q,d);
    const input=document.querySelector("#q");
    if(input)input.value=q;
    const count=document.querySelector("#searchCount");
    if(count)count.textContent=q?'搜尋「'+q+'」：'+hits.length+' 個結果':'所有條目：'+hits.length+' 個條目';
    const box=document.querySelector("#list");
    if(box)box.innerHTML=hits.map(function(a){
      return '<div class="mw-index-row"><a href="article.html?id='+encodeURIComponent(a.id)+'">'+esc(a.title)+'</a><p>'+esc(a.summary||"")+'</p></div>';
    }).join("")||"<p>找不到符合的條目。</p>";
    bindWikiChrome(d);
  });
}

function renderCategory(){
  loadWiki().then(function(d){
    const name=new URLSearchParams(location.search).get("name")||"未指定分類";
    const hits=d.filter(function(a){return (a.categories||[]).includes(name)});
    const title=document.querySelector("#title"),crumb=document.querySelector("#crumb"),count=document.querySelector("#count"),list=document.querySelector("#list");
    document.title=name+"｜黃名帝國百科";
    if(title)title.textContent=name;
    if(crumb)crumb.textContent=name;
    if(count)count.textContent=(categoryDescriptions[name]||"百科分類")+" · "+hits.length+" 個條目";
    if(list)list.innerHTML=hits.map(function(a){
      return '<div class="mw-index-row"><a href="article.html?id='+encodeURIComponent(a.id)+'">'+esc(a.title)+'</a><p>'+esc(a.summary||"")+'</p></div>';
    }).join("")||"<p>目前沒有條目。</p>";
    bindWikiChrome(d);
  });
}

function renderCategories(){
  loadWiki().then(function(d){
    const map={};
    d.forEach(function(a){(a.categories||[]).forEach(function(c){(map[c]??=[]).push(a)})});
    const el=document.querySelector("#cats");
    if(el)el.innerHTML=Object.keys(map).sort(function(a,b){return a.localeCompare(b,"zh-Hant")}).map(function(c){
      return '<div class="mw-index-row"><a href="category.html?name='+encodeURIComponent(c)+'">'+esc(c)+'</a> <span style="color:#72777d">（'+map[c].length+'）</span><p>'+esc(categoryDescriptions[c]||"相關百科條目")+'</p></div>';
    }).join("");
    bindWikiChrome(d);
  });
}

function renderTimeline(){
  loadWiki().then(function(d){
    const ev=d.flatMap(function(a){return (a.events||[]).map(function(e){return Object.assign({},e,{a:a})})}).sort(function(a,b){return a.date.localeCompare(b.date)});
    const box=document.querySelector("#timeline");
    if(box)box.innerHTML=ev.map(function(e){
      return '<div class="mw-history-row"><b>'+esc(e.date)+'</b><span>'+esc(e.text)+'　<a href="article.html?id='+encodeURIComponent(e.a.id)+'">〔'+esc(e.a.title)+'〕</a></span></div>';
    }).join("");
    bindWikiChrome(d);
  });
}

async function searchWiki(){
  const q=(document.querySelector("#q")?.value||"").trim();
  location.href="articles.html"+(q?"?q="+encodeURIComponent(q):"");
}

function initSite(){}

window.wikiData=wikiData;
window.loadWiki=loadWiki;
window.load=load;
window.esc=esc;
window.E=E;
