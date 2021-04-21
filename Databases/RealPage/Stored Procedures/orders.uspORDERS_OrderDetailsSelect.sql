SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_OrderDetailsSelect
-- Description     : This procedure gets Order Details pertaining to passed OrderID
-- Input Parameters: 1. @IPVC_OrderID   as varchar(10)
--                   
-- OUTPUT          : RecordSet of company PMCFlag,PropertyIDSeq,IDSeq,QuoteIDSeq,CreatedDate,
--                   CreatedBy,StatusCode,ApprovedDate,ApprovedBy,Name,IDSeq,SiteMasterID,
--                   AddressLine1,AddressLine2,city,State,Zip if PropertyIDSeq is null  
--
--                   RecordSet of Property PMCFlag,PropertyIDSeq,IDSeq,QuoteIDSeq,CreatedDate,
--                   CreatedBy,StatusCode,ApprovedDate,ApprovedBy,PropertyName,PropertySiteMasterID,
--                   Units,PPUPercentage,PAddressLine1,AddressLine2,city,state,zip
--                   and RecordSet of company        
--                   
-- Code Example    : Exec ORDERS.DBO.uspORDERS_OrderDetailsSelect 'O0902000745'--'O0902000118'--'O0901000001'
-- 
-- 
-- Revision History:
-- Author          : TMN
-- 11/27/2006      : Stored Procedure Created.
-- 11/29/2006      : Changed by TMN. Formatted the stored procedure
-- 12/01/2006      : Changed by STA to display the Order Status Name instead 
--                   of the Order Status Code. 
-- 12/07/2006      : Added companyID
-- 21/07/2006      : Changed by Naval.Created by with function
-- 05/20/2009	   : Naval kishore Modified to get Country Info for other countries. 
-- 06/08/2010      : Shashi Bhushan - Modified to align code and to get the QuoteType value from QUOTE table  
-- 2010-07-20	   : Larry. remove references to bogus column Address.Country (2010.07 regression)
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_OrderDetailsSelect] (@IPVC_OrderID varchar(50)                                                       
                                                      )
