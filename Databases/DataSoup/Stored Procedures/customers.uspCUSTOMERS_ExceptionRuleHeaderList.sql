SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_ExceptionRuleHeaderList]
-- Description     : This is the Main SP called for Listing of all ExceptionRules
-- Input Parameters: @IPI_PageNumber,@IPI_RowsPerPage,@IPVC_CompanyIDSeq and other parameters
-- Syntax          : Exec CUSTOMERS.dbo.uspCUSTOMERS_ExceptionRuleHeaderList @IPI_PageNumber = 1,@IPI_RowsPerPage=21,@IPVC_CompanyIDSeq='C0901000516'
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ExceptionRuleHeaderList] (@IPI_PageNumber             int=1, 
                                                               @IPI_RowsPerPage            int=19,
                                                               @IPVC_CompanyIDSeq          varchar(50),     -- CompanyIDSeq (Mandatory)
                                                               @IPBI_RuleIDSeq             bigint      =0,  -- (Optional)
                                                                                                            -- RuleIDSeq : Pass 0 for all Rules(Default). 
                                                                                                            -- Else pass Specific RuleIDSeq to get Header record for that Rule
                                                               @IPVC_RuleType              varchar(50)='',  -- (Optional Search value)   
                                                                                                            --  RuleType:  Values None,Family,Category,Product,ProductType(Future)
                                                                                                            --  Pass Blank to get all Rule Types 
                                                               @IPVC_RuleDescription       varchar(255)= '',-- (Optional)
                                                                                                            -- RuleDescription (user input short description) Future.                                                        
                                                               @IPBI_UserIDSeq             bigint      =0   -- (Optional)
                                                                                                            -- UserIDSeq : Pass 0 for all Users(Default). 
                                                                                                            -- Else pass Specific UserIDSeq to get Header record for the user who created the that Rule
                                                              )
AS
BEGIN 
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------
  declare @LI_ApplyToCustomBundleFlag  int
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------
  select @IPBI_RuleIDSeq = (case when (@IPBI_RuleIDSeq = 0 or isnumeric(@IPBI_RuleIDSeq) = 0) then NULL
                                  else  @IPBI_RuleIDSeq
                             end),
         @IPBI_UserIDSeq = (case when  (@IPBI_UserIDSeq = 0 or isnumeric(@IPBI_UserIDSeq) = 0) then NULL
                                  else @IPBI_UserIDSeq
                             end),
         @IPVC_RuleDescription = coalesce(nullif(@IPVC_RuleDescription,''),''),
         @IPVC_RuleType        = nullif(ltrim(rtrim(@IPVC_RuleType)),'')


  ;WITH CTE as
            (select Max(IDER.ApplyToCustomBundleFlag) as ApplyToCustomBundleFlag
             from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
             where  IDER.CompanyIDSeq       = @IPVC_CompanyIDSeq
             and    IDER.RuleIDSeq          = @IPBI_RuleIDSeq
            )
  select @LI_ApplyToCustomBundleFlag = coalesce(CTE.ApplyToCustomBundleFlag,0)
  from CTE;
  -----------------------------------------------------
  ;WITH tablefinal AS
       (Select IDER.RuleIDSeq           as RuleIDSeq,
               IDER.CompanyIDSeq        as CompanyIDSeq,
               COM.Name                 as CompanyName,
               IDER.RuleType            as RuleType,
               IDER.RuleName            as RuleName,
               IDER.RuleDescription     as RuleDescription,
               @LI_ApplyToCustomBundleFlag                               as  ApplyToCustomBundleFlag,
               ltrim(rtrim(UC.FirstName + ' ' + UC.LastName))            as  CreatedByUserName,
               IDER.CreatedDate                                          as  CreatedDate,
               ltrim(rtrim(UM.FirstName + ' ' + UM.LastName))            as  ModifiedByUserName,
               IDER.ModifiedDate                                         as  ModifiedDate,
               row_number() OVER(ORDER BY IDER.[RuleIDSeq] asc)          as  [RowNumber],
               Count(1) OVER()                                           as  TotalBatchCountForPaging
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRule IDER with (nolock)
        inner join
               CUSTOMERS.dbo.Company COM with (nolock)
        on     IDER.CompanyIDSeq = COM.IDSeq
        and    IDER.CompanyIDSeq = @IPVC_CompanyIDSeq
        and    COM.IDSeq         = @IPVC_CompanyIDSeq
        left outer join
               Security.dbo.[User] UC with (nolock)
        on     IDER.CreatedByIDSeq = UC.IDSeq
        left outer join
               Security.dbo.[User] UM with (nolock)
        on     IDER.ModifiedByIDSeq = UM.IDSeq
        where  IDER.CompanyIDSeq = @IPVC_CompanyIDSeq
        and    (IDER.[RuleIDSeq]        = coalesce(@IPBI_RuleIDSeq,IDER.[RuleIDSeq]))
        and    (IDER.RuleType           = coalesce(@IPVC_RuleType,IDER.RuleType))
        and    (coalesce(IDER.RuleDescription,'') like '%' + @IPVC_RuleDescription + '%')              
        and    (IDER.CreatedByIDSeq = coalesce(@IPBI_UserIDSeq,IDER.CreatedByIDSeq))
       )
  select tablefinal.RuleIDSeq,
         tablefinal.CompanyIDSeq,
         tablefinal.CompanyName,
         tablefinal.RuleType,
         tablefinal.RuleName,
         tablefinal.RuleDescription,
         tablefinal.ApplyToCustomBundleFlag,
         tablefinal.CreatedByUserName,
         tablefinal.CreatedDate,
         tablefinal.ModifiedByUserName,
         tablefinal.ModifiedDate,
         tablefinal.TotalBatchCountForPaging
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END
GO
