use DataSoup
go
ALTER TABLE [tcu].[CostCenter] ADD CONSTRAINT [CostCenter_has_ParentCostCenter] FOREIGN KEY 
	(
		[ParentCostCenter]
	) REFERENCES [tcu].[CostCenter] (
		[CostCenter]
	)
GO