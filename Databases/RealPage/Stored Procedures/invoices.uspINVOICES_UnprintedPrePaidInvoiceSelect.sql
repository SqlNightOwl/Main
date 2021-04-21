SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_UnprintedPrePaidInvoiceSelect
-- Description     : This procedure gets called by UI to retrieve all Unprinted PrePaid Invoices for a given Quote
--                   This will be called at the tail end of Quote Approval process, which by now
--                   UI would have created Orders, AutoFulfilled Orders, Created Invoices with Taxes
-- Input Parameters: @IPVC_QuoteIDSeq varchar(50)
--
-- 
-- OUTPUT          : ResultSet of InvoiceIDs
--
-- Code Example    : Exec INVOICES.[dbo].[uspINVOICES_UnprintedPrePaidInvoiceSelect] @IPVC_QuoteIDSeq = 'Q0911000538',@IPBI_UserIDSeq=123
--
-- Author          : SRS
-- 06/06/2011      : Stored Procedure Created. TFS # 662 PrePaid Invoices Domin-8
-- Author          : Satya B
-- 07/18/2011      : Enhance (newly added for R5) Proc for domin-8 instant invoice short term solution with refence to TFS #295 Instant Invoice Transactions through OMS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE procedure [invoices].[uspINVOICES_UnprintedPrePaidInvoiceSelect] (@IPVC_QuoteIDSeq        varchar(50),     ---> Mandatory. This the Quote that is approved for Prepaid Instant Invoice.
                                                                    @IPBI_UserIDSeq         bigint      =-1  ---> MANDATORY : User ID of the User Logged on and doing the operation.
                                                                   )
