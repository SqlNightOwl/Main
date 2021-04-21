SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-------------------------------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES      
-- Procedure Name  : uspQUOTES_Rep_GetAccountInfoForProformaInvoice      
-- Description     : This procedure returns one record with Account Info and Billing and Shipping Address 
--                   to show on Header and Paystub on Proforma Invoice
-- Input Parameters: @IPVC_QuoteID,@IPBI_GroupID,@IPVC_CompanyID,@IPVC_OMSID  passed from 
--                   call of uspQUOTES_GetGroupsForProformaInvoice.SQL
--            
-- Code Example    : 
/*
 Exec QUOTES.dbo.uspQUOTES_Rep_GetAccountInfoForProformaInvoice 
             @IPVC_QuoteID='Q0901000443',
             @IPBI_GroupID=533,
             @IPVC_CompanyID='C0901001233',
             @IPVC_OMSID='P0901065105',
             @IPVC_ProformaInvoiceDate = '07/01/2010'

 Exec QUOTES.dbo.uspQUOTES_Rep_GetAccountInfoForProformaInvoice  
             @IPVC_QuoteID='Q1008000880',
             @IPBI_GroupID=24828,
             @IPVC_CompanyID='C0901007688',
             @IPVC_OMSID='C0901007688',
             @IPVC_ProformaInvoiceDate = '08/22/2010'
*/
--       
--       
-- Revision History:      
-- Author          : SRS      
-- 08/26/2010      : Stored Procedure Created. Defect 8015
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [reports].[uspQUOTES_Rep_GetAccountInfoForProformaInvoice] (@IPVC_QuoteID             varchar(50), --->QuoteID    from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                         @IPBI_GroupID             bigint,      --->GroupID    from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                         @IPVC_CompanyID           varchar(50), --->CompanyID  from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                         @IPVC_OMSID               varchar(50), --->OMSID      from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                         @IPVC_ProformaInvoiceDate varchar(50)  ---> UI already knows the value for this date as MM/DD/YYYY format.
                                                                                                                  --- If Quote is being approved,UI knows the QuoteApprovalDate that user keys in.
                                                                                                                  --- If Quote is in Submitted State, UI knows the Quote Submitted Date.
                                                                                                                  --- If Quote is in Not Submitted State, UI will pass current system date as MM/DD/YYYY. 
                                                                        )
