SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_InvoiceDetailsSelect
-- Description     : This procedure gets Invoice Details pertaining to passed InvoiceID
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(15)
--      
-- OUTPUT          : RcordSet of CompanyName,InvoiceidSeq,AccountId,SiteMsaterID,EpicoreId,
--                   Siebelid,PastDue,ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,
--                   SubTotal,Tax,Total,TotalDue,LastInvoiceDate,LastInvoicebalance,
--                   LastInvoiceDueDate,LastPaymentDate are generated             
--
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_InvoiceDetailsSelect @IPVC_InvoiceID ='I0808009645';
    
-- 
-- 
-- Revision History:
-- Author          : TMN
-- 12/01/2006      : Stored Procedure Created.
-- 01/10/2007      : Retrieved data for address from address table 
--                 : Removed values for Siebel id, Epicorid, and sitemasterid 
-- 10/25/2007      : Naval Kishore Added PrintFlag 
-- 02/25/2008	   : Naval Kishore Added InvoiceDate  
-- 05/20/2009	   : Naval kishore Modified to get Country Info for other countries.              
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceDetailsSelect] (@IPVC_InvoiceID  varchar(50)  
                                                           )
AS
BEGIN 
  set nocount on;
  exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID=@IPVC_InvoiceID;
  ------------------------------------------------------------------------
  declare   @LVC_InvoiceIDSeq               varchar(15)
  declare   @LVC_PropertyIDSeq              varchar(15)
  declare   @IPC_AccountID                  char(20)
  declare   @LVC_LastInvoiceID              varchar(20)
  declare   @LVN_LastAmountDue              numeric(30,2)
  declare   @LM_LastInvoiceBalance          money
  declare   @LD_LastInvoiceDate             varchar(12)
  declare   @LD_LastInvoiceDueDate          varchar(12)
  declare   @LD_LastPaymentDate             varchar(12)
  declare   @LM_LastPaymentBalance          money
  declare   @LV_Address                     varchar(200)
  declare   @LN_DocumentID                  varchar(50)