AS
BEGIN 
  set nocount on;
  -----------------------------------------------------------
  Declare @LVC_AccountID              varchar(50)
  Declare @LVC_PropertyID             varchar(50)
  Declare @LVC_RecentInvoiceID        varchar(50)

  select  Top 1 @LVC_AccountID =O.AccountIdseq,
                @LVC_PropertyID=O.PropertyIDSeq
  from    Orders.dbo.[order] O with (nolock)
  where   O.OrderIDSeq=@IPVC_OrderID

  set @LVC_RecentInvoiceID = (select top 1 InvoiceIDSeq
                              from invoices.dbo.invoice with (nolock)
                              where AccountIDSeq =@LVC_AccountID and PrintFlag=1
                              order by InvoiceIDSeq desc)
  -----------------------------------------------------------------------
  --Input Variable for the select statement  is @IPVC_OrderID
  --If @IPVC_PropertyIDSeq is NULL then select only company details
  --else select both company details and property details
  ----------------------------------------------------------------------
   if (coalesce(@LVC_PropertyID,'') = '')
   begin
      select 
           Convert(bit, 1)                          as PMCFlag,
           o.AccountIDSeq                           as AccountIDSeq,
           A.IDSeq                                  as CompanyAccountIDSeq,
           o.PropertyIDSeq                          as PropertyIDSeq,
           o.OrderIDSeq                             as IDSeq,
           o.QuoteIDSeq                             as QuoteIDSeq,
           o.CompanyIDSeq                           as CompanyIDSeq,
           convert(varchar (15),o.CreatedDate,101)  as OrderCreatedDate,
           o.CreatedBy                              as CreatedBy,
           ost.Name                                 as StatusCode,
           convert(varchar (15),o.ApprovedDate,101) as ApprovedDate,
           o.ApprovedBy                             as ApprovedBy,
           ''                                       as Name,
           ''                                       as SiteMasterID,
           ''                                       as Units,
           ''                                       as PPUPercentage,
           ''                                       as AddressLine1,
           ''                                       as AddressLine2,
           ''                                       as city,
           ''                                       as state,
           ''                                       as zip,
           '' 					    as Country,
           c.Name                                   as CName, 
           c.IDSeq                                  as CIDSeq,
           c.SiteMasterId                           as CSiteMasterId,
           compa.Addressline1                       as CAddressLine1,
           compa.AddressLine2                       as CAddressLine2,
           compa.city                               as CCity,
           compa.state                              as CState,
           compa.zip                                as CZip,
		   UPPER(compaC.[Name]) as CCountry,
           @LVC_RecentInvoiceID                     as InvoiceIDSeq,
           isnull(convert(varchar(15),II.OriginalPrintDate ,101), 'N/A')    as PrintDate,
           isnull(convert(varchar(15),II.CreatedDate,101), 'N/A')           as CreatedDate,
           isnull(convert(varchar(15),II.InvoiceDate,101), 'N/A')           as InvoiceDate,
           II.AccountIDSeq                                                  as AccountIDSeq,
           convert(numeric(10,2),
            (isnull(II.ILFChargeAmount,0)
            +isnull(II.AccessChargeAmount,0)
            +isnull(II.TransactionChargeAmount,0)
            +isnull(II.TaxAmount,0)
            +isnull(II.ShippingAndHandlingAmount,0)))                       as Amount,
           'N/A'                                                            as NextInvoiceDate,
           case when (o.QuoteIDSeq = '' or o.QuoteIDSeq is null) then 'NEWQ'
                else QT.[Code]
             end                                                            as QuoteTypeCode,
           case when (o.QuoteIDSeq = '' or o.QuoteIDSeq is null) then 'New'
                else QT.[Name]
             end                                                            as QuoteTypeName
      from Orders.dbo.[order] o           with (nolock)
      inner join 
           Customers.dbo.[Company] c      with (nolock)
        on  o.CompanyIDSeq = c.IDSeq
        and o.OrderIDSeq   = @IPVC_OrderID
      inner join
           Customers.dbo.Account A        with (nolock)
        ON C.IDSeq = A.CompanyIDSeq
        AND A.AccountTypeCode = 'AHOFF'
        AND A.PropertyIDSeq IS NULL
      inner join
           Customers.dbo.[Address] compa  with (nolock)
        on  compa.CompanyIDSeq = c.IDSeq
        and compa.AddressTypeCode = 'COM'
        and compa.PropertyIDSeq is null
	  left outer join [CUSTOMERS].[dbo].[Country] compaC with (nolock) on compaC.[Code]=compa.[CountryCode]
      inner join
           Orders.dbo.OrderStatusType ost with (nolock)
        on ost.Code = o.StatusCode      
      left outer join
            Invoices.dbo.invoice II       with (nolock)
        on o.AccountIDSeq         = II.AccountIDSeq  
       and II.InvoiceIDSeq        = @LVC_RecentInvoiceID
      left outer join
           Quotes.dbo.Quote Q             with (nolock)
        on o.QuoteIDSeq   = Q.QuoteIDSeq
       and o.CompanyIDSeq = Q.CustomerIDSeq
      left outer join
           Quotes.dbo.QuoteType QT       with (nolock)
        on QT.Code = Q.QuoteTypeCode
      where o.OrderIDSeq          = @IPVC_OrderID
        and compa.AddressTypeCode = 'COM'
        and compa.PropertyIDSeq is null
      end
  else
  begin
    select 
            Convert(bit, 0)                          as PMCFlag,
            ACT.IDSeq                                as CompanyAccountIDSeq,
            o.AccountIDSeq                           as AccountIDSeq,
            o.PropertyIDSeq                          as PropertyIDSeq,
            o.OrderIDSeq                             as IDSeq,
            o.QuoteIDSeq                             as QuoteIDSeq,
            o.CompanyIDSeq                           as CompanyIDSeq,
            convert(varchar (15),o.CreatedDate,101)  as OrderCreatedDate,
            o.CreatedBy                              as CreatedBy,
            ost.Name                                 as StatusCode,
            convert(varchar (15),o.ApprovedDate,101) as ApprovedDate,
            o.ApprovedBy                             as ApprovedBy,
            p.Name                                   as [Name],
            p.SiteMasterID                           as SiteMasterID,
            p.Units                                  as Units,
            p.PPUPercentage                          as PPUPercentage,
            a.AddressLine1                           as AddressLine1,
            a.AddressLine2                           as AddressLine2,
            a.city                                   as city,
            a.state                                  as state,
            a.zip                                    as zip,
		    UPPER(aC.[Name]) as country,
            c.Name                                   as CName,
            c.IDSeq                                  as CIDSeq,
            c.SiteMasterId                           as CSiteMasterId,
            compa.Addressline1                       as CAddressLine1,
            compa.AddressLine2                       as CAddressLine2,
            compa.city                               as CCity,
            compa.state                              as CState,
            compa.zip                                as CZip,
			UPPER(compaC.[Name]) as CCountry,
            @LVC_RecentInvoiceID                     as InvoiceIDSeq,
            isnull(convert(varchar(15),II.OriginalPrintDate ,101), 'N/A')   as PrintDate,
            isnull(convert(varchar(15),II.CreatedDate,101), 'N/A')             as CreatedDate,
            isnull(convert(varchar(15),II.InvoiceDate,101),'N/A')           as InvoiceDate,
            II.AccountIDSeq                                                 as AccountIDSeq,
            convert(numeric(10,2),
            (isnull(II.ILFChargeAmount,0)
            +isnull(II.AccessChargeAmount,0)
            +isnull(II.TransactionChargeAmount,0)
            +isnull(II.TaxAmount,0)
            +isnull(II.ShippingAndHandlingAmount,0)))                       as Amount,
            'N/A'                                                           as NextInvoiceDate,
           case when (o.QuoteIDSeq = '' or o.QuoteIDSeq is null) then 'NEWQ'
                else QT.[Code]
             end                                                            as QuoteTypeCode,
           case when (o.QuoteIDSeq = '' or o.QuoteIDSeq is null) then 'New'
                else QT.[Name]
             end                                                            as QuoteTypeName
     from   Orders.dbo.[order] o       with (nolock)
     inner join 
            Customers.dbo.[Company] c  with (nolock)
        ON  o.CompanyIDSeq  = c.IDSeq
        and o.OrderIDSeq           = @IPVC_OrderID
     inner join
            Customers.dbo.[Property] p with (nolock)
        ON  o.PropertyIDSeq = p.IDSeq
     inner join 
            Customers.dbo.[Address] a  with (nolock)
        ON  a.CompanyIDSeq     = C.IDSeq
        and a.PropertyIDSeq    = p.IDSeq
        and a.AddressTypeCode  = 'PRO'  
        and a.PropertyIDSeq   is not null   
