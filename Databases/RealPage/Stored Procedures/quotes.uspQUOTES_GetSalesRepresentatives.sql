SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [quotes].[uspQUOTES_GetSalesRepresentatives] (
                                                            @IPVC_QuoteID       varchar(11),
                                                            @IPVC_ProductCode   char(30)
                                                          )
AS
BEGIN
  -------------------------------------------------------------------
	SELECT  IDSeq,
          ProductCode, 
          CONVERT(NUMERIC(10, 2), CommissionPercent) AS CommissionPercent,
          SalesAgentIDSeq
  FROM    QUOTES.dbo.QuoteSaleAgent
  WHERE   QuoteIDSeq  = @IPVC_QuoteID
  AND     ProductCode = @IPVC_ProductCode
  -------------------------------------------------------------------
END

GO
