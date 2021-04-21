SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_RepresentativeProductsList]
-- Description     : This procedure returns the list of Products for the specified Quote.
-- Input Parameters:  1. @IPVC_QuoteID varchar(11)
-- 
-- OUTPUT          : RecordSet of Product Code and DisplayName.
--
-- Code Example    : Exec QUOTES.[dbo].[uspQUOTES_RepresentativeProductsList] @IPVC_QuoteID = 'Q0000002546'
-- 
-- Revision History:
-- Author          : RealPage 
-- 07/26/2007      : Created, STA.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_RepresentativeProductsList] (@IPVC_QuoteID varchar(11))	
AS
BEGIN
  ------------------------------------------------
	SELECT DISTINCT 
                  QI.ProductCode AS ProductCode,
                  P.DisplayName  AS DisplayName
  FROM            
                  QUOTES..QuoteItem QI
  INNER JOIN      
                  PRODUCTS..Product P
    ON            
                  QI.ProductCode = P.Code
  WHERE           
                  QuoteIDSeq = @IPVC_QuoteID
  ------------------------------------------------
END

GO
