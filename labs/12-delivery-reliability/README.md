# W12–W13：取樣與離線補送

目標：量測選圖／取樣的傳輸量與延遲，建立有限離線佇列、退避重試與冪等。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：設定 queue 上限、滿載策略、重試上限；比較同批合成輸入的事件數、bytes、延遲。記錄量測邊界。

公開驗收：斷線時佇列有界；恢復後無遺失或未說明的丟棄；DB 無重複；公布取樣前後量測方法和結果。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
