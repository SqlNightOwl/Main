SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_UpdatePrintFlag]
-- Description     : Updates the print flag
-- Syntax          : EXEC INVOICES.dbo.uspINVOICES_UpdatePrintFlag @IPVC_InvoiceID = 'I0901000609',@IPBI_UserIDSeq=123
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006        : Stored Procedure Created.
-- 10/26/2007      : Naval Kishore Added OriginalPrintDate,printcount 
-- 05/20/2011      : TFS 592 SRS - After XML Generate process, Core Attributes of Invoice header should not be touched.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UpdatePrintFlag] (@IPVC_InvoiceID         varchar(50),
                                                      @IPVC_PrePaidEmailID    varchar(4000)='',
                                                      @IPBI_UserIDSeq         bigint       =-1  ---> MANDATORY : User ID of the User Logged on and doing the operation.
                                                     )
AS
BEGIN
  set nocount on;
  ---------------------------------
  declare @LDT_SystemDate  datetime
  select  @LDT_SystemDate = Getdate()
  select  @IPVC_PrePaidEmailID = nullif(ltrim(rtrim(@IPVC_PrePaidEmailID)),'')
  ---------------------------------
  BEGIN TRY
    ------------------------------------------------------------------
    --Step1 : Update for Print Flag
    ------------------------------------------------------------------
    update Invoices.dbo.Invoice 
    set    PrintFlag          = 1,    
           OriginalPrintDate  = (case when PrintFlag = 0 then @LDT_SystemDate else OriginalPrintDate end),
           BillToEmailAddress = (case when Prepaidflag = 1 then coalesce(@IPVC_PrePaidEmailID,BillToEmailAddress) else BillToEmailAddress end),
           ReprintDate        = @LDT_SystemDate,
           PrintCount         = PrintCount + 1,
           ModifiedByIDSeq    = @IPBI_UserIDSeq,
           ModifiedDate       = @LDT_SystemDate,
           SystemLogDate      = @LDT_SystemDate
    where  InvoiceIDSeq       = @IPVC_InvoiceID;  
    ------------------------------------------------------------------------------------------
    --Step 2: Update For Orderitem for POILastBillingPeriodFrom and To Date, for Invoice Close
    ------------------------------------------------------------------------------------------
    ;with II_CTE (OrderIDSeq,OrderGroupIDSeq,OrderItemIDSeq,
                  MinBillingPeriodFromDate,MaxBillingPeriodToDate,
                  Units,Beds,PPUPercentage
                 )
    as (Select     II.OrderIDSeq,II.OrderGroupIDSeq,II.OrderItemIDSeq,
                   MIN(II.BillingPeriodFromDate) as [MinBillingPeriodFromDate],
                   MAX(II.BillingPeriodToDate)   as [MaxBillingPeriodToDate],
                   Max(II.Units)                 as Units,
                   Max(II.Beds)                  as Beds,
                   Max(II.PPUPercentage)         as PPUPercentage
            from   Invoices.dbo.InvoiceItem II with (nolock)  
            where  II.InvoiceIDSeq=@IPVC_InvoiceID
            group by II.OrderIDSeq,II.OrderGroupIDSeq,II.OrderItemIDSeq
       )
    update OI
    set    OI.PrintedOnInvoiceFlag = 1,
           OI.POILastBillingPeriodFromDate = (Case when OI.POILastBillingPeriodFromDate is null then S.MinBillingPeriodFromDate
                                                   when (isdate(OI.POILastBillingPeriodFromDate)=1 and OI.POILastBillingPeriodFromDate <= S.MinBillingPeriodFromDate)
                                                     then OI.POILastBillingPeriodFromDate
                                                   else   S.MinBillingPeriodFromDate
                                              end),
           OI.POILastBillingPeriodToDate   = (Case when OI.POILastBillingPeriodToDate is null then S.MaxBillingPeriodToDate
                                                   when (isdate(OI.POILastBillingPeriodToDate)=1 and OI.POILastBillingPeriodToDate <= S.MaxBillingPeriodToDate)
                                                     then S.MaxBillingPeriodToDate
                                                   else   OI.POILastBillingPeriodToDate
                                              end),  
           OI.POIUnits                     = S.Units,
           OI.POIBeds                      = S.Beds,
           OI.POIPPUPercentage             = S.PPUPercentage,
           OI.SystemLogDate                = @LDT_SystemDate
    from   Orders.dbo.OrderItem OI with (nolock)
    inner join
           II_CTE               S  with (nolock)
    on     OI.OrderIDSeq      = S.OrderIDSeq
    and    OI.OrderGroupIDSeq = S.OrderGroupIDSeq
    and    OI.IDSeq           = S.OrderItemIDSeq;
    ------------------------------------------------------------------------------------------
    --Step 3: Update InvoicedFlag,PrintedOnInvoiceFlag For OrderItemTransaction for Invoice Close
    ------------------------------------------------------------------------------------------
    ;with II_CTE (OrderIDSeq,OrderGroupIDSeq,OrderItemIDSeq,OrderItemTransactionIDSeq)
     as (select II.OrderIDSeq,II.OrderGroupIDSeq,II.OrderItemIDSeq,II.OrderItemTransactionIDSeq
            from   Invoices.dbo.InvoiceItem II with (nolock)                   
            where  II.InvoiceIDSeq=@IPVC_InvoiceID
            and    II.OrderItemTransactionIDSeq is not null
           )
    Update OIT
    set    OIT.InvoicedFlag         = 1,
           OIT.PrintedOnInvoiceFlag = 1,
           OIT.SystemLogDate        = @LDT_SystemDate
    from   Orders.dbo.[OrderItemTransaction] OIT with (nolock)
    inner Join
           II_CTE                            S   with (nolock)
    on     OIT.IDSeq           = S.OrderItemTransactionIDSeq --> This is Unique Primary Key for Orderitem Transaction
    and    OIT.OrderIDSeq      = S.OrderIDSeq
    and    OIT.OrderGroupIDSeq = S.OrderGroupIDSeq
    and    OIT.OrderItemIDSeq  = S.OrderItemIDSeq   
  END TRY
  BEGIN CATCH
  END   CATCH;
  ---------------------------------
END
GO
