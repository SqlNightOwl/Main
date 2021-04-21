SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [orders].[uspORDERS_OrderStatusTypes]
AS
BEGIN
  select Code,Name from Orders.dbo.OrderStatusType with (nolock)
END

GO
