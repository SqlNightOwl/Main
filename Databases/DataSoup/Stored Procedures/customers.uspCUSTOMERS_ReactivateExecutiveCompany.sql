SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : CUSTOMERS  
-- Procedure Name  : uspCUSTOMERS_ReactivateExecutiveCompany  
-- Description     : This procedure is used to Re-activate the removed/de-Reactivated "Executive Company".  
-- Revision History:  
-- Author          : Mahaboob  
-- 10/14/2011      : Stored Procedure Created. TFS #1022
------------------------------------------------------------------------------------------------------  
CREATE procedure [customers].[uspCUSTOMERS_ReactivateExecutiveCompany]( @IPVC_ExecutiveCompanyID varchar(11), @IPBI_UserID bigint )  
AS  
BEGIN-->Main Begin 
  BEGIN TRY
  BEGIN TRANSACTION A; 
	  Update Customers.dbo.ExecutiveCompany 
      set ActiveFlag = 1, ModifiedByIDSeq = @IPBI_UserID, ModifiedDate = getdate(), SystemLogDate = getdate()
      where ExecutiveCompanyIDSeq = @IPVC_ExecutiveCompanyID  
	  select @@ROWCOUNT  
  COMMIT TRANSACTION A;
  end TRY
  begin CATCH    
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION A;
    end
    else 
    if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION A;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION A;
    return;                 
  end CATCH         
END--->Main End  
  

GO
