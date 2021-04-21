SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_SetGroupAttributesForApproval]
-- Description     : This procedure shall be called from UI before Approval.
--                   The call of uspQUOTES_SetGroupAttributesForApproval returns resultset to show in UI for User to override.
--                   This proc is then called for each group to Update the User overridden or Not from UI before approval
--                   
-- Input Parameters: @IPVC_QuoteIDSeq      VARCHAR(50)
-- 
-- OUTPUT          : Result set to show in UI.
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_SetGroupAttributesForApproval]  @IPVC_QuoteIDSeq    = 'Q1002000233',@IPBI_GroupIDSeq = 123, other parameters
-- Revision History: 
-- 07/01/2011      : SRS - Created TFS 738 Enhancement for AutoFulfill at Group Level
-----------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_SetGroupAttributesForApproval] (@IPVC_QuoteIDSeq           varchar(50),   ---> This is QuoteID. UI already knows this.
                                                                  @IPBI_GroupIDSeq           bigint,        ---> This is the GroupIDSeq (UI has this as hidden value) for each group.
                                                                                                             -- The call of uspQUOTES_GetGroupAttributesForApproval returned this to UI 
                                                                  @IPI_AutoFulfillILFFlag    int,           ---> This is final value of check box for AutoFulfillILFFlag for this group.
                                                                                                             -- User might have chosen to accept this as such or overridden by selecting or Unchecking the check box for AutoFulfillILFFlag.                                              
                                                                  @IPI_AutoFulfillACSANCFlag int,           ---> This is final value of check box for AutoFulfillACSANCFlag for this group.
                                                                                                             -- User might have chosen to accept this as such or overridden by selecting or Unchecking the check box for AutoFulfillACSANCFlag.
                                                                  @IPVC_AutoFulfillStartDate varchar(30),   ---> This is Auto Fulfill Start Date for this group.
                                                                                                             -- If one of the check boxes AutoFulfillILFFlag or AutoFulfillACSANCFlag is checked,
                                                                                                             --     this AutoFulfillStartDate is defaulted to user entered Quote Approval date. User can then override this date to a date
                                                                                                             --     greater than or equal to Quote Approval date only if they choose to.
                                                                  @IPBI_UserIDSeq            bigint         ---> This is the userID who is logged and do this operation. UI knows this value already.
                                                                  )
AS
BEGIN
  set nocount on; 
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(1000) 

  select @LDT_SystemDate            = getdate(),
         @IPVC_AutoFulfillStartDate = nullif(ltrim(rtrim(@IPVC_AutoFulfillStartDate)),'')
  --------------------------------------------------------------------------------------
  --Step 1 : Intial Validation
  -- @IPI_AutoFulfillILFFlag=0 and @IPI_AutoFulfillACSANCFlag = 1 is not possible for a group.
  -- UI will stop this scenario at Quote Approval itself.
  -- This is a sanity Check.
  --------------------------------------------------------------------------------------
  If (@IPI_AutoFulfillILFFlag=0 and @IPI_AutoFulfillACSANCFlag=1)
  begin
    select @LVC_CodeSection = 'Proc:uspQUOTES_SetGroupAttributesForApproval. Quote: ' + @IPVC_QuoteIDSeq + ':Group:' + convert(varchar(50),@IPBI_GroupIDSeq) + 
                              '. Access Cannot be Auto Fulfilled when ILF is deferred for Fulfilment.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  --------------------------------------------------------------------------------------
  --Passed in @IPVC_AutoFulfillStartDate should be valid if atleast @IPI_AutoFulfillILFFlag or both @IPI_AutoFulfillILFFlag , @IPI_AutoFulfillACSANCFlag  are 1
  if ((@IPI_AutoFulfillILFFlag = 1 or @IPI_AutoFulfillACSANCFlag = 1)
       and
       isdate(@IPVC_AutoFulfillStartDate)=0
     ) 
  begin 
    select @LVC_CodeSection = 'Proc:uspQUOTES_SetGroupAttributesForApproval. Quote: ' + @IPVC_QuoteIDSeq + ':Group:' + convert(varchar(50),@IPBI_GroupIDSeq) + 
                              '. Auto Fulfill Start Date is Required for fulfilling ILF and/or corresponding Access'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  --------------------------------------------------------------------------------------
  Update Quotes.dbo.[Group]
  set    AutoFulfillILFFlag    = @IPI_AutoFulfillILFFlag,
         AutoFulfillACSANCFlag = @IPI_AutoFulfillACSANCFlag,
         AutoFulfillStartDate  = @IPVC_AutoFulfillStartDate,
         ModifiedDate          = @LDT_SystemDate,
         ModifiedByIDSeq       = @IPBI_UserIDSeq
  where  QuoteIDSeq = @IPVC_QuoteIDSeq
  and    IDSeq      = @IPBI_GroupIDSeq;
  --------------------------------------------------------------------------------------  
END
GO
