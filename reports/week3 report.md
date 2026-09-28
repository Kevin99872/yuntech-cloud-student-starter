# 本週增量報告（自行複製並填寫）

- 週次／組別／成員／Git 版本：
    W3／第五組／周于凱、張巧麗、張慧如、林宥穎／7726d01（部署服務回報的完整 SHA 為 `7726d01684969140b31a74396bb168c0ca868a72`）
- 需求與架構選擇：
    - 1 個專用 Security Group
    - 1 個 EC2 key pair
    - 1 台 t3.micro EC2
    - 其根 EBS 與網路介面由 EC2 產生
- AWS 區域、帳號末四碼、核准資源範圍、成本預估：
    - AWS 區域：`us-east-1`
    - 帳號末四碼：`7828`
    - `bash scripts/verify-aws.sh`：已執行成功；本報告未記錄憑證內容。
    - 核准資源範圍：1 個專用 Security Group、1 個 EC2 key pair、1 台 `t3.micro` EC2，以及該主機的根 EBS 與 ENI；沿用預設 VPC、預設公有子網與既有 IGW，不新建網路。
    - 成本預估：約 `$11.88 USD/month`，假設 `t3.micro` 運作 730 小時、8 GiB gp3、1 個公有 IPv4；實際金額依 Learner Lab 額度與 AWS 帳單為準。
- 部署與重建步驟（不含秘密）：
    - T1（部分完成）：已核對／已知名稱 `yuntech-learning`、Amazon Linux 64-bit、`t3.micro`、區域 `us-east-1`；已核對預設 VPC `vpc-0565cd00fae099d5b`（CIDR `172.31.0.0/16`，來源：`.local/resources.json`）。子網 ID、子網實際使用的路由表（`0.0.0.0/0 → igw-…`）、AMI 名稱／建立日期、根 EBS 加密／DeleteOnTermination、IMDSv2 required 尚未核對，列於下方「未測部分」。
    - T2 第一輪（手動補救，列為偏離）：本次實際使用的 key pair 為 `vockey`，不是本週規格要求的自產 ed25519 key pair，已於第二輪修正。實際掛載的 Security Groups 為 `default`（`sg-0a094864316485bfb`）與 `my device`（`sg-0c1a26345931ec779`），因此第一輪不符合「僅一個專用 SG」的範圍。已記錄的 Instance ID 為 `i-005bfb8e1d915dc69`；公開 IPv4 曾隨主機狀態變更，`3.238.65.144` 與後續操作使用的 `44.223.85.180` 不視為同時有效，應以同一觀測時間的 Console 截圖或 `describe-instances` 輸出為準。因建立主機時忘記填 User data，改用以下手動補救，這不等同於首次開機 User data 成功：

      ```bash
      scp -i ~/.ssh/labsuser.pem .local/w03-user-data.sh \
        ec2-user@44.223.85.180:/tmp/w03-user-data.sh

      ssh -i ~/.ssh/labsuser.pem ec2-user@44.223.85.180 \
        'sudo bash /tmp/w03-user-data.sh'
      ```

    - T2 第二輪（規格修正並完成部署）：
        1. 先核對第一輪資源 ID，未刪除預設 VPC、default Security Group、W2 S3 或既有 `vockey`。
        2. 在 EC2 Console 終止第一輪主機 `i-005bfb8e1d915dc69`，確認狀態為 `Terminated`。
        3. 確認第一輪專用 SG `sg-0c1a26345931ec779` 的入站規則已清空；沒有刪除 `default` SG。
        4. 產生本機 ed25519 key pair `w03-ed25519`，只將公開金鑰匯入 EC2，私鑰未上傳或提交 Git。
        5. 建立第二輪專用 SG `w03-secround-sg`，只允許筆電公開 IP 的 `/32` 存取 TCP 22 與 TCP 80，不開放 TCP 8080 或 `0.0.0.0/0`。
        6. 使用同一個 commit `7726d01684969140b31a74396bb168c0ca868a72` 產生 User data，建立第二輪 `t3.micro` EC2；建立時注入 User data。
        7. 以 `w03-ed25519` SSH 登入第二輪主機，執行 `cloud-init status --wait`、兩個 `systemctl is-active` 與 loopback `/health` 檢查。
        8. 驗證成功後在 Console 執行 Stop，確認第二輪主機最終狀態為 `stopped`，保留到 W4。
        9. 回收讀回與重建證據：第一輪為 `Terminated`；第二輪資源與 stopped 狀態記錄於下方「精確資源 ID 清單」。

      第二輪資源：
        - Instance：`i-06c91e9e6ab7888da`
        - Security Group：`sg-08a34c2e87143f7b6`（`w03-secround-sg`）
        - Root EBS：`vol-01f6f6da25147c05e`
        - ENI：`eni-0f4d6f5a4431901cf`
        - Key pair：`w03-ed25519`
        - 部署 commit：`7726d01684969140b31a74396bb168c0ca868a72`

      限制：`deploy/up.sh` 與 `deploy/down.sh` 尚未建立，本輪建立與第一輪回收皆為手動操作，尚不能宣稱 T2／T4 已腳本化。

