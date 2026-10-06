# 小軟體收藏館

收集個人開發的小工具、小網頁和實驗作品。純靜態網頁，資料全部放在這個 repo 的 GitHub Issues：

- **投稿**：訪客用 issue 表單投稿，自動加上 `submission` 標籤。
- **上架**：你替 issue 加上 `listed` 標籤，作品就會出現在網站上。拿掉標籤或關閉 issue 即下架。
- **留言交流**：每件作品的 issue 就是它的留言區，網站上可直接閱讀。
- **人氣**：issue 上的 👍 數會顯示在卡片上。
- **我的收藏**：存在訪客自己的瀏覽器。

## 設定步驟

1. 在 GitHub 建立公開 repo，名稱 `soft-shelf`（帳號 `p19691221-web`）。若用別的名稱，改 `index.html` 最下方的 `OWNER` / `REPO`。
2. 上傳本資料夾所有檔案，包含 `.github/ISSUE_TEMPLATE/` 這個隱藏資料夾。
3. Settings → Pages → Source 選 `Deploy from a branch`，Branch 選 `main` / `(root)`。
4. Issues → Labels 建立兩個標籤：`submission`、`listed`。
5. 網站網址：https://p19691221-web.github.io/soft-shelf/

## 上架你的第一批作品

設定完成後點下面連結，表單已經預填好，按 Submit 後再替該 issue 加上 `listed` 標籤：

- [收款結算小幫手](https://github.com/p19691221-web/soft-shelf/issues/new?template=submit.yml&title=%5B%E6%8A%95%E7%A8%BF%5D+%E6%94%B6%E6%AC%BE%E7%B5%90%E7%AE%97%E5%B0%8F%E5%B9%AB%E6%89%8B&name=%E6%94%B6%E6%AC%BE%E7%B5%90%E7%AE%97%E5%B0%8F%E5%B9%AB%E6%89%8B&url=https%3A%2F%2Fp19691221-web.github.io%2Fbento-calc%2Fbento.html&desc=%E5%B9%AB%E8%BE%A6%E5%85%AC%E5%AE%A4%E8%A8%82%E4%BE%BF%E7%95%B6%E7%9A%84%E4%BA%BA%E5%92%8C%E5%B0%8F%E5%BA%97%E5%AE%B6%E8%A8%98%E9%8C%84%E8%A8%82%E5%96%AE%E3%80%81%E7%AE%97%E6%AF%8F%E5%80%8B%E4%BA%BA%E8%A9%B2%E4%BB%98%E5%A4%9A%E5%B0%91%E3%80%81%E5%B0%8D%E5%B8%B3%E6%94%B6%E6%AC%BE%E3%80%82%E6%94%AF%E6%8F%B4%E8%B2%BC%E4%B8%8A+Excel+%E6%89%B9%E6%AC%A1%E5%8C%AF%E5%85%A5%E3%80%81%E4%B8%80%E9%8D%B5%E5%88%86%E4%BA%AB%E5%88%B0+LINE%EF%BC%8C%E5%8F%AF%E5%8A%A0%E5%88%B0%E6%89%8B%E6%A9%9F%E4%B8%BB%E7%95%AB%E9%9D%A2%E3%80%82&maker=Calvin+Lin&tags=%E7%B6%B2%E9%A0%81%E5%B7%A5%E5%85%B7%2C+%E8%A8%82%E9%A4%90%2C+%E5%B0%8D%E5%B8%B3%2C+PWA)
- [陳述線索分析器](https://github.com/p19691221-web/soft-shelf/issues/new?template=submit.yml&title=%5B%E6%8A%95%E7%A8%BF%5D+%E9%99%B3%E8%BF%B0%E7%B7%9A%E7%B4%A2%E5%88%86%E6%9E%90%E5%99%A8&name=%E9%99%B3%E8%BF%B0%E7%B7%9A%E7%B4%A2%E5%88%86%E6%9E%90%E5%99%A8&url=https%3A%2F%2Fp19691221-web.github.io%2Fstatement-cue-analyzer%2F&desc=%E5%9C%A8%E7%80%8F%E8%A6%BD%E5%99%A8%E8%A3%A1%E5%88%86%E6%9E%90%E4%B8%80%E6%AE%B5%E9%99%B3%E8%BF%B0%E4%B8%AD%E7%9A%84%E8%A1%8C%E7%82%BA%E7%B7%9A%E7%B4%A2%EF%BC%8C%E4%BE%9B%E7%A0%94%E7%A9%B6%E8%88%87%E6%95%99%E5%AD%B8%E4%BD%BF%E7%94%A8%E3%80%82%E4%B8%8D%E6%98%AF%E6%B8%AC%E8%AC%8A%E5%B7%A5%E5%85%B7%E3%80%82&maker=Calvin+Lin&tags=%E7%B6%B2%E9%A0%81%E5%B7%A5%E5%85%B7%2C+%E7%A0%94%E7%A9%B6%2C+%E6%95%99%E5%AD%B8)

## 限制

- 投稿與留言需要 GitHub 帳號。
- 網站讀取 GitHub API 不需登入，但同一網路每小時上限 60 次；頁面會快取 5 分鐘。
- 最多顯示 100 件已上架作品。超過時需要加分頁。