left outer join [CUSTOMERS].[dbo].[Country] aC with (nolock) on aC.[Code]=a.[CountryCode]
     inner join  
            Customers.dbo.Account ACT  with (nolock)
        ON  C.IDSeq = ACT.CompanyIDSeq        
        and ACT.AccountTypeCode = 'AHOFF'
        AND ACT.PropertyIDSeq IS NULL
     inner join 
            Customers.dbo.Address compa with (nolock)
        ON  compa.CompanyIDSeq = c.IDSeq
        and compa.AddressTypeCode = 'COM'
        and compa.PropertyIDSeq is null    
	 left outer join [CUSTOMERS].[dbo].[Country] compaC with (nolock) on compaC.[Code]=compa.[CountryCode]
     inner join
            Orders.dbo.OrderStatusType ost with (nolock)
        on  ost.Code = o.StatusCode
     left outer join 
            Invoices.dbo.invoice II     with (nolock)
        ON  o.AccountIDSeq        = II.AccountIDSeq  
        and II.InvoiceIDSeq       = @LVC_RecentInvoiceID
     left outer join
           Quotes.dbo.Quote Q             with (nolock)
        on o.QuoteIDSeq   = Q.QuoteIDSeq
       and o.CompanyIDSeq = Q.CustomerIDSeq
     left outer join
            Quotes.dbo.QuoteType QT       with (nolock)
        on  QT.Code = Q.QuoteTypeCode
     where  o.OrderIDSeq           = @IPVC_OrderID            
        and a.AddressTypeCode      = 'PRO'     
        and compa.AddressTypeCode  = 'COM'
        and compa.PropertyIDSeq is null            
      end
END
GO
