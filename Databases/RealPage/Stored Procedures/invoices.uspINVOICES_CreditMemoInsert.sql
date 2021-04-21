SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : uspINVOICES_CreditMemoInsert   
-- Description     : This procedure inserts credit Details   
-- Input Parameters: @InvoiceIDSeq varchar(22),@TotalCreditAmount numeric(30,2),
--                   @TotalTaxAmount numeric(30,2),@TotalNetCreditAmount numeric(30,2),
--                   @CreditStatusCode varchar(6),@CreditReasonCode varchar(6),@CreatedBy varchar(22),
--                   @RequestedBy varchar(22),@RequestedDate DateTime,@Comments  varchar(50)
--                     
-- OUTPUT          :   
--  
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_CreditMemoInsert 
--                   'I0000000003',100.00,200.00,300.00,'ST1','RS1','Madhu','KRK','2007-01-12 20:13:21.500',
--                   'Comments on this Credit','26,28'
--   
--   
-- Revision History:  
-- Author          : STA  
-- 1/12/2007       : Stored Procedure Created.  
-- 08/27/2008      : Included shipping and handling amount in the INSERT and aligned the code. 
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspINVOICES_CreditMemoInsert] (                                                                                                           
                                                      @InvoiceIDSeq             varchar(22),
                                                      @TotalCreditAmount        numeric(30,2),
                                                      @TotalTaxAmount           numeric(30,2),
                                                      @TotalNetCreditAmount     numeric(30,2),
                                                      @CreditReasonCode         varchar(6),
                                                      @RequestedBy              varchar(22),
                                                      @RequestedDate            varchar(12),
                                                      @Comments                 varchar(4000),
                                                      @CrtBy                    varchar(50),
                                                      @CreditType               varchar(30),
                                                      @ILFCreditAmount          numeric(30,2),
                                                      @AccessCreditAmount       numeric(30,2),
                                                      @DoNotPrintCreditReason	bit,
                                                      @DoNotPrintCreditComments bit,
                                                      @CreditMemoIDSeq          varchar(22),
                                                      @SnHAmount                numeric(30,2),
                                                      @EpicorPostingCode        varchar(10),
                                                      @TaxwareCompanyCode       varchar(10),
                                                      @IPBI_UserIDSeq           bigint = -1    --> Mandatory : This is userID of the Person initiating this credit operation from UI.
                                                                                               --   UI already knows this value to pass in. 
                                                      )  
AS  
BEGIN   
  set nocount on;
  ----------------------------------------------------------------------------------
  DECLARE  @LDT_SystemDate             datetime,
           @LVC_CreditTypeCode         varchar(6);    
  ----------------------------------------------------------------------------------
  select @LDT_SystemDate     = GETDATE(),
         @LVC_CreditTypeCode = (Case when (@CreditType = 'FullCredit') 
                                       then 'FULC'
                                     when (@CreditType = 'TaxCredit' or @CreditType = 'FullTax') 
                                       then 'TAXC'
                                     when (@CreditType = 'PartialCredit') 
                                       then 'PARC'
                                     else 'PARC'
                              end); 
  ----------------------------------------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION 
      --      update INVOICES.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      --      set    IDSeq = IDSeq+1,
      --             GeneratedDate =CURRENT_TIMESTAMP 
      --      where  TypeIndicator = 'R'
      --
      --      select @LVC_NewCreditMemoIDSeq = IDGeneratorSeq
      --      from   INVOICES.DBO.IDGenerator with (NOLOCK)  
      --      where  TypeIndicator = 'R'
      ----------------------------------------------------------------------------------
      INSERT INTO  invoices.dbo.creditMemo
                   (
                    CreditMemoIDSeq,
                    InvoiceIDSeq,
	            TaxAmount,
	            TotalNetCreditAmount,
                    CreditStatusCode,
	            CreditReasonCode,	            
	            Comments,                    
                    CreditTypeCode,
                    ILFCreditAmount,
                    AccessCreditAmount,
                    ShippingAndHandlingCreditAmount,
	            DoNotPrintCreditReasonFlag,
	            DoNotPrintCreditCommentsFlag,
                    EpicorPostingCode,
                    TaxwareCompanyCode,
                    RequestedBy,                  
	            RequestedDate,
                    CreatedBy, 
                    CreatedByIDSeq,
	            CreatedDate, 
                    SystemLogDate
                   )
             select		     
                    @CreditMemoIDSeq                             as CreditMemoIDSeq,
                    @InvoiceIDSeq                                as InvoiceIDSeq,
	            Convert(NUMERIC(30,2),@TotalTaxAmount)       as TaxAmount,
	            Convert(NUMERIC(30,2),@TotalCreditAmount)    as TotalNetCreditAmount,
	            'PAPR'                                       as CreditStatusCode,
	            @CreditReasonCode                            as CreditReasonCode,	            
	            @Comments                                    as Comments,
                    @LVC_CreditTypeCode                          as CreditTypeCode,
                    Convert(NUMERIC(30,2),@ILFCreditAmount)      as ILFCreditAmount,
                    Convert(NUMERIC(30,2),@AccessCreditAmount)   as AccessCreditAmount,
                    Convert(NUMERIC(30,2),@SnHAmount)            as ShippingAndHandlingCreditAmount,
	            @DoNotPrintCreditReason                      as DoNotPrintCreditReasonFlag,
	            @DoNotPrintCreditComments                    as DoNotPrintCreditCommentsFlag,
                    @EpicorPostingCode                           as EpicorPostingCode,
                    @TaxwareCompanyCode                          as TaxwareCompanyCode,
                    @RequestedBy                                 as RequestedBy,
	            @RequestedDate                               as RequestedDate,   
                    ------------------                	            
                    @CrtBy                                       as CreatedBy,
                    @IPBI_UserIDSeq                              as CreatedByIDSeq,
                    @LDT_SystemDate                              as CreatedDate,
                    @LDT_SystemDate                              as SystemLogDate
                   
    COMMIT TRANSACTION
    ----------------------------------------------------------------------------    
  END TRY
  BEGIN CATCH
    select @CreditMemoIDSeq = NULL
    ---SELECT 'Credit Insert Section' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
        -- XACT_STATE:
             -- If 1, the transaction is committable.
             -- If -1, the transaction is uncommittable and should be rolled back.
             -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
        end 
        select @CreditMemoIDSeq as CreditMemoIDSeq
        EXEC CUSTOMERS.dbo.uspCUSTOMERS_RaiseError 'Credit Insert-New CreditID Generation Failed'   
  END CATCH 
  --------------------------------------------------------------------------------------- 
  select @CreditMemoIDSeq as CreditMemoIDSeq
END  
-----------------------------------------------------------------------------------------------
GO
