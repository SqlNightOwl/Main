SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
-- =============================================
-- Author:		<Raghavender,,Realpage>
-- Create date: <24 oct 2008>
-- Description:	<proc to add new FootNote>
-- =============================================
CREATE PROCEDURE [products].[uspProducts_StockBundleIdentifierList]
	  
AS
BEGIN
	  select Code, [Name] from Products.dbo.StockBundleIdentifier order by Sortseq
END
GO
