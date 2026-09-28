# W7：影像與事件關聯

目標：將合成影像放私有 S3，以 metadata 關聯事件；硬體接入依教師課堂安排。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：區分 SQL metadata 和 S3 bytes；設計受控上傳及短效讀取、內容型別／大小限制、失敗補償。

公開驗收：正確影像 hash；匿名拒絕；未授權事件附件拒絕；錯誤大小／格式拒絕；上傳失敗不留下假成功資料。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