- 成功測試：輸入、預期、實際、時間、證據位置：
    - 第一輪手動補救驗證：
        - 輸入：手動執行 `/tmp/w03-user-data.sh`，再執行 `systemctl status` 與 `curl -i http://127.0.0.1/health`。
        - 預期：nginx 與 inspection 為 `active (running)`；`/health` 回 HTTP `200`，且版本等於部署 commit。
        - 實際：2026-09-28 16:19:12 UTC 兩個服務啟動；2026-09-28 16:22:47 UTC `/health` 回 HTTP `200`，版本為 `7726d01684969140b31a74396bb168c0ca868a72`。
        - 證據（摘錄，完整原始輸出已去除秘密後另存）：

                [ec2-user@ip-172-31-0-22 ~]$ sudo systemctl status nginx --no-pager
                ● nginx.service - The nginx HTTP and reverse proxy server
                    Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
                    Active: active (running) since Mon 2026-09-28 16:19:12 UTC; 3min 22s ago
                    Process: 4886 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
                    Process: 4887 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
                    Process: 4893 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
                Main PID: 4898 (nginx)
                    Tasks: 3 (limit: 1059)
                    Memory: 2.5M
                        CPU: 43ms
                    CGroup: /system.slice/nginx.service
                            ├─4898 "nginx: master process /usr/sbin/nginx"
                            ├─4899 "nginx: worker process"
                            └─4900 "nginx: worker process"

                Sep 28 16:19:12 ip-172-31-0-22.ec2.internal systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
                Sep 28 16:19:12 ip-172-31-0-22.ec2.internal nginx[4887]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
                Sep 28 16:19:12 ip-172-31-0-22.ec2.internal nginx[4887]: nginx: configuration file /etc/nginx/nginx.conf test is successful
                Sep 28 16:19:12 ip-172-31-0-22.ec2.internal systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
                [ec2-user@ip-172-31-0-22 ~]$ sudo systemctl status inspection --no-pager
                ● inspection.service - W3 inspection service
                    Loaded: loaded (/etc/systemd/system/inspection.service; enabled; preset: disabled)
                    Active: active (running) since Mon 2026-09-28 16:19:12 UTC; 3min 32s ago
                Main PID: 4841 (python3)
                    Tasks: 1 (limit: 1059)
                    Memory: 9.6M
                        CPU: 123ms
                    CGroup: /system.slice/inspection.service
                            └─4841 /usr/bin/python3 /opt/inspection/app/service.py

                Sep 28 16:19:12 ip-172-31-0-22.ec2.internal systemd[1]: Started inspection.service - W3 inspection service.
                [ec2-user@ip-172-31-0-22 ~]$ curl -i http://127.0.0.1/health
                HTTP/1.1 200 OK
                Server: nginx
                Date: Mon, 28 Sep 2026 16:22:47 GMT
                Content-Type: application/json; charset=utf-8
                Content-Length: 134
                Connection: keep-alive
                Cache-Control: no-store

                {"status": "ok", "service": "inspection", "version": "7726d01684969140b31a74396bb168c0ca868a72", "started_at": "2026-09-28T16:19:12Z"}

        - 以上輸出證明手動執行 user data 後服務可用，但不證明 User data 在首次開機時成功執行。
        - 尚缺：主機 running、2/2 status checks、cloud-init 完成、nginx 與 `127.0.0.1:8080` 首次監聽的五層觀測時間未完整記錄。

    - 第二輪自動化驗證（T2 已完成項）：已使用自產 ed25519 key pair 與建立時注入的 User data 完成部署並驗證服務；這是第二輪主機的驗證，不代表第一輪的手動補救等同於首次 User data 成功。
        - 驗證時間：服務輸出顯示 2026-09-28 17:40:03 UTC，尚未記錄本機執行 `date` 的時間。
        - 實際：`cloud-init status --wait` 回 `status: done`；nginx 與 inspection 均回 `active`；`curl -i http://127.0.0.1/health` 回 HTTP `200 OK`。
        - 回應：`status=ok`、`service=inspection`、`version=7726d01684969140b31a74396bb168c0ca868a72`、`started_at=2026-09-28T17:39:24Z`。
        - 證據：第二輪 EC2 內的 cloud-init、systemd 與 loopback curl 輸出已由本人保存。
        - 尚待補齊：五層首次觀測時間、服務尚未就緒前的 early curl 完整證據（見「未測部分」）。

