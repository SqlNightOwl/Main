SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : [uspCredits_CreditMemoUpdate]   
-- Description     : This procedure updates credit Details   
-- Input Parameters: @TotalCreditAmount numeric(10,2),
--                   @TotalTaxAmount numeric(10,2),@TotalNetCreditAmount numeric(10,2),
--                   @CreditStatusCode varchar(6),@CreditReasonCode varchar(6),@CreatedBy varchar(22),
--                   @RequestedBy varchar(22),@RequestedDate DateTime,@Comments  varchar(50)
--                     
-- OUTPUT          :   
--  
--                     
-- Code Example    : Exec Invoices.dbo.uspCredits_CreditMemoUpdate 
--                   100.00,200.00,300.00,'ST1','RS1','Madhu','KRK','2007-01-12 20:13:21.500',
--                   'Comments on this Credit','26,28'  
--   
-- Revision History:  
-- Author          : Shashi Bhushan
-- 10/11/2007      : Stored Procedure Created.  
-- 12/26/2007      : Naval Kishore Modified Strored Procedure 
-- 08/27/2008      : Included Shipping and handling amount and aligned the code
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspCredits_CreditMemoUpdate] (@CreditMemoIDSeq		varchar(50),
                                                      @TotalTaxAmount           numeric(30,2),
                                                      @TotalNetCreditAmount     numeric(30,2),
                                                      @CreditReasonCode         varchar(6),
                                                      @RequestedBy		varchar(22),
                                                      @RevisedBy		varchar(22),
                                                      @RevisedDate		varchar(12),
                                                      @Comments                 varchar(4000),
                                                      @ILFCreditAmount          numeric(30,2),
                                                      @AccessCreditAmount       numeric(30,2),
                                                      @DoNotPrintCreditReason	bit,
                                                      @DoNotPrintCreditComments bit,
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
  DECLARE  @LDT_SystemDate     datetime;          
  select   @LDT_SystemDate     = GETDATE();
  ----------------------------------------------------------------------------------
  --              Updating into the Credit Memo Table
  ----------------------------------------------------------------------------------
  UPDATE Invoices.dbo.CreditMemo
  SET    TaxAmount                       = @TotalTaxAmount,
	 TotalNetCreditAmount            = @TotalNetCreditAmount,
         CreditStatusCode                = 'PAPR',
	 CreditReasonCode                = @CreditReasonCode,	 
	 Comments                        = @Comments,
	 ILFCreditAmount                 = @ILFCreditAmount,
	 AccessCreditAmount              = @AccessCreditAmount, 
	 DoNotPrintCreditReasonFlag      = @DoNotPrintCreditReason,
	 DoNotPrintCreditCommentsFlag    = @DoNotPrintCreditComments,
         ShippingAndHandlingCreditAmount = @SnHAmount,
         EpicorPostingCode               = @EpicorPostingCode,
         TaxwareCompanyCode              = @TaxwareCompanyCode,
         RequestedBy                     = @RequestedBy,
	 RevisedBy                       = @RevisedBy,
         RevisedDate                     = @RevisedDate,
         ModifiedBy                      = @RevisedBy,
         ModifiedDate                    = @LDT_SystemDate,
         ModifiedByIDSeq                 = @IPBI_UserIDSeq,
         SystemLogDate                   = @LDT_SystemDate
  WHERE  CreditMemoIDSeq                 = @CreditMemoIDSeq    
END  
-----------------------------------------------------------------------------------------------
GO
