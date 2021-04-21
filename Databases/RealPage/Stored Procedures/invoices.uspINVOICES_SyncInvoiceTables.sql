SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID='I0905016642'
exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID='I0905016650'
exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID='I0905016658'
*/
CREATE PROCEDURE [invoices].[uspINVOICES_SyncInvoiceTables] (@IPVC_InvoiceID       varchar(50),
                                                @IPI_EOMProcessorFlag int = 0
                                               )
AS
BEGIN   
  set nocount on;
  IF (@IPI_EOMProcessorFlag = 1)
  BEGIN
    ---------------------------------------------
    --Update Invoice - THIS IS SPECIFICALLY CALLED BY EOMPROCESSOR
    ---------------------------------------------
    BEGIN TRY
      Update I
      set    I.ILFChargeAmount        =S.ILFChargeAmount,
             I.AccessChargeAmount     =S.AccessChargeAmount,
             I.TransactionChargeAmount=S.TransactionChargeAmount,
             I.TaxAmount              =S.TaxAmount,         
             I.CreditAmount           =S.CreditAmount,
             I.ShippingAndHandlingAmount = S.ShippingAndHandlingAmount         
      from   INVOICES.dbo.Invoice I with (nolock)
      inner join
             (select X.InvoiceIDSeq,
                     sum((case when (X.Measurecode    = 'TRAN') then X.NetChargeAmount else 0 end))                           as TransactionChargeAmount,
                     sum((case when (X.ChargeTypecode = 'ILF' and X.Measurecode <>'TRAN') then X.NetChargeAmount else 0 end)) as ILFChargeAmount,
                     sum((case when (X.ChargeTypecode = 'ACS' and X.Measurecode <>'TRAN') then X.NetChargeAmount else 0 end)) as AccessChargeAmount,
                     sum(X.TaxAmount)    as  TaxAmount,
                     sum(X.CreditAmount) as  CreditAmount,
                     sum(X.ShippingAndHandlingAmount) as ShippingAndHandlingAmount
              from INVOICES.dbo.InvoiceItem X with (nolock) 
              where X.InvoiceIDSeq = @IPVC_InvoiceID
              group by InvoiceIDSeq
             ) S
      on     I.InvoiceIDSeq  = S.InvoiceIDSeq
      and    I.InvoiceIDSeq  = @IPVC_InvoiceID
      and    S.InvoiceIDSeq  = @IPVC_InvoiceID
      where  I.InvoiceIDSeq  = @IPVC_InvoiceID;
    END TRY
    BEGIN CATCH
    END   CATCH
    RETURN
  END
  ---------------------------------------------
  ---Update For BillToAddress Variation If any
  ---------------------------------------------
  BEGIN TRY    
    Update I 
    set    I.BillToAddressLine1=A.AddressLine1,
           I.BillToAddressLine2=A.AddressLine2,
           I.BillToCity        =A.City,
           I.BillToState       =A.State,
           I.BillToZip         =A.Zip,
           I.BillToCountry     =A.Country,
           I.BillToEmailAddress=A.Email
    from   Invoices.dbo.Invoice  I with (nolock)
    inner join
           Customers.dbo.Address A with (nolock)
    on     I.CompanyIdSeq = A.CompanyIdSeq
    and    I.InvoiceIDSeq = @IPVC_InvoiceID
    and    I.Printflag = 0
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
   where  I.InvoiceIDSeq = @IPVC_InvoiceID
   and    I.Printflag    = 0
   and    I.CompanyIdSeq = A.CompanyIdSeq
   and    I.BillToAddressTypeCode  = A.Addresstypecode
  END TRY
  BEGIN CATCH
  END   CATCH
  ---------------------------------------------
  ---Update For ShipToAddress Variation If any
  ---------------------------------------------
  BEGIN TRY
    Update I
    set    I.ShipToAddressLine1=A.AddressLine1,
           I.ShipToAddressLine2=A.AddressLine2,
           I.ShipToCity        =A.City,       
           I.ShipToState       =A.State,
           I.ShipToZip         =A.Zip,
           I.ShipToCountry     =A.Country
    from   Invoices.dbo.Invoice  I with (nolock)
    inner join
           Customers.dbo.Address A with (nolock)
    on     I.CompanyIdSeq = A.CompanyIdSeq
    and    I.InvoiceIDSeq = @IPVC_InvoiceID
    and    I.Printflag = 0
    and   (
           (A.Addresstypecode = 'PST'              and 
            I.CompanyIdSeq    = A.CompanyIdSeq     and
            I.PropertyIDSeq   = A.PropertyIDSeq    and 
            I.PropertyIDSeq is not null            and
            A.PropertyIDSeq is not null                 

           )
            OR
           (A.Addresstypecode = 'CST'              and 
            I.CompanyIdSeq    = A.CompanyIdSeq        
           ) 
          )
    and (
         I.ShipToAddressLine1 <> A.AddressLine1 
          OR
         coalesce(ltrim(rtrim(I.ShipToAddressLine2)),'') <> coalesce(ltrim(rtrim(A.AddressLine2)),'')
          OR
         I.ShipToCity <> A.City
          OR
         I.ShipToState <> A.State
          OR
         I.ShipToZip <> A.Zip
          OR
         coalesce(ltrim(rtrim(I.ShipToCountry)),'') <> coalesce(ltrim(rtrim(A.Country)),'')
       )
   where  I.InvoiceIDSeq = @IPVC_InvoiceID
   and    I.Printflag    = 0
   and    I.CompanyIdSeq = A.CompanyIdSeq
   and    ((I.PropertyIDSeq is not null and A.Addresstypecode = 'PST')
              or
           (I.PropertyIDSeq is null and A.Addresstypecode = 'CST')
          )
  END TRY
  BEGIN CATCH
  END   CATCH  
  ---------------------------------------------
  --Delete extra Billing Record for ordersynchstartmonth <> 0
  -- and BillingPeriodFromDate greater than Orderitems Enddate
  -- and Non Tran For recurring access
  ---------------------------------------------
  BEGIN TRY
    Delete IIN
    from   Invoices.dbo.Invoice     I  with (nolock)
    inner Join
           Customers.dbo.Company C with (nolock)
    on     I.CompanyIDSeq = C.IDSeq
    and    C.ordersynchstartmonth <> 0
    and    I.InvoiceIDSeq  = @IPVC_InvoiceID
    and    I.Printflag     = 0
    inner Join
           Invoices.dbo.InvoiceItem II with (nolock)
    on     II.InvoiceIDSeq = I.InvoiceIDSeq
    and    I.InvoiceIDSeq  = @IPVC_InvoiceID
    and    II.InvoiceIDSeq = @IPVC_InvoiceID
    and    I.Printflag     = 0
    inner join
           Invoices.dbo.InvoiceItemNote IIN with (nolock)
    on     II.InvoiceIDSeq  = IIN.InvoiceIDSeq
    and    II.IDSeq         = IIN.InvoiceItemIDSeq
    and    IIN.InvoiceIDSeq = @IPVC_InvoiceID
    inner Join
           Orders.dbo.OrderItem OI With (nolock)
    on     II.OrderIDSeq      = OI.OrderIDSeq
    and    II.OrderGroupIDSeq = OI.OrderGroupIDSeq
    and    II.OrderItemIDSeq  = OI.IDSeq
    and    II.ProductCode     = OI.ProductCode
    and    II.PriceVersion    = OI.PriceVersion
    and    II.ChargetypeCode  = OI.Chargetypecode
    and    II.Measurecode     = OI.MeasureCode
    and    II.FrequencyCode   = OI.FrequencyCode
    and    II.chargetypecode  = 'ACS'
    and    OI.chargetypecode  = 'ACS'
    and    II.measurecode     <>'TRAN'
    and    OI.measurecode     <>'TRAN'
    and    OI.ActivationEndDate < II.BillingPeriodFromDate      
    where  I.InvoiceIDSeq     = @IPVC_InvoiceID
    and    I.Printflag        = 0
    and    C.ordersynchstartmonth <> 0
    and    II.chargetypecode  = 'ACS'
    and    OI.chargetypecode  = 'ACS'
    and    II.measurecode     <>'TRAN'
    and    OI.measurecode     <>'TRAN'
    and    OI.ActivationEndDate < II.BillingPeriodFromDate 


    Delete II
    from   Invoices.dbo.Invoice     I  with (nolock)
    inner Join
           Customers.dbo.Company C with (nolock)
    on     I.CompanyIDSeq = C.IDSeq
    and    C.ordersynchstartmonth <> 0
    and    I.InvoiceIDSeq  = @IPVC_InvoiceID
    and    I.Printflag     = 0
    inner Join
           Invoices.dbo.InvoiceItem II with (nolock)
    on     II.InvoiceIDSeq = I.InvoiceIDSeq
    and    I.InvoiceIDSeq  = @IPVC_InvoiceID
    and    II.InvoiceIDSeq = @IPVC_InvoiceID
    and    I.Printflag     = 0  
    inner Join
           Orders.dbo.OrderItem OI With (nolock)
    on     II.OrderIDSeq      = OI.OrderIDSeq
    and    II.OrderGroupIDSeq = OI.OrderGroupIDSeq
    and    II.OrderItemIDSeq  = OI.IDSeq
    and    II.ProductCode     = OI.ProductCode
    and    II.PriceVersion    = OI.PriceVersion
    and    II.ChargetypeCode  = OI.Chargetypecode
    and    II.Measurecode     = OI.MeasureCode
    and    II.FrequencyCode   = OI.FrequencyCode
    and    II.chargetypecode  = 'ACS'
    and    OI.chargetypecode  = 'ACS'
    and    II.measurecode     <>'TRAN'
    and    OI.measurecode     <>'TRAN'
    and    OI.ActivationEndDate < II.BillingPeriodFromDate      
    where  I.InvoiceIDSeq     = @IPVC_InvoiceID
    and    I.Printflag        = 0
    and    C.ordersynchstartmonth <> 0
    and    II.chargetypecode  = 'ACS'
    and    OI.chargetypecode  = 'ACS'
    and    II.measurecode     <>'TRAN'
    and    OI.measurecode     <>'TRAN'
    and    OI.ActivationEndDate < II.BillingPeriodFromDate
  END TRY
  BEGIN CATCH
  END CATCH
  ---------------------------------------------
  --Delete Orphan CreditMemoItems
  ---------------------------------------------
  BEGIN TRY
    Delete CMN
    from  INVOICES.dbo.CreditMemoItem CMI with (nolock)
    inner join
          INVOICES.dbo.CreditMemoItemNote CMN with (nolock)
    on    CMI.CreditMemoIDSeq = CMN.CreditMemoIDSeq
    and   CMI.IDSeq           = CMN.CreditMemoItemIDSeq
    and   CMI.Invoiceidseq    = @IPVC_InvoiceID
    inner join
          INVOICES.dbo.InvoiceItem    II  with (nolock)
    on    CMI.Invoiceidseq     = II.Invoiceidseq
    and   CMI.InvoiceItemIDSeq = II.IDSeq
    and   CMI.Invoiceidseq = @IPVC_InvoiceID
    and   II.Invoiceidseq  = @IPVC_InvoiceID
    and   II.OrderitemTransactionIDSeq is null
    and   not exists (select top 1 1
                      from   ORDERS.dbo.Orderitem OI with (nolock)
                      where  II.Orderidseq     = OI.Orderidseq
                      and    II.Ordergroupidseq= OI.Ordergroupidseq
                      and    II.OrderitemIDSeq = OI.IDSeq                    
                      )
    where CMI.Invoiceidseq = @IPVC_InvoiceID;

    Delete CMI
    from  INVOICES.dbo.CreditMemoItem CMI with (nolock)
    inner join
          INVOICES.dbo.InvoiceItem    II  with (nolock)
    on    CMI.Invoiceidseq     = II.Invoiceidseq
    and   CMI.InvoiceItemIDSeq = II.IDSeq
    and   CMI.Invoiceidseq = @IPVC_InvoiceID
    and   II.Invoiceidseq  = @IPVC_InvoiceID
    and   II.OrderitemTransactionIDSeq is null
    and   not exists (select top 1 1
                      from   ORDERS.dbo.Orderitem OI with (nolock)
                      where  II.Orderidseq     = OI.Orderidseq
                      and    II.Ordergroupidseq= OI.Ordergroupidseq
                      and    II.OrderitemIDSeq = OI.IDSeq                    
                      )
    where CMI.Invoiceidseq = @IPVC_InvoiceID;
  END TRY
  BEGIN CATCH
  END   CATCH

  BEGIN TRY
    Delete CMN
    from  INVOICES.dbo.CreditMemoItem CMI with (nolock)
    inner join
          INVOICES.dbo.CreditMemoItemNote CMN with (nolock)
    on    CMI.CreditMemoIDSeq = CMN.CreditMemoIDSeq
    and   CMI.IDSeq           = CMN.CreditMemoItemIDSeq
    and   CMI.Invoiceidseq    = @IPVC_InvoiceID
    inner join
          INVOICES.dbo.InvoiceItem    II  with (nolock)
    on    CMI.Invoiceidseq     = II.Invoiceidseq
    and   CMI.InvoiceItemIDSeq = II.IDSeq
    and   CMI.Invoiceidseq = @IPVC_InvoiceID
    and   II.Invoiceidseq  = @IPVC_InvoiceID
    and   II.OrderitemTransactionIDSeq is not null
    and   not exists (select top 1 1
                      from   ORDERS.dbo.OrderitemTransaction OIT with (nolock)
                      where  II.Orderidseq     = OIT.Orderidseq
                      and    II.Ordergroupidseq= OIT.Ordergroupidseq
                      and    II.OrderitemIDSeq            = OIT.OrderitemIDSeq
                      and    II.OrderitemTransactionIDSeq = OIT.IDSeq                    
                     )
    where CMI.Invoiceidseq = @IPVC_InvoiceID;

    Delete CMI
    from  INVOICES.dbo.CreditMemoItem CMI with (nolock)
    inner join
          INVOICES.dbo.InvoiceItem    II  with (nolock)
    on    CMI.Invoiceidseq = II.Invoiceidseq
    and   CMI.InvoiceItemIDSeq = II.IDSeq
    and   CMI.Invoiceidseq = @IPVC_InvoiceID
    and   II.Invoiceidseq  = @IPVC_InvoiceID
    and   II.OrderitemTransactionIDSeq is not null
    and   not exists (select top 1 1
                      from   ORDERS.dbo.OrderitemTransaction OIT with (nolock)
                      where  II.Orderidseq     = OIT.Orderidseq
                      and    II.Ordergroupidseq= OIT.Ordergroupidseq
                      and    II.OrderitemIDSeq            = OIT.OrderitemIDSeq
                      and    II.OrderitemTransactionIDSeq = OIT.IDSeq                    
                     )
    where CMI.Invoiceidseq = @IPVC_InvoiceID;
  END TRY
  BEGIN CATCH
  END   CATCH
  --------------------------------
  --Delete Orphan InvoiceItems
  --------------------------------
  BEGIN TRY
    Delete IIN
    from   INVOICES.dbo.InvoiceItemNote IIN with (nolock)
    where  IIN.Invoiceidseq  = @IPVC_InvoiceID
    and   not exists (select top 1 1
                      from   ORDERS.dbo.Orderitem OI with (nolock)
                      where  IIN.Orderidseq     = OI.Orderidseq
                      and    IIN.OrderItemIDSeq = OI.IDSeq                      
                      );


    Delete II
    from  INVOICES.dbo.InvoiceItem    II  with (nolock)
    where II.Invoiceidseq  = @IPVC_InvoiceID
    and   II.OrderitemTransactionIDSeq is null
    and   not exists (select top 1 1
                      from   ORDERS.dbo.Orderitem OI with (nolock)
                      where  II.Orderidseq     = OI.Orderidseq
                      and    II.Ordergroupidseq= OI.Ordergroupidseq
                      and    II.OrderitemIDSeq = OI.IDSeq                    
                      );
    

    Delete II
    from  INVOICES.dbo.InvoiceItem    II  with (nolock)
    where II.Invoiceidseq  = @IPVC_InvoiceID
    and   II.OrderitemTransactionIDSeq is not null
    and   not exists (select top 1 1
                      from   ORDERS.dbo.OrderitemTransaction OIT with (nolock)
                      where  II.Orderidseq     = OIT.Orderidseq
                      and    II.Ordergroupidseq= OIT.Ordergroupidseq
                      and    II.OrderitemIDSeq = OIT.OrderitemIDSeq
                      and    II.OrderitemTransactionIDSeq = OIT.IDSeq                    
                      );   

  END TRY
  BEGIN CATCH
  END   CATCH
  --------------------------------
  --Delete Orphan InvoiceGroups
  --------------------------------
  BEGIN TRY
    Delete IG
    from  INVOICES.dbo.InvoiceGroup    IG  with (nolock)
    where IG.Invoiceidseq  = @IPVC_InvoiceID  
    and   not exists (select top 1 1
                      from   Invoices.dbo.Invoiceitem II with (nolock)
                      where  II.Invoiceidseq = @IPVC_InvoiceID
                      and    IG.Invoiceidseq = II.Invoiceidseq
                      and    IG.IDSeq        = II.InvoiceGroupIDSeq                  
                     );  
  END TRY
  BEGIN CATCH
  END   CATCH
  ---------------------------------------------
  --Update InvoiceItem
  ---------------------------------------------
  BEGIN TRY
    UPDATE II
    set    II.DiscountAmount = II.DiscountAmount + (II.ExtChargeAmount - II.DiscountAmount - II.NetChargeAmount)
    from   INVOICES.dbo.InvoiceItem II with (nolock)
    where  II.Invoiceidseq   = @IPVC_InvoiceID
    and    (II.ExtChargeAmount - II.DiscountAmount - II.NetChargeAmount) <> 0
  END TRY
  BEGIN CATCH
  END   CATCH
  -----------
  BEGIN TRY
    ;with CMI_CTE(InvoiceIDSeq,InvoiceItemIDSeq,NetCreditAmount)
     as (select CMI.InvoiceIDSeq                          as InvoiceIDSeq,
                CMI.InvoiceItemIDSeq                      as InvoiceItemIDSeq,
                coalesce(sum(CMI.NetCreditAmount                 +                             
                             CMI.TaxAmount
                             )
                        ,0.00)                            as NetCreditAmount
            from   INVOICES.dbo.CreditMemoItem CMI with (nolock)          
            inner join 
                   INVOICES.dbo.CreditMemo CM with (nolock)
            on     CM.InvoiceIDSeq     = CMI.InvoiceIDSeq
            and    CM.CreditMemoIDSeq  = CMI.CreditMemoIDSeq          
            and    CM.CreditStatusCode = 'APPR'
            and    CMI.InvoiceIDSeq = @IPVC_InvoiceID
            and    CM.InvoiceIDSeq  = @IPVC_InvoiceID
            where  CMI.InvoiceIDSeq = @IPVC_InvoiceID
            and    CM.InvoiceIDSeq  = @IPVC_InvoiceID
            and    CM.CreditStatusCode = 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceItemIDSeq
           )
    Update IIO
    set    IIO.CreditAmount = coalesce(S.NetCreditAmount,0.00)
    From   INVOICES.dbo.InvoiceItem IIO with (nolock)
    left outer Join
           CMI_CTE S with (nolock)
    on    IIO.InvoiceIDSeq = S.InvoiceIDSeq
    and   IIO.IDSeq        = S.InvoiceItemIDSeq
    and   IIO.InvoiceIDSeq = @IPVC_InvoiceID
    and   S.InvoiceIDSeq   = @IPVC_InvoiceID
    where IIO.InvoiceIDSeq = @IPVC_InvoiceID;
  END TRY
  BEGIN CATCH
  END   CATCH
  ---------------------------------------------
  --Update CreditMemo
  ---------------------------------------------
  BEGIN TRY
    Update CM
    set    CM.ILFCreditAmount         = S.ILFCreditAmount,
           CM.AccessCreditAmount      = S.AccessCreditAmount,
           CM.TransactionCreditAmount = S.TransactionCreditAmount,
           CM.ShippingAndHandlingCreditAmount = S.ShippingAndHandlingCreditAmount,
           CM.TaxAmount               = S.TaxAmount,
           CM.TotalNetCreditAmount    = (S.ILFCreditAmount+S.AccessCreditAmount+S.TransactionCreditAmount)
    from   INVOICES.dbo.CreditMemo CM with (nolock)
    inner join 
           (select CMI.InvoiceIDSeq                                                                                       as InvoiceIDSeq,
                   CMI.CreditMemoIDSeq                                                                                    as CreditMemoIDSeq,
            sum((case when (X.Measurecode    = 'TRAN') then (CMI.NetCreditAmount) else 0 end))                            as TransactionCreditAmount,
            sum((case when (X.ChargeTypecode = 'ILF' and X.Measurecode <>'TRAN')  then (CMI.NetCreditAmount) else 0 end)) as ILFCreditAmount,
            sum((case when (X.ChargeTypecode = 'ACS' and X.Measurecode <>'TRAN')  then (CMI.NetCreditAmount) else 0 end)) as AccessCreditAmount,          
            sum(CMI.ShippingAndHandlingCreditAmount)                                                                      as ShippingAndHandlingCreditAmount,
            sum(CMI.TaxAmount)            as TaxAmount          
            from   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            inner join
                   INVOICES.dbo.InvoiceItem    X with (nolock)
            on     X.InvoiceIDSeq   = CMI.InvoiceIDSeq
            and    X.IDSeq          = CMI.InvoiceItemIDSeq 
            and    CMI.InvoiceIDSeq = @IPVC_InvoiceID
            where  CMI.InvoiceIDSeq = @IPVC_InvoiceID
            group by CMI.InvoiceIDSeq,CMI.CreditMemoIDSeq
           ) S
    on     CM.InvoiceIDSeq  = S.InvoiceIDSeq
    and    CM.InvoiceIDSeq  = @IPVC_InvoiceID
    and    S.InvoiceIDSeq   = @IPVC_InvoiceID
    and    CM.CreditMemoIDSeq = S.CreditMemoIDSeq
    where  CM.Invoiceidseq = @IPVC_InvoiceID;  
  END TRY
  BEGIN CATCH
  END   CATCH
  ---------------------------------------------
  --Update InvoiceGroup
  ---------------------------------------------
  BEGIN TRY
    Update IG
    set    IG.ILFChargeAmount        =S.ILFChargeAmount,
           IG.AccessChargeAmount     =S.AccessChargeAmount,
           IG.TransactionChargeAmount=S.TransactionChargeAmount,
           IG.CreditAmount           =S.CreditAmount
    from   INVOICES.dbo.InvoiceGroup IG with (nolock)
    inner join
           (select X.InvoiceIDSeq,
                   X.InvoiceGroupIDSeq,
                   sum((case when (X.Measurecode    = 'TRAN') then X.NetChargeAmount else 0 end))                           as TransactionChargeAmount,
                   sum((case when (X.ChargeTypecode = 'ILF' and X.Measurecode <>'TRAN') then X.NetChargeAmount else 0 end)) as ILFChargeAmount,
                   sum((case when (X.ChargeTypecode = 'ACS' and X.Measurecode <>'TRAN') then X.NetChargeAmount else 0 end)) as AccessChargeAmount,
                   sum(X.CreditAmount)                                                                                      as CreditAmount
            from INVOICES.dbo.InvoiceItem X with (nolock) 
            where X.InvoiceIDSeq = @IPVC_InvoiceID
            group by InvoiceIDSeq,InvoiceGroupIDSeq
           ) S
    on     IG.InvoiceIDSeq  = S.InvoiceIDSeq
    and    IG.InvoiceIDSeq  = @IPVC_InvoiceID
    and    S.InvoiceIDSeq   = @IPVC_InvoiceID
    and    IG.IDSeq         = S.InvoiceGroupIDSeq
    where  IG.Invoiceidseq  = @IPVC_InvoiceID;
  END TRY
  BEGIN CATCH
  END   CATCH
  ---------------------------------------------
  --Update Invoice
  ---------------------------------------------
  BEGIN TRY
    Update I
    set    I.ILFChargeAmount        =S.ILFChargeAmount,
           I.AccessChargeAmount     =S.AccessChargeAmount,
           I.TransactionChargeAmount=S.TransactionChargeAmount,
           I.TaxAmount              =S.TaxAmount,         
           I.CreditAmount           =S.CreditAmount,
           I.ShippingAndHandlingAmount = S.ShippingAndHandlingAmount         
    from   INVOICES.dbo.Invoice I with (nolock)
    inner join
           (select X.InvoiceIDSeq,
                   sum((case when (X.Measurecode    = 'TRAN') then X.NetChargeAmount else 0 end))                           as TransactionChargeAmount,
                   sum((case when (X.ChargeTypecode = 'ILF' and X.Measurecode <>'TRAN') then X.NetChargeAmount else 0 end)) as ILFChargeAmount,
                   sum((case when (X.ChargeTypecode = 'ACS' and X.Measurecode <>'TRAN') then X.NetChargeAmount else 0 end)) as AccessChargeAmount,
                   sum(X.TaxAmount)                                                                                         as TaxAmount,
                   sum(X.CreditAmount)                                                                                      as CreditAmount,
                   sum(X.ShippingAndHandlingAmount)                                                                         as ShippingAndHandlingAmount
            from INVOICES.dbo.InvoiceItem X with (nolock) 
            where X.InvoiceIDSeq = @IPVC_InvoiceID
            group by InvoiceIDSeq
           ) S
    on     I.InvoiceIDSeq  = S.InvoiceIDSeq
    and    I.InvoiceIDSeq  = @IPVC_InvoiceID
    and    S.InvoiceIDSeq  = @IPVC_InvoiceID
    where  I.Invoiceidseq  = @IPVC_InvoiceID;
  END TRY
  BEGIN CATCH
  END   CATCH
  --------------------------------------------------------------------
  ---Final Step : If atleast 1 InvoiceItem is not found, Then delete the invoice 
  -- as it is an orphan Invoice
  BEGIN TRY
    If Not exists (select Top 1 1 from Invoices.dbo.Invoiceitem II with (nolock)
                   where II.Invoiceidseq = @IPVC_InvoiceID
                  )
    begin
      delete D
      from   INVOICES.dbo.CreditMemoItemNote D with (nolock)  
      where  exists (select top 1 1 
                     from   INVOICES.dbo.CreditMemo S with (nolock)
                     where  D.CreditMemoIDSeq  = S.CreditMemoIDSeq
                     and    S.InvoiceIDSeq     = @IPVC_InvoiceID
                    );
      delete from INVOICES.dbo.CreditMemoItem  where InvoiceIDSeq = @IPVC_InvoiceID; 
      delete from INVOICES.dbo.InvoiceItemNote where InvoiceIDSeq = @IPVC_InvoiceID; 
      delete from INVOICES.dbo.InvoiceItem     where InvoiceIDSeq = @IPVC_InvoiceID;
      delete from INVOICES.dbo.InvoiceGroup    where InvoiceIDSeq = @IPVC_InvoiceID;
      delete from INVOICES.dbo.CreditMemo      where InvoiceIDSeq = @IPVC_InvoiceID; 
      delete from INVOICES.dbo.InvoicePayment  where InvoiceIDSeq = @IPVC_InvoiceID;
      delete from INVOICES.dbo.Invoice         where InvoiceIDSeq = @IPVC_InvoiceID;  
    end
  END TRY
  BEGIN CATCH
  END   CATCH
  ----------------------------------------------------------------------  
END
GO
