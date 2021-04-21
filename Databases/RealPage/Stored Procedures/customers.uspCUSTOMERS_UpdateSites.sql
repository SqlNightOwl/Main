SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCustomers_UpdateSites]
-- Description     : This procedure Updates CustomBundlesProductBreakDownTypeCode in Customer and Property Table
--                  
--
-- Code Example    : CUSTOMERS..[uspCustomers_UpdateSites] 
--                   @IPVC_CompanyIDSEQ = 'C0802000010',
--                   @IPVC_PropertyIDSEQ = 'P0802000010'
--                   @CustomBundlesProductBreakDownTypeCode  = 'YEBR'
--
-- Revision History:
-- Author          : Naval Kishore
-- 07/24/2007      : Stored Procedure Created.
-- Revised         : Anand Chakravarthy
-- 03/28/2008      : Stored Procedure Revised.
-- 12/01/2009      : Naval Kishore Modifed to add new parameters @IPB_CheckedOption & @IPVC_SelectedOption
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_UpdateSites] (
                                                    @IPVC_CompanyIDSEQ                             varchar(50),
                                                    @IPVC_PropertyIDSEQ                            varchar(50), 
                                                    @CustomBundlesProductBreakDownTypeCode         varchar(4),
                                                    @IPVC_ExpandBundle                             varchar(10),
                                                    @IPB_CheckedOption                             bit,	 
                                                    @IPVC_SelectedOption                           varchar(30),
                                                    @IPBI_UserIDSeq                                bigint                  --> This is UserID of person logged on and creating this Address in OMS.(Mandatory)
                                                    )     
AS
BEGIN
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate      datetime
  select  @LDT_SystemDate      = Getdate()
  ------------------------------------------ 
  IF((@IPVC_ExpandBundle = 'All') OR (@IPVC_ExpandBundle = 'Disable'))
  begin
    update C
    set C.CustomBundlesProductBreakDownTypeCode = case when @IPVC_SelectedOption = 'ExpandBundle'
                                                         then @CustomBundlesProductBreakDownTypeCode
                                                         else C.CustomBundlesProductBreakDownTypeCode 
                                                       end,
        C.SeparateInvoiceByFamilyFlag           = case when @IPVC_SelectedOption = 'PrintSeparateInvoice' 
                                                         then @IPB_CheckedOption 
                                                         else C.SeparateInvoiceByFamilyFlag end,
        C.SendInvoiceToClientFlag               = case when @IPVC_SelectedOption = 'DoNotPrint' 
                                                         then @IPB_CheckedOption 
                                                         else C.SendInvoiceToClientFlag end,
        C.ModifiedByIDSeq      = @IPBI_UserIDSeq,
        C.ModifiedDate         = @LDT_SystemDate,
        C.SystemLogDate        = @LDT_SystemDate
   from CUSTOMERS.dbo.COMPANY C with (nolock)
   where C.IDSEQ = @IPVC_CompanyIDSEQ

    update PRP
    set  PRP.CustomBundlesProductBreakDownTypeCode = case when @IPVC_SelectedOption = 'ExpandBundle'
                                                           then @CustomBundlesProductBreakDownTypeCode
                                                          else PRP.CustomBundlesProductBreakDownTypeCode end,
         PRP.SeparateInvoiceByFamilyFlag          = case when @IPVC_SelectedOption = 'PrintSeparateInvoice' 
                                                          then @IPB_CheckedOption 
                                                          else PRP.SeparateInvoiceByFamilyFlag end,
         PRP.SendInvoiceToClientFlag              = case when @IPVC_SelectedOption = 'DoNotPrint' 
                                                          then @IPB_CheckedOption 
                                                          else PRP.SendInvoiceToClientFlag end,
         PRP.ModifiedByIDSeq      = @IPBI_UserIDSeq,
         PRP.ModifiedDate         = @LDT_SystemDate,
         PRP.SystemLogDate        = @LDT_SystemDate 
    from CUSTOMERS.dbo.PROPERTY PRP  with (nolock)
    where PRP.PMCIDSEQ = @IPVC_CompanyIDSEQ  
  end
  else
  ------------------------------------------ 
  begin
    if(@IPVC_CompanyIDSEQ = @IPVC_PropertyIDSEQ)
    begin
      update C
      set    C.CustomBundlesProductBreakDownTypeCode = case when @IPVC_SelectedOption = 'ExpandBundle'
                                                             then @CustomBundlesProductBreakDownTypeCode
                                                             else C.CustomBundlesProductBreakDownTypeCode end,
	     C.SeparateInvoiceByFamilyFlag           = case when @IPVC_SelectedOption = 'PrintSeparateInvoice' 
                                                             then @IPB_CheckedOption 
                                                             else C.SeparateInvoiceByFamilyFlag end,
	     C.SendInvoiceToClientFlag               = case when @IPVC_SelectedOption = 'DoNotPrint' 
                                                             then @IPB_CheckedOption 
                                                             else C.SendInvoiceToClientFlag end,
             C.ModifiedByIDSeq      = @IPBI_UserIDSeq,
             C.ModifiedDate         = @LDT_SystemDate,
             C.SystemLogDate        = @LDT_SystemDate
     from CUSTOMERS.dbo.COMPANY C with (nolock)
     where C.IDSEQ = @IPVC_CompanyIDSEQ
    end
    ------------------------------------------ 
    update PRP
    set     PRP.CustomBundlesProductBreakDownTypeCode = case when @IPVC_SelectedOption = 'ExpandBundle'
                                                              then @CustomBundlesProductBreakDownTypeCode
                                                              else PRP.CustomBundlesProductBreakDownTypeCode end,
	    PRP.SeparateInvoiceByFamilyFlag          = case when @IPVC_SelectedOption = 'PrintSeparateInvoice' 
                                                              then @IPB_CheckedOption 
                                                              else PRP.SeparateInvoiceByFamilyFlag end,
	    PRP.SendInvoiceToClientFlag              = case when @IPVC_SelectedOption = 'DoNotPrint' 
                                                              then @IPB_CheckedOption 
                                                              else PRP.SendInvoiceToClientFlag end,
            PRP.ModifiedByIDSeq      = @IPBI_UserIDSeq,
            PRP.ModifiedDate         = @LDT_SystemDate,
            PRP.SystemLogDate        = @LDT_SystemDate 
    from CUSTOMERS.dbo.PROPERTY PRP  with (nolock)  
    where PRP.IDSEQ = @IPVC_PropertyIDSEQ
  end
END-->main End
GO
