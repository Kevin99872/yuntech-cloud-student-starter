# W14–W15：監控與故障診斷

目標：建立一項能觸發／恢復的 CloudWatch 告警，診斷受控的網路、授權或資料故障。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：先定義訊號、閾值、觀察窗及缺資料策略，再設計可逆故障。只操作自己的精確資源，不修改 IAM；不對外傳送通知。

公開驗收：正常 → ALARM → OK 證據；故障前後與最小修復；無秘密的日誌；刪除本題告警、log group 與測試資源。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
