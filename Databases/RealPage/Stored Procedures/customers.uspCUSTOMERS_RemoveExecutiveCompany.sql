SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : CUSTOMERS  
-- Procedure Name  : uspCUSTOMERS_RemoveExecutiveCompany  
-- Description     : This procedure makes the "Executive Company" as Inactive.  
-- Revision History:  
-- Author          : Mahaboob  
-- 07/27/2011      : Stored Procedure Created.  
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
------------------------------------------------------------------------------------------------------  
CREATE procedure [customers].[uspCUSTOMERS_RemoveExecutiveCompany]( @IPVC_ExecutiveCompanyID varchar(11), @IPBI_UserID bigint )  
AS  
BEGIN-->Main Begin 
  BEGIN TRY
  BEGIN TRANSACTION A; 
	  Update Customers.dbo.Company 
      set ExecutiveCompanyIDSeq = null, ModifiedByIDSeq = @IPBI_UserID, ModifiedDate = getdate(), SystemLogDate = getdate() 
      where ExecutiveCompanyIDSeq = @IPVC_ExecutiveCompanyID
	  Update Customers.dbo.ExecutiveCompany 
      set ActiveFlag = 0, ModifiedByIDSeq = @IPBI_UserID, ModifiedDate = getdate(), SystemLogDate = getdate()
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
