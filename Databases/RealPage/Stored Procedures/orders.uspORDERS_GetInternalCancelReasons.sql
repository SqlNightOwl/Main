SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetInternalCancelReasons]
-- Description     : This procedure gets the list of internal CancelReasons 

--                   This proc returns all  Reason Category record for Internal Cancel reason Category  which are ACTIVE only by default.
--                   If the criteria is to show all, then @IPI_ShowAllFlag should be passed as 1. 
--
-- OUTPUT          : RecordSet of ReasonCode,ReasonName
--
-- Code Example    : Exec Orders.dbo.[uspORDERS_GetInternalCancelReasons]  @IPI_ShowAllFlag = 0  
--                   Exec Orders.dbo.[uspORDERS_GetInternalCancelReasons]  @IPI_ShowAllFlag = 1  
--
-- Revision History:
-- Author          : DNETHUNURI
-- 12/28/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetInternalCancelReasons] (@IPI_ShowAllFlag    INT=0)

AS
BEGIN 
  SET NOCOUNT ON;
  ---------------
  SELECT DISTINCT 
         R.Code          as ReasonCode, 
         R.ReasonName    as ReasonName 
  FROM   ORDERS.dbo.ReasonCategory RC WITH (NOLOCK)
  INNER JOIN ORDERS.dbo.Reason R WITH (NOLOCK)
  on     RC.ReasonCode   = R.Code
  and    RC.CategoryCode = 'CANC'
  and    ( (@IPI_ShowAllFlag=0 and RC.ActiveFlag = 1) ---> If @IPI_ShowAllFlag is 0, return only ACTIVE Cancel Reason category Records. This is Default behavior.
              OR
           (@IPI_ShowAllFlag=1) ---> If @IPI_ShowAllFlag is 1, return all ACTIVE and INACTIVE Cancel Reason category Records. This is NOT Default behavior, but specific request behavior.
         )
	and RC.InternalFlag = 1
 
UNION
 SELECT  
         ''            as ReasonCode, 
         'Internal'    as ReasonName 

 ORDER BY R.ReasonName ASC,R.Code ASC
END
GO
