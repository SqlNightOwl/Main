SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_ReadToSend]
-- Description     : This procedure returns the number of invoices ready to send to epicor
-- 
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_ReadToSend] 
AS
BEGIN
  SELECT count(*) FROM Invoices..Invoice  
  where PrintFlag = 1
  and SentToEpicorFlag = 0
  and SentToEpicorStatus is null
    
END



GO
