SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_GetBundleProductsforDeleting]
-- Description     : This procedure gets the list of Quotes available.
--
-- Input Parameters: @PageNumber              int,
--                   @RowsPerPage             int, 
--                   
-- 
-- OUTPUT          : A recordSet of QuoteID, CustomerID, CustomerName, 
--                   Status, ILF, Access, ExpiresOn, RowNumber
--
-- Code Example    : Exec uspQUOTES_GetBundleProductsforDeleting 'Q0000000424','372'
--
-- Revision History:
-- Author          : Naval Kishore Singh
-- 01/11/2008      : Stored Procedure Created.
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetBundleProductsforDeleting]
                 (
                   @IPVC_QuoteID         varchar(22),
                   @IPVC_GroupIDSeq       bigint   
                 )
AS
BEGIN

	SELECT DISTINCT 
					p.Displayname as ProductName
	FROM QUOTES.dbo.Quoteitem Q
			inner join Products.dbo.Product p
			on Q.productCode = p.code
			and Q.priceVersion = p.priceVersion 
	WHERE Q.quoteidseq=@IPVC_QuoteID and Q.GroupIDSeq=@IPVC_GroupIDSeq

END

-- exec uspQUOTES_GetBundleProductsforDeleting 'Q0000000424','372'




GO
