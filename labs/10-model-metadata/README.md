# W10–W11：模型版本與推論資料

目標：在 S3 管理模型版本與 hash，把 model_version／分類結果關聯到平台事件。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：設計 immutable version key、manifest 與 hash 驗證；先用合成分類資料測雲端，再依課堂接 Coral。

公開驗收：正確版本可驗證；損毀檔案拒絕；UI 可追溯模型版本；模擬測試與實機測試分開標示。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