AS
BEGIN
  set nocount on;
  ----------------------------------------------------------------------------------------------------
  declare @LN_TotalDue  numeric(30,2)
  select  @IPVC_ProformaInvoiceDate = convert(varchar(50),convert(datetime,@IPVC_ProformaInvoiceDate),101)
  ----------------------------------------------------------------------------------------------------
  create table #LT_TempPricingData   (SEQ                      int not null identity(1,1) primary Key,                                 
                                      quoteid                  varchar(50),
                                      groupid                  bigint, 
                                      quoteitemid              bigint,
                                      companyid                varchar(50),
                                      omsid                    varchar(50),
                                      productcode              varchar(100),
                                      productname              varchar(255), 
                                      custombundlename         varchar(255),
                                      custombundlenameenabledflag int,                                                                      
                                      productcategorycode      varchar(50),
                                      familycode               varchar(20)   not null,
                                      chargetypecode           varchar(50),
                                      reportingtypecode        varchar(50),                                      
                                      measurecode              varchar(20)   not null,
                                      measurename              varchar(100),
                                      DisplayTransactionalProductPriceOnInvoiceFlag int not null default(1),                                
                                      frequencycode            varchar(20)   not null,
                                      frequencyname            varchar(100),
                                      chargeamount             money         not null default 0,
                                      discountpercent          float         not null default 0.00,
                                      discountamount           numeric(30,2) not null default 0,
                                      totaldiscountpercent     float         not null default 0.00,
                                      totaldiscountamount      numeric(30,2) not null default 0,
                                      extchargeamount          numeric(30,2) not null default 0,
                                      extSOCchargeamount       numeric(30,2) not null default 0,
                                      unitofmeasure            numeric(30,5) not null default 0.00,                    
                                      multiplier               decimal(18,6) not null default 0.00,
                                      extyear1chargeamount     numeric(30,2) not null default 0,                                
                                      netchargeamount          numeric(30,3) not null default 0,
                                      netextchargeamount       numeric(30,2) not null default 0,                                                                                                                   
                                      netextyear1chargeamount  numeric(30,2) not null default 0,
                                      pricingtiers             int           not null default 1,
                                      PricingLineItemNotes     varchar(8000) null
                                      )
  ----------------------------------------------------------------------------------------------- 
  --Step 1 : Get Raw Pricing Data for @IPVC_QuoteID,@IPBI_GroupID,@IPVC_OMSID
  -----------------------------------------------------------------------------------------------
  insert into #LT_TempPricingData(quoteid,groupid,quoteitemid,companyid,omsid,
                                 productcode,productname,custombundlename,custombundlenameenabledflag,
                                 productcategorycode,
                                 familycode,chargetypecode,reportingtypecode,
                                 measurecode,measurename,frequencycode,frequencyname,DisplayTransactionalProductPriceOnInvoiceFlag,
                                 chargeamount,
                                 discountpercent,discountamount,totaldiscountpercent,totaldiscountamount,
                                 extchargeamount,extSOCchargeamount,unitofmeasure,multiplier,extyear1chargeamount,                              
                                 netchargeamount,netextchargeamount,netextyear1chargeamount,
                                 pricingtiers,PricingLineItemNotes)
  exec QUOTES.dbo.uspQUOTES_PriceEngine @IPVC_QuoteID=@IPVC_QuoteID,@IPI_GroupID=@IPBI_GroupID,
                                        @IPVC_PropertyAmountAnnualized='NO',@IPI_ProformaInvoice=1
  ----> Remove other records that does not pertain to @IPVC_OMSID
  delete from #LT_TempPricingData where omsid <> @IPVC_OMSID

  select @LN_TotalDue = convert(numeric(30,2),sum(S.netextchargeamount))
  from   #LT_TempPricingData S with (nolock)
  where  S.quoteid = @IPVC_QuoteID
  and    S.groupid = @IPBI_GroupID
  and    S.omsid   = @IPVC_OMSID
  ----> Clean up Temp table
  if (object_id('tempdb.dbo.#LT_TempPricingData') is not null) 
  begin
    drop table #LT_TempPricingData
  end
  ----------------------------------------------------------------------------------------------- 
  --Final Select to Report 
  --Return One Record for Header, Pay Stub information for Account in Question for @IPVC_OMSID
  ----------------------------------------------------------------------------------------------- 
  if (@IPVC_CompanyID <> @IPVC_OMSID) ---> This is for Property Account
  begin
    select  Top 1
            @IPVC_QuoteID                                            as InvoiceNo,
            coalesce(Act.IDSeq,@IPVC_OMSID)                          as AccountNo,
            coalesce(Act.EpicorCustomerCode,'N/A')                   as RefNo,
            Upper(Prp.Name)                                          as AccountName,
            @IPVC_ProformaInvoiceDate                                as InvoiceDate,
            @LN_TotalDue                                             as TotalDue,
            'Upon Receipt'                                           as Due,
            ---------------------------------
            (Case when BillAddr.SameAsPMCAddressFlag = 1
                    then Upper(Com.Name) 
                  else   Upper(Prp.Name) 
             end)                                                    as BillToAccountName, ---> This should be used for Billing Address section
            Upper(BillAddr.AddressLine1)                             as BillingAddress1,
            Upper(coalesce(BillAddr.AddressLine2,''))                as BillingAddress2,            
            Upper(BillAddr.City)                                     as BillingCity,  
            (Upper(BillAddr.State) + ' ' + Upper(BillAddr.Zip))      as BillingStateZip,
            Upper(BillAddr.Country)                                  as BillingCountry,
            ---------------------------------
            (Case when ShipAddr.SameAsPMCAddressFlag = 1
                    then Upper(Com.Name) 
                  else   Upper(Prp.Name) 
             end)                                                    as ShipToAccountName, ---> This should be used for Shipping Address section
            Upper(ShipAddr.AddressLine1)                             as ShippingAddress1,
            Upper(coalesce(ShipAddr.AddressLine2,''))                as ShippingAddress2,            
            Upper(ShipAddr.City)                                     as ShippingCity,  
            (Upper(ShipAddr.State) + ' ' + ShipAddr.Zip)             as ShippingStateZip,
            Upper(ShipAddr.Country)                                  as ShippingCountry,
            ---------------------------------
            lower(Quotes.dbo.fnGetQuoteBusinessUnitLogo(@IPVC_QuoteID))
                                                                     as BusinessUnit
            ---------------------------------               
    from    Customers.dbo.Property Prp with (nolock)
    inner join
            Customers.dbo.Company  Com with (nolock)
    on      Prp.PMCIDSeq          = Com.IDSeq
    and     Prp.IDSeq             = @IPVC_OMSID
    and     Prp.PMCIDSeq          = @IPVC_CompanyID
    and     Com.IDSeq             = @IPVC_CompanyID
    inner join
            Customers.dbo.Address BillAddr with (nolock)
    on      Com.IDSeq             = BillAddr.CompanyIDSeq
    and     Prp.IDSeq             = BillAddr.PropertyIDSeq
    and     Com.IDSeq             = @IPVC_CompanyID
    and     BillAddr.CompanyIDSeq = @IPVC_CompanyID
    and     Prp.IDSeq             = @IPVC_OMSID
    and     BillAddr.PropertyIDSeq= @IPVC_OMSID 
    and     BillAddr.Addresstypecode = 'PBT'
    and     BillAddr.PropertyIDSeq is not null
    inner join
            Customers.dbo.Address ShipAddr with (nolock)
    on      Com.IDSeq             = ShipAddr.CompanyIDSeq
    and     Prp.IDSeq             = ShipAddr.PropertyIDSeq
    and     Com.IDSeq             = @IPVC_CompanyID
    and     ShipAddr.CompanyIDSeq = @IPVC_CompanyID
    and     Prp.IDSeq             = @IPVC_OMSID
    and     ShipAddr.PropertyIDSeq= @IPVC_OMSID 
    and     ShipAddr.Addresstypecode = 'PST'
    and     ShipAddr.PropertyIDSeq is not null
    left outer join
            Customers.dbo.Account Act with (nolock)
    on      Com.IDSeq           = Act.CompanyIDSeq
    and     Prp.IDSeq           = Act.PropertyIDSeq
    and     Com.IDSeq           = @IPVC_CompanyID
    and     Prp.IDSeq           = @IPVC_OMSID
    and     Act.CompanyIDSeq    = @IPVC_CompanyID
    and     Act.PropertyIDSeq   = @IPVC_OMSID
    and     Act.AccountTypecode = 'APROP'
    and     Act.PropertyIDSeq   is not null
    and     Act.Activeflag      = 1
  end
  else --- This is for Company Account
  begin 
    select  Top 1
            @IPVC_QuoteID                                            as InvoiceNo,
            coalesce(Act.IDSeq,@IPVC_OMSID)                          as AccountNo,
            coalesce(Act.EpicorCustomerCode,'N/A')                   as RefNo,
            Upper(Com.Name)                                          as AccountName,
            @IPVC_ProformaInvoiceDate                                as InvoiceDate,
            @LN_TotalDue                                             as TotalDue,
            'Upon Receipt'                                           as Due,
            ---------------------------------
            Upper(Com.Name)                                          as BillToAccountName, ---> This should be used for Billing Address section
            Upper(BillAddr.AddressLine1)                             as BillingAddress1,
            Upper(coalesce(BillAddr.AddressLine2,''))                as BillingAddress2,            
            Upper(BillAddr.City)                                     as BillingCity,  
            (Upper(BillAddr.State) + ' ' + Upper(BillAddr.Zip))      as BillingStateZip,
            Upper(BillAddr.Country)                                  as BillingCountry,
            ---------------------------------
            Upper(Com.Name)                                          as ShipToAccountName, ---> This should be used for Shipping Address section
            Upper(ShipAddr.AddressLine1)                             as ShippingAddress1,
            Upper(coalesce(ShipAddr.AddressLine2,''))                as ShippingAddress2,            
            Upper(ShipAddr.City)                                     as ShippingCity,  
            (Upper(ShipAddr.State) + ' ' + ShipAddr.Zip)             as ShippingStateZip,
            Upper(ShipAddr.Country)                                  as ShippingCountry,
            ---------------------------------
            lower(Quotes.dbo.fnGetQuoteBusinessUnitLogo(@IPVC_QuoteID))
                                                                     as BusinessUnit
            ---------------------------------               
    from    Customers.dbo.Company Com      with (nolock)
    inner join
            Customers.dbo.Address BillAddr with (nolock)
    on      Com.IDSeq             = BillAddr.CompanyIDSeq
    and     Com.IDSeq             = @IPVC_OMSID
    and     BillAddr.CompanyIDSeq = @IPVC_OMSID
    and     BillAddr.Addresstypecode = 'CBT'
    and     BillAddr.PropertyIDSeq is null
    inner join
            Customers.dbo.Address ShipAddr with (nolock)
    on      Com.IDSeq                = ShipAddr.CompanyIDSeq
    and     Com.IDSeq                = @IPVC_OMSID
    and     ShipAddr.CompanyIDSeq    = @IPVC_OMSID
    and     ShipAddr.Addresstypecode = 'CST'
    and     ShipAddr.PropertyIDSeq is null
    left outer join
            Customers.dbo.Account Act with (nolock)
    on      Com.IDSeq           = Act.CompanyIDSeq
    and     Com.IDSeq           = @IPVC_OMSID
    and     Act.CompanyIDSeq    = @IPVC_OMSID
    and     Act.AccountTypecode = 'AHOFF'
    and     Act.PropertyIDSeq   is null
    and     Act.Activeflag      = 1
  end  
  ----------------------------------------------------------------------------------------------- 
END
GO
