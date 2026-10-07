#!/usr/bin/env python3
import json
import os
import sys
import urllib.parse
import urllib.request
import http.cookiejar

API_URL = os.environ.get(
    "MEDIAWIKI_API_URL",
    "https://wongming-encyclopedia.onrender.com/api.php",
)
BOT_LOGIN = os.environ["MEDIAWIKI_BOT_LOGIN"]
BOT_PASSWORD = os.environ["MEDIAWIKI_BOT_PASSWORD"]

cookie_jar = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(
    urllib.request.HTTPCookieProcessor(cookie_jar)
)

def request(params, post=False):
    data = urllib.parse.urlencode(params).encode("utf-8")
    if post:
        req = urllib.request.Request(API_URL, data=data)
    else:
        req = urllib.request.Request(API_URL + "?" + data.decode("utf-8"))
    req.add_header("User-Agent", "WongmingBot/1.0")
    with opener.open(req, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))

def main(path):
    with open(path, "r", encoding="utf-8") as f:
        edit = json.load(f)

    title = edit["title"]
    text = edit["text"]
    summary = edit.get("summary", "WongmingBot 編輯")
    minor = "1" if edit.get("minor", False) else "0"

    login_token = request({
        "action": "query",
        "meta": "tokens",
        "type": "login",
        "format": "json",
    })["query"]["tokens"]["logintoken"]

    login = request({
        "action": "login",
        "lgname": BOT_LOGIN,
        "lgpassword": BOT_PASSWORD,
        "lgtoken": login_token,
        "format": "json",
    }, post=True)

    if login.get("login", {}).get("result") != "Success":
        raise RuntimeError("MediaWiki 登入失敗：" + json.dumps(login, ensure_ascii=False))

    csrf_token = request({
        "action": "query",
        "meta": "tokens",
        "type": "csrf",
        "format": "json",
    })["query"]["tokens"]["csrftoken"]

    result = request({
        "action": "edit",
        "title": title,
        "text": text,
        "summary": summary,
        "minor": minor,
        "bot": "1",
        "token": csrf_token,
        "format": "json",
    }, post=True)

    edit_result = result.get("edit", {}).get("result")
    if edit_result != "Success":
        raise RuntimeError("MediaWiki 編輯失敗：" + json.dumps(result, ensure_ascii=False))

    print(json.dumps(result, ensure_ascii=False))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法：mediawiki_bot.py <edit.json>", file=sys.stderr)
        sys.exit(2)
    main(sys.argv[1])