--  declare	@LVN_ILF						numeric(30,2)
--  declare	@LVN_Access						numeric(30,2)
--  declare	@LVN_Ancillary					numeric(30,2)
 

  set   @LVN_LastAmountDue      = 0
  set   @LM_LastInvoiceBalance  = 0
  set   @LM_LastPaymentBalance  = 0


  ----------------------------------------------------------------------------
  --Select InvoiceIDSeq into local variable @LVC_OrderIDSeq,
  --PropertyIDSeq into local variable @LVC_PropertIDSeq,
  --AccountIDSeq into local variable @IPC_AccountID
  --for the passed Input variable @IPVC_OrderID

  SELECT  @LVC_InvoiceIDSeq    = InvoiceIDSeq,
          @LVC_PropertyIDSeq   = PropertyIDSeq,
          @IPC_AccountID       = AccountIDSeq  
  FROM    Invoices.dbo.Invoice with (nolock)
  WHERE  InvoiceIDSeq           = @IPVC_InvoiceID


  select top 1  @LN_DocumentID = DocumentIDSeq
  from Documents.dbo.Document with (nolock)
  where InvoiceIDSeq = @LVC_InvoiceIDSeq
  and AttachmentFlag = 1
  and ActiveFlag = 1 ORDER BY DocumentIDSeq DESC

  ----------------------------------------------------------------------------

      select  I.InvoiceIDSeq,
              isnull(PropertyName, CompanyName) Name,
              I.AccountIDSeq AS CompanyAccountIDSeq,
              I.BillToAddressLine1 as AddressLIne1,
              BillToAddressLine2 as AddressLIne2,
              BillToCity as City,
              BillToState as State,
              BillToZip as Zip,
              I.ILFChargeAmount,
              I.AccessChargeAmount,
              I.TransactionChargeAmount,
              I.ShippingandHandlingAmount,
              I.TaxAmount,
              I.CreditAmount      
      from   INVOICES.DBO.[Invoice] I with (nolock)

      where  I.InvoiceIDSeq = @LVC_InvoiceIDSeq




 
  -----------------------------------------------------------------------------
  -- TO Get Past Due Information
  -- select @LN_LastAmountDue from sum of ILFChargeAmount,
  -- TransactionChargeAmount, and TaxAmount
  -- from the previous invoiceId and AccountID
  -- (i.e) Before the current Invoice
  -- Calculation of Past due
  -----------------------------------------------------------------------------
  SELECT TOP  1 @LVC_LastInvoiceID = InvoiceIDSeq, 
              @LVN_LastAmountDue = (ILFChargeAmount
                                      + AccessChargeAmount
                                        + TransactionChargeAmount
                                        + ShippingandHandlingAmount
                                          + TaxAmount - CreditAmount)
           
  FROM        Invoices.dbo.[Invoice] with (nolock) 
  WHERE       InvoiceIDSeq < @IPVC_InvoiceID
  AND         AccountIDSeq = @IPC_AccountID
  ORDER BY InvoiceIDSeq DESC
  
  -----------------------------------------------------------------------------
  --
  -- TO get the Past due invoice due for last invoice
  -- 
  -----------------------------------------------------------------------------
  IF @LVC_LastInvoiceID IS NOT NULL
  BEGIN
   /* ;with CTE_IP(TotalInvoiceAmtPaid)
   as (select sum(IP.InvoiceTotalAmount) as TotalInvoiceAmtPaid
       from   Invoices.dbo.InvoicePayment IP with (nolock)       
       where  IP.InvoiceIDSeq = @LVC_LastInvoiceID   
       and    IP.PaymentGatewayResponseCode = 'Success'       
      )
   select  @LVN_LastAmountDue = @LVN_LastAmountDue - coalesce(CTE_IP.TotalInvoiceAmtPaid,0)
   from    CTE_IP; 
   */ 

   --> OMS does not deal with Payments. For PrePaid II invoices, Payment info is records for reporting purposes only.
   -- Hence @LVN_LastAmountDue will have to be 0
   select @LVN_LastAmountDue = 0 
  END
  --
  -----------------------------------------------------------------------
  -- To get the last invoice date and Last InvoiceDueDate
  --  
  -- --------------------------------------------------------------------
  IF @LVC_LastInvoiceID IS NOT NULL
  BEGIN
    select    @LD_LastInvoiceDate     = convert(varchar(12),InvoiceDate,101),
              @LD_LastInvoiceDueDate  = convert(varchar(12),InvoiceDueDate,101)
    from      Invoices.dbo.invoice with (nolock)
    where     InvoiceIDSeq < @IPVC_InvoiceID
    and       AccountIDSeq = @IPC_AccountID
    order by  InvoiceIDSeq desc
  END  
  -----------------------------------------------------------------------
  -- 
  -- To get the last invoice Balance and to store the value in 
  -- Local variable @LM_LastInvoiceBalance
  -- Calculation of last invoice balance
  -----------------------------------------------------------------------
   SELECT TOP 1 @LVC_LastInvoiceID = InvoiceIDSeq, 
              @LM_LastInvoiceBalance = ILFChargeAmount
                                        + AccessChargeAmount
                                          + TransactionChargeAmount
                                          + ShippingandHandlingAmount
                                            + TaxAmount
     
   FROM       Invoices.dbo.[Invoice] with (nolock) 
   WHERE      InvoiceIDSeq < @IPVC_InvoiceID
   AND        AccountIDSeq = @IPC_AccountID
   ORDER BY   InvoiceIDSeq DESC
   
  -----------------------------------------------------------------------------------
  --To get Last invoice balance
  -----------------------------------------------------------------------------------
  IF @LVC_LastInvoiceID IS NOT NULL
  BEGIN
    select  @LM_LastInvoiceBalance = @LM_LastInvoiceBalance - sum(CreditAmount)
    from    Invoices.dbo.invoice with (nolock)
    where   InvoiceIDSeq = @LVC_LastInvoiceID
  END  


  -------------------------------------------------------------------------------------
  -- 
  -- Last Payment Information
  --To get last payment date from invoicepayment
  -------------------------------------------------------------------------------------
  
  IF @LVC_LastInvoiceID IS NOT NULL
  BEGIN
    /*;with CTE_IP(LastPaymentDate)
     as (select convert(varchar(12),Max(IP.PaymentTransactionDate),101) as LastPaymentDate
         from   Invoices.dbo.InvoicePayment IP with (nolock)
         inner join
                Invoices.dbo.Invoice I with (nolock)
         on     I.InvoiceIDSeq = IP.InvoiceIDSeq
         and    I.AccountIDSeq = @IPC_AccountID
         and    IP.PaymentGatewayResponseCode = 'Success'
         and    IP.InvoiceIDSeq < @IPVC_InvoiceID
         and    I.InvoiceIDSeq  < @IPVC_InvoiceID
         where  I.AccountIDSeq = @IPC_AccountID       
        )
    select  @LD_LastPaymentDate = CTE_IP.LastPaymentDate
    from    CTE_IP;
    */

   --> OMS does not deal with Payments. For PrePaid II invoices, Payment info is records for reporting purposes only.
   -- Hence @LD_LastPaymentDate will have to be NULL
   select  @LD_LastPaymentDate = NULL
  END  

  IF (@LVC_PropertyIDSeq IS NULL)
  BEGIN 
    select  @LV_Address   = BillToAddressLine1
    from    Invoices.dbo.Invoice with (nolock)
    where   InvoiceIDSeq  = @IPVC_InvoiceID
  END 

