SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : useCUSTOMERS_UpdateAccountStatus
-- Description     : This procedure gets called for Save of Property Or Company Related Attributes only
--                    This procedure takes care of setting Account Status Properly
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.useCUSTOMERS_UpdateAccountStatus  Passing Input Parameters
-- Revision History:
-- Author          : SRS Defect 8430
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[useCUSTOMERS_UpdateAccountStatus] (@IPVC_CompanyIDSeq           varchar(50),                     --> This is the CompanyID, to which the property needs to be created.(Mandatory) 
                                                           @IPVC_PropertyIDSeq          varchar(50) =NULL,               --> For Edit Existing Property it  passed from UI.(Mandatory)                                 
                                                           @IPVC_StatusTypecode         varchar(10) ='ACTIV',            --> UI will pass based on Value of Status drop down.Default ACTIV
                                                           @IPVC_AccountTypeCode        varchar(10),                     --> AHOFF for Company Account, APROP for Property Account
                                                           @IPBI_UserIDSeq              bigint                           --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
                                                          )
AS 
BEGIN
  set nocount on
  -------------------------------
  declare @LDT_SystemDate      datetime
  declare @LDT_MaxAccountDate  datetime
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @LDT_SystemDate     = Getdate(),
         @IPVC_PropertyIDSeq = nullif(@IPVC_PropertyIDSeq,'')

  select @LDT_MaxAccountDate = Max(Coalesce(A.ModifiedDate,A.Createddate,A.SystemLogDate))
  from   Customers.dbo.Account A with (nolock)
  where  A.CompanyIDSeq    = @IPVC_CompanyIDSeq
  and    coalesce(A.PropertyIDSeq,'ABCDEF')   = coalesce(@IPVC_PropertyIDSeq,coalesce(A.PropertyIDSeq,'ABCDEF'))
  and    A.AccountTypeCode = @IPVC_AccountTypeCode
  ----------------------------------------------------------------------------
  begin try
    ---------------------------------------------------------------------------- 
    if (@IPVC_StatusTypecode = 'ACTIV')
    begin
      Update Customers.dbo.Account 
      set    ActiveFlag          = 1,
             ModifiedByIDSeq     = @IPBI_UserIDSeq,
             ModifiedDate        = @LDT_SystemDate,
             SystemLogDate       = @LDT_SystemDate
      where  CompanyIDSeq        = @IPVC_CompanyIDSeq
      and    coalesce(PropertyIDSeq,'ABCDEF')   = coalesce(@IPVC_PropertyIDSeq,coalesce(PropertyIDSeq,'ABCDEF'))
      and    AccountTypeCode     = @IPVC_AccountTypeCode
      and    Coalesce(ModifiedDate,Createddate,SystemLogDate) = @LDT_MaxAccountDate
      and    ActiveFlag = 0
    end
    else if (@IPVC_StatusTypecode <> 'ACTIV')
    begin
      Update Customers.dbo.Account 
      set    ActiveFlag          = 0,
             ModifiedByIDSeq     = @IPBI_UserIDSeq,
             ModifiedDate        = @LDT_SystemDate,
             SystemLogDate       = @LDT_SystemDate
      where  CompanyIDSeq        = @IPVC_CompanyIDSeq
      and    coalesce(PropertyIDSeq,'ABCDEF')   = coalesce(@IPVC_PropertyIDSeq,coalesce(PropertyIDSeq,'ABCDEF'))
      and    AccountTypeCode     = @IPVC_AccountTypeCode    
      and    ActiveFlag = 1
    end 
    ----------------------------------------------------------------------------
  end try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:useCUSTOMERS_UpdateAccountStatus. Update to Customers.dbo.Account table for Account Status Failed.'
    return
  end   Catch      
END --: Main Procedure END
GO
