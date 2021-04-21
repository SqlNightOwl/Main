SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetReasonForCategory]
-- Description     : This procedure gets the list of Reason to populate drop down based on CategoryCode Passed.

--                   This proc returns all  Reason Category record for CategoryCode  which are ACTIVE only by default.
--                   If the criteria is to show all, then @IPI_ShowAllFlag should be passed as 1. 
--
-- OUTPUT          : RecordSet of ReasonCode,ReasonName
--
-- Code Example    : Exec Orders.dbo.[uspORDERS_GetReasonForCategory]  @IPVC_CategoryCode = 'RTRN', @IPI_ShowAllFlag = 0  (Default behavior to populate drop down list for active ones alone).
--                   Exec Orders.dbo.[uspORDERS_GetReasonForCategory]   @IPVC_CategoryCode = 'RTRN',@IPI_ShowAllFlag = 1  (This is specific behavior to get all Inactive and Active Cancel reasons for More-->View)
--
-- Revision History:
-- Author          : SRS
-- 07/29/2010      : Stored Procedure Created.Defect 8143
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetReasonForCategory] (@IPVC_CategoryCode  varchar(5), 
                                                         @IPI_ShowAllFlag    int=0
                                                        )

AS
BEGIN 
  set nocount on;
  ---------------
  select distinct 
         R.Code          as ReasonCode, ---UI to hold it internally corresponding to drop down value.
         R.ReasonName    as ReasonName  ---UI will show this Name in drop down
  from   ORDERS.dbo.ReasonCategory RC with (nolock)
  inner join
         ORDERS.dbo.Reason R with (nolock)
  on     RC.ReasonCode   = R.Code
  and    RC.CategoryCode = @IPVC_CategoryCode
  and    ( (@IPI_ShowAllFlag=0 and RC.ActiveFlag = 1) ---> If @IPI_ShowAllFlag is 0, return only ACTIVE  Reason category Records. This is Default behavior.
              OR
           (@IPI_ShowAllFlag=1) ---> If @IPI_ShowAllFlag is 1, return all ACTIVE and INACTIVE  Reason category Records. This is NOT Default behavior, but specific request behavior.
         )
  order by R.ReasonName Asc,R.Code Asc
END
GO
