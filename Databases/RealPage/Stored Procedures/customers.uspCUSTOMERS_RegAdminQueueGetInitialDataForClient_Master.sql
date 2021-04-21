SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_RegAdminQueueGetInitialDataForClient_Master] 
AS
BEGIN 
  set nocount on;
  --------------------------------
  Select AccountIDSeq As AccountID
  From [ORDERS].dbo.[RegAdminQueue] with (nolock) 
  Where PushedToRegAdminFlag=0 And OrderIDSeq Is NULL
END

/*
EXEC [CUSTOMERS].dbo.[uspCUSTOMERS_RegAdminQueueGetInitialDataForClient_Master]
*/

GO
