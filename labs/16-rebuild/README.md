# W16–W18：備份、重建與交付

目標：由固定 Git 版本與備份恢復系統，展示個人理解，最後完整回收。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：自行編寫具參數和資源清單的 CLI 部署／清除；先驗證備份再刪來源。CLI 不會自動提供宣告式 state 或 drift 管理。

公開驗收：另一乾淨環境能重建；資料筆數／hash 相符；恢復後業務情境通過；說明費用、保留資料與所有資源回收證據。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
