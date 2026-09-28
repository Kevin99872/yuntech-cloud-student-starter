# W5：資料持久化

目標：在自己的 Lab 帳號內連接教師核對的私有 PostgreSQL，實作設備、事件、附件與處理歷程。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：自行設計 SQL migration、主外鍵、交易、參數化查詢與 event_id 唯一鍵。Codespace 不在 VPC，不能假設直接連到 DB；使用核准的应用通道。

公開驗收：同事件重送不重複；衝突內容有明確回應；重啟資料仍在；非應用 SG 無法連 DB；不公開 DB、不提交密碼。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
