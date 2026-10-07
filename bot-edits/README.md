# WongmingBot 編輯佇列

這個分支專門讓 GitHub Actions 以 `WongmingBot` 呼叫黃名帝國百科的 MediaWiki API。

## 必要的 GitHub Actions Secrets

在 `annynn1990/wk` 的 Settings → Secrets and variables → Actions 建立：

- `MEDIAWIKI_BOT_LOGIN`：完整 Bot 登入名稱，例如 `WongmingBot@YourBotPasswordName`
- `MEDIAWIKI_BOT_PASSWORD`：MediaWiki Special:BotPasswords 產生的密碼

不要把 Bot Password 寫進 Git，也不要貼到聊天裡。

## 建立一次 Bot Password

登入黃名帝國百科後開啟：

`https://wongming-encyclopedia.onrender.com/index.php?title=Special:BotPasswords`

建立一組給 `WongmingBot` 使用的 Bot Password，權限只勾選日後需要的 API 編輯權限即可。

## 編輯格式

把 JSON 放在：

`bot-edits/inbox/`

格式：

```json
{
  "title": "頁面名稱",
  "text": "完整的 MediaWiki wikitext",
  "summary": "WongmingBot 編輯摘要",
  "minor": false
}
```

推送後 GitHub Actions 會自動呼叫 MediaWiki API，成功後把檔案移到 `bot-edits/processed/`。
