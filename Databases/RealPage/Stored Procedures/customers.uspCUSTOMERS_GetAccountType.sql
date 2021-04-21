SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [customers].[uspCUSTOMERS_GetAccountType] 
AS
BEGIN
select Code,[Name] from Customers..AccountType
END

GO