- 拒絕／故障測試：操作、預期、實際、原因、最小修正：
    - T3(a) Security Group 阻擋 HTTP：已完成。
        - 預測：移除 TCP 80 入站規則後，封包應在 Security Group 被阻擋，curl timeout、HTTP status `000`；恢復相同規則後應回 HTTP `200`。
        - 實際：原始測試 2026-09-29 00:50:18 CST（UTC+8）回 HTTP `200`、curl exit `0`；移除規則後 timeout、curl exit `28`；恢復規則後回 HTTP `200`、curl exit `0`。
        - 原因：移除 TCP 80 入站規則時，封包未到達 nginx；加回原本相同的 TCP 80／來源 `/32` 規則後服務恢復。
        - 最小修正：恢復原本的 TCP 80 入站規則。
        - 證據：
            - 原始：2026-09-29 00:50:18 CST，`http://44.223.85.180/health` 回 `HTTP/1.1 200 OK`、`curl exit=0`，JSON version 為 `7726d01684969140b31a74396bb168c0ca868a72`。
            - 移除：2026-09-29 00:51:06 CST，`curl: (28) Connection timed out after 8001 milliseconds`、`curl exit=28`、HTTP status `000`。
            - 恢復：2026-09-29 00:52:28 CST，回 `HTTP/1.1 200 OK`、`curl exit=0`，JSON status 為 `ok`、service 為 `inspection`。
            - Security Group：`sg-0c1a26345931ec779`（`my laptop`）；TCP 80 來源為本人筆電公開 IP `/32`，完整 IP 不放入公開報告。
            - Console 證據：已保存規則移除與恢復的畫面。
    - T3(b) inspection 停止／啟動：已完成。
        - 預測：停止 inspection 後 nginx 應仍回應，但因無法連到 `127.0.0.1:8080` 而回 `502`；重新啟動 inspection 後應回 HTTP `200`。
        - 實際：停止前兩個服務均 active 且 `/health` 回 `200`；停止後回 `502`、curl exit `0`；恢復後回 `200`、curl exit `0`。
        - 原因：nginx 仍在運作並成功回應，但後端 inspection 停止；恢復 inspection 後反向代理重新可用。
        - 最小修正：執行 `sudo systemctl start inspection`。
        - 證據：
            - 停止前：2026-09-28 16:54:34 UTC，nginx 與 inspection 均為 `active`，本機 `/health` 回 `200`。
            - 停止後：2026-09-29 00:56:44 CST（UTC+8），回 `HTTP/1.1 502 Bad Gateway`、`curl exit=0`，Server 為 nginx。
            - 恢復後：2026-09-29 00:57:41 CST（UTC+8），回 `HTTP/1.1 200 OK`、`curl exit=0`，JSON version 為 `7726d01684969140b31a74396bb168c0ca868a72`。
    - T3(c) 停止 nginx（小組項）：未做。依任務卡需指定一人示範、全組比較三種故障樣貌；本人尚未執行，列入下方「未測部分」。

- 一次請求經過哪些服務與權限檢查：
    - 筆電或 Codespace → 公有 IPv4 → 預設路由表／IGW → Security Group TCP 80 → nginx → `127.0.0.1:8080` 的 inspection → `/health` JSON。
    - 本次實際掛載兩個 Security Group，且使用筆電連線；來源 `/32` 與規則內容尚未在本報告附上，因此此段路徑仍需以 Console 證據補強。
- AI 協助內容、本人驗證與修改：
    - AI 協助檢查 W3 契約、整理部署與驗證命令；本人自行執行 `verify-aws.sh`、SCP、SSH、user data 與服務檢查。
    - 本人確認服務輸出版本等於完整 commit；未將未測的 T1 網路核對、T2 五層觀測、T3(c) 或 T4 腳本化寫成通過。
- 精確資源 ID 清單與回收／保留理由：
    - T4 第一輪回收：
    - 第一輪 EC2 `i-005bfb8e1d915dc69`：Console 截圖顯示狀態為 `Terminated`，已回收。
    - 第一輪專用 SG `sg-0c1a26345931ec779`（`my laptop`）：Console 截圖顯示 Inbound rules 為 0；證明規則已移除，但尚未證明 Security Group 本身已刪除。
    - 第一輪根 EBS、ENI、key pair ID：尚未補齊，需從 EC2 詳細資料核對後填入；不以名稱猜測或廣泛刪除。
    - `default` SG `sg-0a094864316485bfb` 與預設 VPC：不刪除。
    - T4 第二輪重建與保留：
    - 第二輪 EC2 `i-06c91e9e6ab7888da`：key pair 為 `w03-ed25519`；專用 SG 為 `sg-08a34c2e87143f7b6`（`w03-secround-sg`）；根 EBS `vol-01f6f6da25147c05e`；ENI `eni-0f4d6f5a4431901cf`；部署 commit 同為 `7726d01684969140b31a74396bb168c0ca868a72`。
    - 第二輪驗證：`cloud-init done`、nginx active、inspection active、`/health` HTTP `200`。
    - 第二輪保留：最終狀態為 `stopped`，停止時間為 2026-09-29 01:44，時區依 Console 截圖紀錄；保留到 W4。
    - 證據時間：2026-09-29 01:10 CST（UTC+8），時間取自截圖左下角。
- 成本觀察與不確定性：
    - 預估約 `$11.88 USD/month`，包含 `t3.micro`、8 GiB gp3 與公有 IPv4 的假設；實際值受運作時數、磁碟大小、Learner Lab 額度與當期價格影響。
    - EC2 停止後通常不收運算費，但 EBS 與公有 IPv4 的計費狀態仍需依當期 AWS 價格確認。

