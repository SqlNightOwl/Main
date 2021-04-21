SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_RegAdminQueueGetInitialDataForSW_Maintenance] 
AS
BEGIN 
  set nocount on;
  --------------------------------
  Select AccountIDSeq   As AccountID,
         OrderIDSeq     As OrderID,
         OrderItemIDSeq As OrderItemID 
  From  [ORDERS].dbo.[RegAdminQueue] with (nolock) 
  Where PushedToRegAdminFlag=0 And OrderItemIDSeq Is Not NULL
END

/*
EXEC [CUSTOMERS].dbo.[uspCUSTOMERS_RegAdminQueueGetInitialDataForSW_Maintenance]
*/

GO
