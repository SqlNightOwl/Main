SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
--bpquotesummary
exec Quotes.dbo.uspQUOTES_RepDealSheet_GetRenewalCap 
@IPC_CompanyID = 'C0000032910',@IPVC_QuoteID = 'Q0000005367'

exec Quotes.dbo.uspQUOTES_RepDealSheet_GetRenewalCap 
@IPC_CompanyID = 'C0000032910',@IPVC_QuoteID = 'Q0000005367|Q0000005398|Q0000005399|Q0000005400'
----------------------------------------------------------------------
*/

CREATE PROCEDURE [quotes].[uspQUOTES_RepDealSheet_GetRenewalCap]
                                                         (@IPC_CompanyID     varchar(50),
                                                          @IPVC_QuoteID      varchar(8000), 
                                                          @IPVC_Delimiter    varchar(1)= '|'                                                                                                                                                                                                               
                                                          )
AS
BEGIN   
  set nocount on 
  -----------------------------------------------------------------------------------
  declare @LT_Quotes  TABLE (QuoteID varchar(50)) 
  -----------------------------------------------------------------------------------
  --Parse the string to get all the Quotes.
  insert into @LT_Quotes(QuoteID)
  select Items as QuoteID from QUOTES.dbo.fnSplitDelimitedString(@IPVC_QuoteID,@IPVC_Delimiter)
  -----------------------------------------------------------------------------------  
  declare @LT_RenewalCap table (seq           bigint identity(1,1) not null,                               
                                Productcode   varchar(500)         null,
                                ProductName   varchar(500)         null,
                                ProductDisplayName varchar(500)    null,
                                Sites         bigint               not null default 0,
                                capterm       bigint               not null default '0',
                                cappercent    numeric(30,2)        not null default 0.00,
                                capbasis      varchar(50)          not null default 'LIST',
                                startdate     datetime             null,
                                enddate       datetime             null
                                )
  ----------------------------------------------------------------------
  Insert into @LT_RenewalCap(Productcode,ProductName,ProductDisplayName,
                             Sites,capterm,cappercent,capbasis,startdate,enddate)
  select distinct
         PCPR.ProductCode     as Productcode,
         P.Name               as ProductName,
         P.DisplayName        as ProductDisplayName,      
         Count(GP.PropertyIDSeq)
                              as Sites,
         PC.PriceCapTerm      as capterm,
         PC.PriceCapPercent   as cappercent,
         PC.PriceCapBasisCode as capbasis,
         PC.PriceCapStartDate as startdate,
         PC.PriceCapEndDate   as startdate
  from CUSTOMERS.dbo.PriceCap PC with (nolock)
  inner join CUSTOMERS.dbo.PriceCapProducts PCPR with (nolock)
  on    PC.IDSeq = PCPR.PriceCapIDSeq
  and   PC.ActiveFlag = 1
  and   PC.CompanyIDSeq = PCPR.CompanyIDSeq
  and   PC.CompanyIDSeq = @IPC_CompanyID
  and   PCPR.CompanyIDSeq = @IPC_CompanyID 
  inner join PRODUCTS.dbo.Product P with (nolock)
  on    PCPR.ProductCode = P.Code
  and   exists (select Top 1 QI.ProductCode
                from   QUOTES.dbo.QuoteItem QI with (nolock)
                inner join
                       @LT_Quotes  S  
                on     QI.QuoteIDseq  = S.QuoteID
                and    QI.ProductCode = PCPR.ProductCode                
                and    QI.ProductCode = P.code
                and    QI.PriceVersion= P.PriceVersion 
                )
  left outer join CUSTOMERS.dbo.PriceCapProperties PCP with (nolock)
  on   PCPR.CompanyIDSeq = PCP.CompanyIDSeq
  and  PCP.CompanyIDSeq  = @IPC_CompanyID
  and  PCPR.CompanyIDSeq = @IPC_CompanyID 
  Left outer join QUOTES.dbo.GroupProperties GP with (nolock)
  on   GP.CustomerIDSeq = PCP.CompanyIDSeq
  and  GP.PropertyIDSeq = PCP.PropertyIDSeq
  and  GP.CustomerIDSeq = @IPC_CompanyID 
  and  exists (select top 1 1 
               from   @LT_Quotes S
               where  GP.QuoteIDseq = S.QuoteID
              )  
  group by PCPR.ProductCode,P.Name,P.DisplayName,PC.PriceCapTerm,
           PC.PriceCapPercent,PC.PriceCapBasisCode,PC.PriceCapStartDate,
           PC.PriceCapEndDate
  order by P.DisplayName,PC.PriceCapStartDate,PC.PriceCapEndDate
  ----------------------------------------------------------------------
  if (select count(*) from @LT_RenewalCap) = 0
  begin
    insert into @LT_RenewalCap(Productcode,ProductName,ProductDisplayName,
                              Sites,capterm,cappercent,capbasis,startdate,enddate)
    select '' as productcode,'' as ProductName,'' as ProductDisplayName,
           0  as Sites,0 as capterm,0.00 as cappercent,'LIST' as capbasis,
           NULL as startdate,NULL as enddate
  end
  ----------------------------------------------------------------------
  --Final Select
  select ProductDisplayName as Product,Sites,capterm,cappercent,capbasis,
         convert(varchar(50),startdate,101) as startdate,
         convert(varchar(50),enddate,101) as enddate 
  from   @LT_RenewalCap
  ----------------------------------------------------------------------
END

GO