--	SELECT sum(NetChargeAmount) from InvoiceItem 
--					where InvoiceIDSeq=@IPVC_InvoiceID and ReportingTypeCode='ILFF'
--	SELECT sum(NetChargeAmount) from InvoiceItem 
--					where InvoiceIDSeq=@IPVC_InvoiceID and ReportingTypeCode='ANCF' AND MeasureCode!='TRAN'
--	SELECT  sum(NetChargeAmount) from InvoiceItem 
--					where InvoiceIDSeq=@IPVC_InvoiceID and ReportingTypeCode='ACSF'AND MeasureCode!='TRAN'
					



  -------------------------------------------------------------------------------------
  -- 
  -- To get last payment Amount
  -- No sufficient data
  -------------------------------------------------------------------------------------

  -------------------------------------------------------------------------------------
  -- 
  --  To get last payment next Invoice
  --  NO sufficient column in database
  -------------------------------------------------------------------------------------


   -------------------------------------------------------------------------------------
   -- Final select
   -------------------------------------------------------------------------------------
  SELECT            I.PropertyName                                       as PropertyName, 
                    CompanyName                                         as CompanyName,
                    CompanyIDSeq                                        as CompanyIDSeq,
                    I.InvoiceIdSeq                                      as InvoiceIDSeq,
                    I.AccountIDSeq                                      as AccountID,
                    (select top 1 A.IDSeq from Customers.dbo.Account A with (nolock) 
                     where A.CompanyIDSeq = I.CompanyIDSeq 
                     and   A.AccounttypeCode = 'AHOFF'
                     and   A.propertyIDSeq is null
                     and   A.ActiveFlag = 1 
						        )                as CompanyAccountIDSeq,

                    I.BillToAddressLIne1                                 as AddressLine1 ,
                    I.BillToAddressLIne2                                 as AddressLine2 , 
                    I.BillToCity                                         as City, 
                    I.BillToState                                        as State,
                    I.BillToZip                                          as Zip,
					UPPER(I.BillToCountry)								 as Country,
                    convert(numeric(30,2),
                      ISNULL(@LVN_LastAmountDue, 0))                as PastDue,
                     
                    --Total Due
                    ------------------------------------------------------------
                    /* Commented these as these are calculated below from invoice item table
                    convert(numeric(30,2),
                      isnull(I.ILFChargeAmount,0))                  as InitialLicenseFees,
                    convert(numeric(30,2),
                        isnull(I.AccessChargeAmount,0))             as AccessFees,
                    */
                    ------------------------------------------------------------
                    /*
                    convert(numeric(30,2),
                      isnull((SELECT  sum(TotalNetCreditAmount+TaxAmount)
                              FROM    Invoices.dbo.CreditMemo with (nolock) 
                              WHERE   InvoiceIDSeq = I.InvoiceIDSeq
                               AND    CreditStatusCode = 'APPR'),0))                     as CreditAmount,
                     */
                    ------------------------------------------------------------
                    convert(numeric(30,2),
                      isnull((SELECT  sum(TotalNetCreditAmount) + sum(TaxAmount) + sum(ShippingAndHandlingCreditAmount)
                              FROM    Invoices.dbo.CreditMemo with (nolock) 
                              WHERE   InvoiceIDSeq = I.InvoiceIDSeq
                               AND    CreditStatusCode = 'APPR'),0))                     as CreditAmount,
                    ------------------------------------------------------------
					convert(numeric(30,2),
					isnull(I.ShippingAndHandlingAmount,0))	as  ShippingAndHandlingAmount,
					convert(numeric(30,2),
							isnull((SELECT sum(NetChargeAmount) 
                                    from Invoices.dbo.InvoiceItem with (nolock) 
					                where InvoiceIDSeq = @IPVC_InvoiceID 
                                      and ReportingTypeCode='ILFF'),0)) as InitialLicenseFees,
					convert(numeric(30,2),
							isnull((SELECT  sum(NetChargeAmount) 
                                    from Invoices.dbo.InvoiceItem with (nolock) 
					                where InvoiceIDSeq = @IPVC_InvoiceID 
                                      and ReportingTypeCode='ACSF'
                                      AND MeasureCode!='TRAN'),0)) as AccessFees,
					convert(numeric(30,2),
							isnull((SELECT sum(NetChargeAmount) 
                                    from Invoices.dbo.InvoiceItem with (nolock) 
					                where InvoiceIDSeq = @IPVC_InvoiceID 
                                      and ReportingTypeCode='ANCF' 
                                      AND MeasureCode!='TRAN'),0)) as Ancillary,
                    convert(numeric(30,2),
                      isnull(I.TransactionChargeAmount,0))          as TransactionFees,

                    convert(numeric(30,2),
                      isnull(I.ILFChargeAmount,0)
                        + isnull(I.AccessChargeAmount,0)
                          + isnull(I.TransactionChargeAmount,0))
                                                                                        as SubTotal,

                    convert(numeric(30,2),isnull(I.TaxAmount,0))                        as TaxAmount,
                     convert(numeric(30,2),
                      isnull(I.ILFChargeAmount,0)
                        + isnull(I.AccessChargeAmount,0)
                          + isnull(I.TransactionChargeAmount,0)
                          + isnull(I.ShippingandHandlingAmount,0)
                            + isnull(I.TaxAmount,0))  as Total,
