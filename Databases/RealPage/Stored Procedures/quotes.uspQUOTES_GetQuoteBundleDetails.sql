SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetQuoteBundleDetails
-- Description     : This procedure gets customerIDseq pertaining to passed QuoteID
-- Input Parameters: 1. @IPVC_QuoteID  as bigint
--                   
-- OUTPUT          : RecordSet of CustomerIDSeq and CreatedBy
--               
--                   
-- Code Example    : Exec uspQUOTES_GetQuoteBundleDetails 80
-- 
-- 
-- Revision History:
-- Author          : TMN
-- 01/11/2006       : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetQuoteBundleDetails] (
                                                           @IPVC_QuoteID as varchar(50)
                                                          )
AS
BEGIN 

    select CustomerIDSeq,
          CreatedBy,
          QuoteStatusCode 
   from   Quotes.dbo.Quote (nolock) 
   where  QuoteIDSeq = @IPVC_QuoteID  


END 


--Exec uspQUOTES_GetQuoteBundleDetails 'Q0000000043'



GO
