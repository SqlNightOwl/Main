SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec CUSTOMERS.dbo.uspCUSTOMERS_UpdateAccountFromEpicor @IPVC_CompanyID='C0000000287'
exec CUSTOMERS.dbo.uspCUSTOMERS_UpdateAccountFromEpicor @IPVC_CompanyID='C0000000287',@IPVC_PropertyID='P0000002124'
*/

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_UpdateAccountFromEpicor
-- Description     : This procedure Selects Account Info for Epicor Push for the passed parameters.
-- Input Parameters: 1. @IPVC_CompanyID   as varchar(50)
--                   2. @IPVC_PropertyID  as varchar(50)
-- OUTPUT          : None
--  
--                   
-- Code Example    : exec CUSTOMERS.dbo.uspCUSTOMERS_UpdateAccountFromEpicor @IPVC_CompanyID='C0000000287'
--                   exec CUSTOMERS.dbo.uspCUSTOMERS_UpdateAccountFromEpicor @IPVC_CompanyID='C0000000287',
--                                                                           @IPVC_PropertyID='P0000002124'
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_UpdateAccountFromEpicor] (@IPVC_AccountID           varchar(50),
                                                           @IPVC_EpicorCustomerCode  varchar(50)=NULL,
                                                           @IPBI_UserIDSeq           bigint   --> This is UserID of person logged on and creating this company in OMS.(Mandatory)                                      
                                                           )
AS
BEGIN
  set nocount on 
  -------------------------------------------------------
  declare @LDT_SystemDate      datetime
  select  @LDT_SystemDate           = Getdate(),
          @IPVC_EpicorCustomerCode  = nullif(ltrim(rtrim(@IPVC_EpicorCustomerCode)),'')
  -------------------------------------------------------
  begin try
    Update CUSTOMERS.dbo.Account 
    set    EpicorCustomerCode  = @IPVC_EpicorCustomerCode,
           ModifiedByIDSeq     = @IPBI_UserIDSeq,
           ModifiedDate        = @LDT_SystemDate,
           SystemLogDate       = @LDT_SystemDate
    where  IDseq   = @IPVC_AccountID
    and    coalesce(EpicorCustomerCode,'ABCDEF') <> coalesce(@IPVC_EpicorCustomerCode,'ABCDEF')
  end try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspCUSTOMERS_UpdateAccountFromEpicor. Update to Customers.dbo.Account table for EpicorCustomerCode Failed.'
    return
  end   Catch      
END --: Main Procedure END
GO