AS
BEGIN -- :Main Begin
  set nocount on;
  ------------------------------------------------------------------
  declare @LDT_SystemDate  datetime
  select  @LDT_SystemDate = Getdate()

  declare @LT_UnPrintedPrepaidInvoice table
                                     (CompanyIDSeq                    varchar(50),
                                      PropertyIDSeq                   varchar(50),
                                      InvoiceIDSeq                    varchar(50),
                                      OrderIDSeq                      varchar(50),
                                      CompanyName                     varchar(255),
                                      PropertyName                    varchar(255),
                                      AccountName                     varchar(255), 
                                      EpicorID                        varchar(50),
                                      NetCharge                       money,    
                                      ShippingandHandlingAmount       money,
                                      TaxAmount                       money,
                                      TotalAmount                     money
                                     );
  ------------------------------------------------------------------
  ;with Orders_CTE (QuoteIDSeq,OrderIDSeq)
   as (select O.QuoteIDSeq				as QuoteIDSeq,
              O.OrderIDSeq				as OrderIDSeq            
       from   ORDERS.dbo.[Order] O with (nolock)
       where  O.QuoteIDSeq  = @IPVC_QuoteIDSeq
      ),
   Invoice_CTE (CompanyIDSeq,PropertyIDSeq,InvoiceIDSeq,OrderIDSeq,CompanyName,PropertyName,AccountName,EpicorID,
                NetCharge,ShippingandHandlingAmount,TaxAmount,TotalAmount
               )
   as (select 
              max(Iinner.CompanyIDSeq)                                    as CompanyIDSeq,
              max(Iinner.PropertyIDSeq)                                   as PropertyIDSeq,
              Iinner.InvoiceIDSeq                                         as InvoiceIDSeq, 
              OCTE.OrderIDSeq                                             as OrderIDSeq, 
              Max(Iinner.CompanyName)                                     as CompanyName,
              Max(Iinner.PropertyName)                                     as PropertyName,
              Max(coalesce(Iinner.PropertyName, Iinner.CompanyName))      as AccountName,
              Max(Iinner.EpicorCustomerCode)                              as EpicorID,
              ----------------------------
              SUM(II.NetChargeAmount)	                                  as NetCharge,
              SUM(II.ShippingandHandlingAmount)                           as ShippingandHandlingAmount,
              SUM(II.TaxAmount)                                           as TaxAmount,
              SUM(II.NetChargeAmount) + SUM(II.TaxAmount)                 as TotalAmount
              ----------------------------
       from   INVOICES.dbo.Invoice     Iinner with (nolock)
       inner join 
              INVOICES.DBO.InvoiceItem II     with (nolock) 
       on     II.InvoiceIDSeq    = Iinner.InvoiceIDSeq
       and    Iinner.PrintFlag   = 0
       and    Iinner.PrePaidFlag = 1
       inner join 
              Orders_CTE OCTE 
       on     II.OrderIDSeq      = OCTE.OrderIDSeq
       where  Iinner.PrintFlag   = 0
       and    Iinner.PrePaidFlag = 1
       group by Iinner.InvoiceIDSeq,OCTE.OrderIDSeq
       )
  insert into @LT_UnPrintedPrepaidInvoice(CompanyIDSeq,PropertyIDSeq,InvoiceIDSeq,OrderIDSeq,CompanyName,PropertyName,AccountName,EpicorID,
                                          NetCharge,ShippingandHandlingAmount,TaxAmount,TotalAmount
                                         )
  select ICTE.CompanyIDSeq,ICTE.PropertyIDSeq,ICTE.InvoiceIDSeq,ICTE.OrderIDSeq,ICTE.CompanyName,ICTE.PropertyName,ICTE.AccountName,ICTE.EpicorID,
         ICTE.NetCharge,ICTE.ShippingandHandlingAmount,ICTE.TaxAmount,ICTE.TotalAmount
  from   Invoice_CTE ICTE;
  ------------------------------------------------------------------
  Update I
  set    I.XMLProcessingStatus = 1,  --> This is because this Instant Invoice Process does not go through XML Generator.
         I.InvoiceDate         = Convert(varchar(50),@LDT_SystemDate,101),
         I.InvoiceDueDate      = Convert(varchar(50),dateadd(mm,1,@LDT_SystemDate),101),
         I.ModifiedByIDSeq     = @IPBI_UserIDSeq,
         I.ModifiedDate        = @LDT_SystemDate,
         I.SystemLogDate       = @LDT_SystemDate  
  from   Invoices.dbo.Invoice I with (nolock)
  inner join
         @LT_UnPrintedPrepaidInvoice  ICTE 
  on     I.InvoiceIDSeq = ICTE.InvoiceIDSeq
  and    I.PrintFlag   = 0
  and    I.PrePaidFlag = 1
  where  I.PrintFlag   = 0
  and    I.PrePaidFlag = 1;         
  ------------------------------------------------------------------
  --Final Select to UI
  select          
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then 'Total'
               else InvoiceIDSeq
          end)                as InvoiceIDSeq,                ---> This is Instant InvoiceID. UI to bind and show in Modal (page 3 grid) for Instant Invoice ID
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then ''
               else Max(CompanyIDSeq)
          end)                as CompanyIDSeq,                ---> This is CompanyIDSeq (informational). UI may or may not use it.
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then ''
               else Max(PropertyIDSeq)
          end)                as PropertyIDSeq,               ---> This is PropertyIDSeq (informational). UI may or may not use it.
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then ''
               else OrderIDSeq
          end)                as OrderIDSeq,                  ---> This is OrderIDSeq. UI to bind and show in Modal (page 3 grid) for OrderID
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then ''
               else Max(CompanyName)
          end)                as CompanyName,                 ---> This is CompanyName (informational). UI may or may not use it.
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then ''
               else Max(PropertyName)
          end)                as PropertyName,                ---> This is PropertyName (informational). UI may or may not use it. 
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then ''
               else Max(AccountName)
          end)                as AccountName,                 ---> This is AccountName. UI to bind and show in Modal (page 3 grid) for Account Name
         (case when (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1) then ''
               else Max(EpicorID)
          end)                as EpicorID,                    ---> This is EpicorID. UI to bind and show in Modal (page 3 grid) for EpicorID
         sum(NetCharge)       as NetCharge,                   ---> This is NetCharge. UI to bind and show in Modal (page 3 grid) for Net Charge 
         sum(ShippingandHandlingAmount) as ShippingandHandlingAmount, ---> This is ShippingandHandlingAmount. UI to bind and show in Modal (page 3 grid) for Shipping Handling 
         Sum(TaxAmount)       as TaxAmount,                   ---> This is TaxAmount. UI to bind and show in Modal (page 3 grid) for Tax
         Sum(TotalAmount)     as TotalAmount,                 ---> This is TotalAmount. UI to bind and show in Modal (page 3 grid) for Total Amount
         row_number() OVER(ORDER BY [InvoiceIDSeq] desc)   as  [RowNumber], --> This is the RowNumber of record. UI to use it internally to show number of rows in a page (only if needed)
         Count(1) OVER()                                   as  TotalBatchCountForPaging --> This is totalBatchCount for Pagination. UI to use it internally (only if needed)
  from   @LT_UnPrintedPrepaidInvoice
  group by InvoiceIDSeq,OrderIDSeq
  WITH CUBE
  having (
          (GROUPING(InvoiceIDSeq) = 0 and GROUPING(OrderIDSeq) = 0)
           OR
          (GROUPING(InvoiceIDSeq) = 1 and GROUPING(OrderIDSeq) = 1)
         )
  ------------------------------------------------------------------
END -- :Main End
GO
