SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [invoices].[uspINVOICES_SyncUnPrintedInvoicesAndCredits]
AS
BEGIN   
  set nocount on;
  ---------------------------------------------------------
  declare @imin  bigint;
  declare @imax  bigint;
  declare @LVC_InvoiceID varchar(50);
  ---------------------------------------------------------
  Create Table #LT_SyncInvoices(SEQ        bigint not null identity(1,1),
                                InvoiceID  varchar(50)
                               )
  ---------------------------------------------------------
  Insert into #LT_SyncInvoices(InvoiceID)
  select distinct InvoiceIDSeq 
  from Invoices.dbo.Creditmemo with (nolock) 
  where CreditStatuscode <> 'DENY' and SentToEpicorFlag = 0
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select I.InvoiceIDSeq
      from   Invoices.dbo.Invoice I with (nolock)
      inner join
             Customers.dbo.Address A with (nolock)
      on     I.CompanyIdSeq        = A.CompanyIdSeq    
      and    I.PrintFlag           = 0           
      and    I.BillToAddressTypeCode  = A.Addresstypecode
      and   (
             (I.BillToAddressTypeCode = A.Addresstypecode and 
              I.BillToAddressTypeCode like 'PB%'          and
              I.CompanyIdSeq  = A.CompanyIdSeq            and
              I.PropertyIDSeq = A.PropertyIDSeq           and 
              I.PropertyIDSeq is not null                 and
              A.PropertyIDSeq is not null                 
             )
              OR
             (I.BillToAddressTypeCode = A.Addresstypecode and 
              I.BillToAddressTypeCode NOT like 'PB%'      and
              I.CompanyIdSeq  = A.CompanyIdSeq            
             )
           )
      and (
            I.BillToAddressLine1 <> A.AddressLine1 
             OR 
            coalesce(ltrim(rtrim(I.BillToAddressLine2)),'') <> coalesce(ltrim(rtrim(A.AddressLine2)),'')
             OR 
            I.BillToCity <> A.City
             OR
            I.BillToState <> A.State
             OR 
            I.BillToZip <> A.Zip
             OR 
            coalesce(ltrim(rtrim(I.BillToCountry)),'') <> coalesce(ltrim(rtrim(A.Country)),'')
             OR
            coalesce(ltrim(rtrim(I.BillToEmailAddress)),'') <> coalesce(ltrim(rtrim(A.Email)),'')
          )
      where  I.PrintFlag              = 0      
      and    I.CompanyIdSeq           = A.CompanyIdSeq
      and    I.BillToAddressTypeCode  = A.Addresstypecode
  ------------------------------------------------
  Insert into #LT_SyncInvoices(InvoiceID)
  select  S.InvoiceIDSeq
  from (select I.InvoiceIDSeq,
             (sum(I.ILFChargeAmount) + sum(I.AccessChargeAmount) +
              sum(I.TransactionChargeAmount) + 
              sum(I.ShippingandHandlingAmount) + 
              sum(I.TaxAmount))      as InvoiceHeaderGrandTotal
      from   Invoices.dbo.Invoice I with (nolock) 
      where  I.SentToEpicorFlag = 0
      group by I.InvoiceIDSeq
     ) S 
  inner join
     (select IIX.InvoiceIDSeq,
            (sum(IIX.NetChargeAmount)+sum(IIX.ShippingandHandlingAmount)+
             sum(IIX.TaxAmount)) as InvoiceDetailGrandTotal
        from   Invoices.dbo.Invoiceitem IIX with (nolock) 
        inner join
               Invoices.dbo.Invoice IX with (nolock)  
        on     IIX.InvoiceIDSeq = IX.InvoiceIDSeq
        and    IX.SentToEpicorFlag = 0
        group by IIX.InvoiceIDSeq
       ) D 
  on    S.InvoiceIDSeq = D.InvoiceIDSeq
  and   coalesce(S.InvoiceHeaderGrandTotal,0.00) <> coalesce(D.InvoiceDetailGrandTotal,0.00)
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select II.InvoiceIDSeq 
  from   Invoices.dbo.Invoice I with (nolock)
  inner join
         INVOICES.dbo.InvoiceItem    II  with (nolock)
  on     I.InvoiceIDSeq = II.InvoiceIDSeq
  and    I.Printflag    = 0
  and    II.OrderitemTransactionIDSeq is null
  where  II.OrderitemTransactionIDSeq is null
  and    not exists (select top 1 1
                    from   ORDERS.dbo.Orderitem OI with (nolock)
                    where  II.Orderidseq     = OI.Orderidseq
                    and    II.Ordergroupidseq= OI.Ordergroupidseq
                    and    II.OrderitemIDSeq = OI.IDSeq                    
                    )
  group by II.InvoiceIDSeq;
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select II.InvoiceIDSeq 
  from   Invoices.dbo.Invoice I with (nolock)
  inner join
         INVOICES.dbo.InvoiceItem    II  with (nolock)
  on     I.InvoiceIDSeq = II.InvoiceIDSeq
  and    I.Printflag    = 0
  and    II.OrderitemTransactionIDSeq is not null
  where  II.OrderitemTransactionIDSeq is not null
  and    not exists (select top 1 1
                     from   ORDERS.dbo.OrderitemTransaction OIT with (nolock)
                     where  II.Orderidseq     = OIT.Orderidseq
                     and    II.Ordergroupidseq= OIT.Ordergroupidseq
                     and    II.OrderitemIDSeq = OIT.OrderitemIDSeq
                     and    II.OrderitemTransactionIDSeq = OIT.IDSeq                    
                     )
  group by II.InvoiceIDSeq;
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select I.InvoiceIDSeq from Invoices.dbo.Invoice I with (nolock)
  where not exists (select top 1 1 
                    from Invoices.dbo.InvoiceGroup IG with (nolock)
                    where I.Invoiceidseq = IG.Invoiceidseq
                   )
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select I.InvoiceIDSeq from Invoices.dbo.Invoice I with (nolock)
  where not exists (select top 1 1 
                    from Invoices.dbo.InvoiceItem II with (nolock)
                    where I.Invoiceidseq = II.Invoiceidseq
                   )
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select IG.InvoiceIDSeq from Invoices.dbo.InvoiceGroup IG with (nolock)
  where not exists (select top 1 1 
                    from Invoices.dbo.Invoice I with (nolock)
                    where IG.Invoiceidseq = I.Invoiceidseq
                   )
  group by IG.InvoiceIDSeq
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select II.InvoiceIDSeq from Invoices.dbo.InvoiceItem II with (nolock)
  where not exists (select top 1 1 
                    from Invoices.dbo.Invoice I with (nolock)
                    where II.Invoiceidseq = I.Invoiceidseq
                    )
  group by II.InvoiceIDSeq
  -----------------------------  
  Insert into #LT_SyncInvoices(InvoiceID)
  select II.InvoiceIDSeq  from Invoices.dbo.InvoiceItem II with (nolock)
  where not exists (select top 1 1 
                    from Invoices.dbo.InvoiceGroup IG with (nolock)
                    where II.Invoiceidseq = IG.Invoiceidseq
                   )
  group by II.InvoiceIDSeq
  ---------------------------------------------------------
  select @imin=1,@imax=count(InvoiceID) 
  from #LT_SyncInvoices with (nolock)
  ---------------------------------------------------------
  While @imin <= @imax
  begin 
    select @LVC_InvoiceID = InvoiceID
    from   #LT_SyncInvoices with (nolock)
    where  SEQ = @imin
    BEGIN TRY
      EXEC INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID= @LVC_InvoiceID
    END TRY
    BEGIN CATCH
    END   CATCH
    select @imin = @imin+1
  end
  ---------------------------------------------------------
  --Final Cleanup
  if (object_id('tempdb.dbo.#LT_SyncInvoices') is not null) 
  begin
    drop table #LT_SyncInvoices;
  end
END  
GO
