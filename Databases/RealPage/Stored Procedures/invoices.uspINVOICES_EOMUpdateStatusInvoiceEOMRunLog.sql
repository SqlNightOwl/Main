SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_EOMUpdateStatusInvoiceEOMRunLog]
-- Description     : This procedure accepts necessary parameters and records status of each orders/orderitems invoiced.
--                   Call by EOM for every record invoiced.
-- Input Parameters: As below
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_EOMUpdateStatusInvoiceEOMRunLog
--                                @IPDT_EOMBillingCycleDate = '02/15/2010',
--                                @IPI_EOMRunBatchNumber    = 1,@IPVC_EOMRunType='NewContractsBilling',
--                                @IPI_EOMRunStatus         = 1,@IPVC_ErrorMessage='',
--                                @IPVC_AccountIDSeq        = 'Axxxxxxxxxxxx',
--                                @IPVC_OrderIDSeq          ='Oxxxxxxxxx',@IPBI_OrderitemIDSeq=123456   
--
--Author           : SRS
--history          : Created 02/09/2010 Defect 7547

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_EOMUpdateStatusInvoiceEOMRunLog]  (@IPDT_EOMBillingCycleDate  datetime,
                                                                 @IPI_EOMRunBatchNumber     int,
                                                                 @IPVC_EOMRunType           varchar(200),
                                                                 @IPI_EOMRunStatus          int=1,
                                                                 @IPVC_ErrorMessage         varchar(max) = NULL,
                                                                 @IPVC_AccountIDSeq         varchar(50),
                                                                 @IPVC_OrderIDSeq           varchar(50),
                                                                 @IPBI_OrderitemIDSeq       bigint = NULL,
                                                                 @IPBI_UserIDSeq            bigint = NULL                                                                 
                                                                )
As
Begin
  set nocount on;
  ------------------------------------------------------------
  select @IPVC_ErrorMessage   = nullif(@IPVC_ErrorMessage,'');
  select @IPBI_OrderitemIDSeq = nullif(@IPBI_OrderitemIDSeq,'');
  select @IPBI_OrderitemIDSeq = coalesce(@IPBI_OrderitemIDSeq,0)
  ------------------------------------------------------------
  begin try
    Update INVOICES.dbo.InvoiceEOMRunLog
    set    EOMRunStatus    = @IPI_EOMRunStatus,
           ErrorMessage    = @IPVC_ErrorMessage,
           EOMRunDatetime  = Getdate(),
           ModifiedByIDSeq = @IPBI_UserIDSeq,
           ModifiedDate    = Getdate()
    where  AccountIDSeq    = @IPVC_AccountIDSeq
    and    OrderIDSeq      = @IPVC_OrderIDSeq
    and    coalesce(OrderitemIDSeq,0) = @IPBI_OrderitemIDSeq
    and    EOMRunBatchNumber = @IPI_EOMRunBatchNumber
    and    EOMRunType        = @IPVC_EOMRunType
    and    BillingCycleDate  = @IPDT_EOMBillingCycleDate
  End Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_EOMUpdateStatusInvoiceEOMRunLog. Update INVOICES.dbo.InvoiceEOMRunLog Failed.'
    return
  end   Catch 
  ------------------------------------------------------------
End
GO
