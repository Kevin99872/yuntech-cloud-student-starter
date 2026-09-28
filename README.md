# 雲端邊緣運算：學生起始範本

這裡提供環境、任務、方法與公開驗收標準。你要完成自己的程式、部署、診斷與證據。
可用 [OpenCode＋Big Pickle](docs/opencode.md) 或 Copilot Agent／AWS CLI；Agent 能力與 AWS 權限是兩件事。Codespace 已預裝 OpenCode，於 Terminal 執行 `opencode` 啟動；免費模型可用性與限制依供應商現況。
依 [開始使用](docs/getting-started.md) 設定，再逐週完成同一個設備巡檢平台。
後續雲端服務以教師當次發布的可用配置為準；本範本不表示所有 Learner Lab 帳號都已通過所有服務。

| 週次與主題 | 任務 |
|---|---|
| W1–W2：環境與唯讀盤點 | [任務](labs/00-environment/README.md) |
| W2：私有物件與短效分享 | [任務](labs/02-private-s3/README.md) |
| W3：一台主機與網路邊界 | [任務](labs/03-ec2/README.md) |
| W4：平台介面與 API | [任務](labs/04-web-api/README.md) |
| W5：資料持久化 | [任務](labs/05-private-rds/README.md) |
| W6：模擬設備與 MQTT | [任務](labs/06-iot/README.md) |
| W7：影像與事件關聯 | [任務](labs/07-images/README.md) |
| W8–W9：雲端系統里程碑 | [任務](labs/08-cloud-milestone/README.md) |
| W10–W11：模型版本與推論資料 | [任務](labs/10-model-metadata/README.md) |
| W12–W13：取樣與離線補送 | [任務](labs/12-delivery-reliability/README.md) |
| W14–W15：監控與故障診斷 | [任務](labs/14-observability/README.md) |
| W16–W18：備份、重建與交付 | [任務](labs/16-rebuild/README.md) |

W1 概念、W7 與 W10 以後的硬體課程依正式課綱；模擬資料不算硬體驗收。
評分沿用 Lab/Report 50%、專題 35%、課堂 15%。每週小 checkpoint 合併一份增量報告。
W9 有個人需求變更／除錯；W17–18 展示與完整回收。方法可參考、AI 可用，需能現場解釋與修改。
起始 CI 只檢查環境與安全工具；作品功能須由你依 [系統契約](docs/system-contract.md) 編写測試。
使用 [報告模板](reports/TEMPLATE.md)，不要提交秘密、簽名 URL 或真實個資。
