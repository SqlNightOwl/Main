SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetCancelReason]
-- Description     : This procedure gets the list of CancelReasons to populate drop down
--                   for user cancellation of Orderitems.

--                   This proc returns all  Reason Category record for Cancel Category  which are ACTIVE only by default.
--                   If the criteria is to show all, then @IPI_ShowAllFlag should be passed as 1. 
--
-- OUTPUT          : RecordSet of ReasonCode,ReasonName
--
-- Code Example    : Exec Orders.dbo.[uspORDERS_GetCancelReason]  @IPI_ShowAllFlag = 0  (Default behavior to populate drop down list for new orderitem cancellation.
--                   Exec Orders.dbo.[uspORDERS_GetCancelReason]  @IPI_ShowAllFlag = 1  (This is specific behavior to get all Inactive and Active Cancel reasons for More-->View)
--
-- Revision History:
-- Author          : Anand Chakravarthy
-- 04/15/2009      : Stored Procedure Created.
-- 06/26/2010      : SRS Modified for Defect #7686
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetCancelReason] (@IPI_ShowAllFlag    int=0)

AS
BEGIN 
  set nocount on;
  ---------------
  select distinct 
         R.Code          as ReasonCode, ---UI to hold it internally corresponding to drop down value.
         R.ReasonName    as ReasonName  ---UI will show this Name in drop for Cancellation Order modal.
  from   ORDERS.dbo.ReasonCategory RC with (nolock)
  inner join
         ORDERS.dbo.Reason R with (nolock)
  on     RC.ReasonCode   = R.Code
  and    RC.CategoryCode = 'CANC'
  and    ( (@IPI_ShowAllFlag=0 and RC.ActiveFlag = 1) ---> If @IPI_ShowAllFlag is 0, return only ACTIVE Cancel Reason category Records. This is Default behavior.
              OR
           (@IPI_ShowAllFlag=1) ---> If @IPI_ShowAllFlag is 1, return all ACTIVE and INACTIVE Cancel Reason category Records. This is NOT Default behavior, but specific request behavior.
         )
  order by R.ReasonName Asc,R.Code Asc
END
GO
