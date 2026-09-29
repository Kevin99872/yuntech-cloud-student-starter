# 本週增量報告（自行複製並填寫）

- 週次／組別／成員／Git 版本：

    W3／第五組／周于凱、張巧麗、張慧如、林宥穎／7726d01（部署服務回報的完整 SHA 為 `7726d01684969140b31a74396bb168c0ca868a72`）

- 需求與架構選擇：
- AWS 區域、帳號末四碼、核准資源範圍、成本預估：
    - 區域：us-east-1
    - 帳號末四碼：7828
    - 核准資源範圍：EC2,VPC,SG....等等相關服務
    - 成本預估：11.08USD/month
- 部署與重建步驟（不含秘密）：
    - T1:恢復實例

        首先,我們進入到aws console進入EC2實例管理畫面將實例運作起來，並在根據W3中創建的SG安全群組中的入站規則修改ssh,http兩個協定的IP為設備/codespace ID,接下來測試EC2內部服務狀態：

                !date '+%Y-%m-%d %H:%M:%S %Z %z'
                sudo systemctl is-active nginx
                sudo systemctl is-active inspection
                curl -i --max-time 8 http://127.0.0.1/health
                2026-09-29 02:09:29 UTC +0000
                active
                active
                HTTP/1.1 200 OK
                Server: nginx
                Date: Tue, 29 Sep 2026 02:09:29 GMT
                Content-Type: application/json; charset=utf-8
                Content-Length: 134
                Connection: keep-alive
                Cache-Control: no-store

                {"status": "ok", "service": "inspection", "version": "7726d01684969140b31a74396bb168c0ca868a72", "started_at": "2026-09-29T01:45:15Z"}
        
        接下來,我們透過本地設備/codespace進行連路方式進行驗證,驗證bash log如下：

                date '+%Y-%m-%d %H:%M:%S %Z %z'                       
                curl -i --max-time 8 http://54.89.10.160/health
                echo "curl_exit=$status"
                2026-09-29 10:14:23 CST +0800
                HTTP/1.1 200 OK
                Server: nginx
                Date: Tue, 29 Sep 2026 02:14:23 GMT
                Content-Type: application/json; charset=utf-8
                Content-Length: 134
                Connection: keep-alive
                Cache-Control: no-store

                {"status": "ok", "service": "inspection", "version": "7726d01684969140b31a74396bb168c0ca868a72", "started_at": "2026-09-29T01:45:15Z"}curl_exit=0
            
        可以看到目前的資料都是正常的且實例運作健康,那接下來
- 成功測試：輸入、預期、實際、時間、證據位置：
    - T1: 實例驗證
        - 實例內部驗證

                !date '+%Y-%m-%d %H:%M:%S %Z %z'
                sudo systemctl is-active nginx
                sudo systemctl is-active inspection
                curl -i --max-time 8 http://127.0.0.1/health
                2026-09-29 02:09:29 UTC +0000
                active
                active
                HTTP/1.1 200 OK
                Server: nginx
                Date: Tue, 29 Sep 2026 02:09:29 GMT
                Content-Type: application/json; charset=utf-8
                Content-Length: 134
                Connection: keep-alive
                Cache-Control: no-store

                {"status": "ok", "service": "inspection", "version": "7726d01684969140b31a74396bb168c0ca868a72", "started_at": "2026-09-29T01:45:15Z"}

        - codespace/本地端主機驗證

                date '+%Y-%m-%d %H:%M:%S %Z %z'                       
                curl -i --max-time 8 http://54.89.10.160/health
                echo "curl_exit=$status"
                2026-09-29 10:14:23 CST +0800
                HTTP/1.1 200 OK
                Server: nginx
                Date: Tue, 29 Sep 2026 02:14:23 GMT
                Content-Type: application/json; charset=utf-8
                Content-Length: 134
                Connection: keep-alive
                Cache-Control: no-store

                {"status": "ok", "service": "inspection", "version": "7726d01684969140b31a74396bb168c0ca868a72", "started_at": "2026-09-29T01:45:15Z"}curl_exit=0
    - T2:事件實作API

        - 
- 拒絕／故障測試：操作、預期、實際、原因、最小修正：
- 一次請求經過哪些服務與權限檢查：
- AI 協助內容、本人驗證與修改：
- 精確資源 ID 清單與回收／保留理由：
- 成本觀察與不確定性：
- 未測部分／阻塞／下一步：
