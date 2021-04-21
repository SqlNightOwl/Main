SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_ExceptionRuleHeaderUpdate]
-- Description     : This is the Main SP called for Updating short description of Rule that User want to update on existing rule
--                   If No short description is entered, UI will inteligently NOT call this proc all, because default is NULL for RuleDescription
-- Input Parameters: As indicated below.
-- Syntax          : 
/*
Exec CUSTOMERS.dbo.uspCUSTOMERS_ExceptionRuleHeaderUpdate @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,
                                                          @IPVC_RuleType='None',@IPVC_RuleDescription='Special Rule for Prometheus'

*/
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ExceptionRuleHeaderUpdate] (@IPVC_CompanyIDSeq          varchar(50),     -- CompanyIDSeq (Mandatory) : UI Knows this
                                                                 @IPBI_RuleIDSeq             bigint,          -- RuleIDSeq    (Mandatory) : Existing RuleIDSeq
                                                                                                              -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                 @IPVC_RuleType              varchar(50),     --> RuleType:  
                                                                                                              -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                              -- Values None,Family,Category,Product,ProductType(Future). 
                                                                                                              -- UI to Pass it back as such. This proc is a generalized proc used in other places.
                                                                 @IPVC_RuleDescription       varchar(50)='',  -- RuleDescription: This is short description of Rule that User May Type
                                                                                                              -- Default is '' or Blank. UI need not call this proc if user has not typed anything for update. 
                                                                 @IPBI_UserIDSeq             bigint           --> This is UserID of person logged on (Mandatory)  
                                                                )
AS
BEGIN 
  set nocount on;
  declare @LDT_SystemDate datetime;
  ------------------------------------------------------------------
  select @LDT_SystemDate       = Getdate(),
         @IPVC_RuleDescription = nullif(ltrim(rtrim(@IPVC_RuleDescription)),'')
  ------------------------------------------------------------------
  if (@IPVC_RuleDescription is not null)
  begin
    Update CUSTOMERS.dbo.InvoiceDeliveryExceptionRule
    set    RuleType        = (case when RuleType <> @IPVC_RuleType 
                                    then @IPVC_RuleType
                                   else RuleType
                              end),
           RuleDescription = @IPVC_RuleDescription,
           ModifiedByIDSeq = @IPBI_UserIDSeq,
           ModifiedDate    = @LDT_SystemDate,
           SystemLogDate   = @LDT_SystemDate
    where  RuleIDSeq       = @IPBI_RuleIDSeq
    and    CompanyIDSeq    = @IPVC_CompanyIDSeq
  end
END
GO