--                              - isnull((SELECT  sum(TotalNetCreditAmount+TaxAmount) 
--                              FROM    Invoices..CreditMemo 
--                              WHERE   InvoiceIDSeq = I.InvoiceIDSeq
--                                      AND    CreditStatusCode = 'APPR'),0))          as Total, 

                     -- The current charges and Total are the same
                    convert(numeric(30,2),
                      isnull(I.ILFChargeAmount,0)
                        + isnull(I.AccessChargeAmount,0)
                          + isnull(I.TransactionChargeAmount,0)
                            + isnull(I.TaxAmount,0)
                            + isnull(I.ShippingandHandlingAmount,0)
--                              - isnull(I.CreditAmount,0)
                                - isnull(@LVN_LastAmountDue,0))     as TotalDue,

                    -- Last Invoice Data 
                    isnull(convert(varchar(12),@LD_LastInvoiceDate,101),'N/A')               as LastInvoiceDate,
                    @LM_LastInvoiceBalance                          as LastInvoiceBalance,
                    isnull(convert(varchar(12),@LD_LastInvoiceDueDate,101),'N/A')            as LastInvoiceDueDate,

                    -- Last Payment Data   
                    isnull(@LD_LastPaymentDate,'N/A')              as LastPaymentDate,
                    --@LM_LastPaymentBalance                 as LastPaymentBalance 
                    --Next Payment Date

              isnull(@LN_DocumentID, 0) as DocumentID,
              isnull(convert(varchar(12), OriginalPrintDate, 101), 'N/A') as OriginalPrintDate,
              isnull(EpicorBatchCode, 'N/A') as EpicorBatchCode,
              isnull(SentToEpicorStatus, 'NOT SENT')               as SentToEpicorStatus,
              I.PrintFlag as PrintFlag,
			  isnull(convert(varchar(12),InvoiceDate, 101), 'N/A') as InvoiceDate,
			  (case when (I.EpicorCustomerCode='0' or I.EpicorCustomerCode is null)
                  then ''
                  else  I.EpicorCustomerCode end)                  as EpicorId,
              coalesce(IRM.ReportDefinitionFile,'Invoice1')    as ReportDefinitionFile           
    FROM      Invoices.dbo.[Invoice] I with (nolock)
    Left outer Join
              Products.dbo.InvoiceReportMapping IRM with (nolock)
    on       I.SeparateInvoiceGroupNumber = IRM.SeparateInvoiceGroupNumber 
  
    WHERE           I.InvoiceIDSeq = @IPVC_InvoiceID

     
  ----------------------------------------------------------------------------
END 
GO
