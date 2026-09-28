# W3：一台主機與網路邊界

目標：在教師當次核對的 VPC/subnet 建立小型 Linux EC2，提供自己實作的 health 頁。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：查 describe-images、run-instances、describe-instance-status、SG、user-data、stop/start/terminate。使用參數檔記錄本次環境；running 不等於應用已就緒。不得沿用範例 AMI 或 IP。

公開驗收：限制來源的健康頁；受控封鎖與恢復；Stop/Start 後重新發現 IP；最後 instance terminated 且所建 EBS/ENI/SG 無殘留。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
