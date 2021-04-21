SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : uspORDERS_ExpireOrderEntries      
-- Description     : Expires products ready to be deactivated
-- Author          : Davon
-- Created         : 12/6/2007
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [orders].[uspORDERS_ExpireOrderEntries] 
as
BEGIN 
  ----------------------------------------------------------------------
  --Step 7: Expire items to deactivate
  ----------------------------------------------------------------------
  update ORDERS.dbo.OrderItem
  set    StatusCode = 'EXPD'
  where  StatusCode = 'FULF'
  and    convert(datetime,convert(varchar(50),ActivationEndDate,101)) <  
         convert(datetime,convert(varchar(50),getdate()))
END
GO
