SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Exec uspQUOTES_Rep_UnApprovedQuotes @IPVC_Quoteid = 'Q0806003197',@IPD_StartDate= '01/01/1900',@IPD_EndDate = '08/03/2008'
CREATE PROCEDURE [reports].[uspQUOTES_Rep_UnApprovedQuotes] (@IPVC_Quoteid       varchar(50)  = '',                                                 
                                                 @IPVC_CustomerName  varchar(255) = '',
                                                 @IPVC_ProductName   varchar(255) = '',
                                                 @IPD_StartDate      datetime,
                                                 @IPD_EndDate        datetime     
                                                )
AS
BEGIN
  set nocount on;
  ------------------------------------------------------
  SET @IPVC_Quoteid       = nullif(@IPVC_Quoteid,'')  
  SET @IPD_StartDate      = convert(datetime,convert(varchar(50),@IPD_StartDate,101))
  SET @IPD_EndDate        = convert(datetime,convert(varchar(50),@IPD_EndDate,101))
  ------------------------------------------------------
  create table #Temp_QuotesToConsider(Seq              int identity(1,1) not null,
                                      quoteidseq       varchar(50),
                                      createdate       varchar(50),
                                      customeridseq    varchar(50),
                                      customername     varchar(255),
                                      quoteilfamount         money,
                                      quoteAccessamount      money,
                                      quoteAncillaryAmount   money,
                                      quotetotalamount as (quoteilfamount+quoteAccessamount+quoteAncillaryAmount),
                                      productname      varchar(255),
                                      market           varchar(100),
                                      ProductILFAmount         money,
                                      ProductAccessAmount      money,
                                      ProductAncillaryAmount   money,                                     
                                      ProductTotalAmount       as (ProductILFAmount+ProductAccessAmount+ProductAncillaryAmount)
                                      )

  ------------------------------------------------------
  Insert into #Temp_QuotesToConsider(quoteidseq,createdate,customeridseq,customername,
                                     productname,market,
                                     ProductILFAmount,ProductAccessAmount,ProductAncillaryAmount
                                    )

  select Q.quoteidseq                               as quoteidseq,
         Convert(varchar(50),Max(Q.Createdate),101) as createdate,
         Q.customeridseq                            as customeridseq,
         COM.Name                                   as customername,
         P.displayname                              as productname,
         CAT.Name                                   as market,
         SUM(case when C.reportingtypecode = 'ILFF' then QI.NetExtYear1ChargeAmount
                  else 0
             end)                                   as ProductILFAmount,
         SUM(case when C.reportingtypecode = 'ACSF' then QI.NetExtYear1ChargeAmount
                  else 0
             end)                                   as ProductAccessAmount,
         SUM(case when C.reportingtypecode = 'ANCF' then QI.NetExtYear1ChargeAmount
                  else 0
             end)                                   as ProductAncillaryAmount         
  from   QUOTES.dbo.Quote      Q with (nolock)
  inner join
         CUSTOMERS.dbo.Company COM with (nolock)
  on     Q.customeridseq = COM.IDSeq
  and    (COM.Name not like '%TEST%' and COM.Name not like '%SAMPLE%') 
  and    COM.Name  like '%' + @IPVC_CustomerName + '%'  
  and    Q.Quotestatuscode <> 'CNL'
  -------------------------
  and    convert(datetime,convert(varchar(50),Q.Createdate,101)) >= @IPD_StartDate
  and    convert(datetime,convert(varchar(50),Q.Createdate,101)) <= @IPD_EndDate
  -------------------------
  and    Q.Quoteidseq    = coalesce(@IPVC_Quoteid,Q.Quoteidseq)  
  and Not exists (select top 1 1 from ORDERS.dbo.[ORDER] O with (nolock)
                  where O.Quoteidseq = Q.quoteidseq
                 )
  inner join
         QUOTES.dbo.QuoteItem QI with (nolock)
  on     QI.Quoteidseq = Q.quoteidseq
  -------------
  and  not ((Q.QuoteTypecode = 'RPRQ' OR Q.QuoteTypecode = 'STFQ')
                           AND
            (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
           )                
  -------------
  and     QI.ExcludeForBookingsFlag = 0
  -------------  
  inner join
          Products.dbo.Product P with (nolock)
  on      QI.Productcode = P.Code
  and     QI.Priceversion= P.PriceVersion
  and     P.ExcludeForBookingsFlag = 0
  and     P.displayname like '%' + @IPVC_ProductName + '%'
  inner join
          Products.dbo.Charge C with (nolock)
  on      QI.Productcode = C.Productcode
  and     QI.Priceversion= C.PriceVersion
  and     C.Productcode  = P.Code
  and     C.Priceversion = P.Priceversion
  and     C.ChargeTypecode = QI.ChargeTypecode
  and     C.Measurecode    = QI.Measurecode
  and     C.FrequencyCode  = QI.FrequencyCode  
  inner join
          Products.dbo.Category CAT with (nolock)
  on      CAT.Code = P.CategoryCode 
  group by Q.quoteidseq,Q.customeridseq,COM.Name,P.displayname,QI.ProductCode,CAT.Name
  order by createdate ASC,COM.Name ASC,P.displayname ASC,CAT.Name ASC
  --------------------------------------------------------------------
  Update D
  set    D.quoteilfamount       = S.quoteilfamount,
         D.quoteAccessamount    = S.quoteAccessamount,
         D.quoteAncillaryAmount = S.quoteAncillaryAmount
  from   #Temp_QuotesToConsider D with (nolock)
  inner join
         (select X.quoteidseq,sum(X.ProductILFAmount)       as quoteilfamount,
                              sum(X.ProductAccessAmount)    as quoteAccessamount,
                              sum(X.ProductAncillaryAmount) as quoteAncillaryAmount
          from  #Temp_QuotesToConsider X with (nolock)
          group by X.quoteidseq
         ) S
  on     D.quoteidseq=S.quoteidseq
  --------------------------------------------------------------------
  --Final Select
  select quoteidseq                                                            as [Quote],
         Createdate                                                            as [Create Date],
         customeridseq                                                         as [Customer ID],
         customername                                                          as [Customer],
         Quotes.DBO.fn_FormatCurrency(quoteilfamount,1,2)                      as [Quote ILF $],
         Quotes.DBO.fn_FormatCurrency(quoteAccessamount,1,2)                   as [Quote Access $],
         Quotes.DBO.fn_FormatCurrency(quoteAncillaryAmount,1,2)                as [Quote Ancillary $],
         Quotes.DBO.fn_FormatCurrency(quotetotalamount,1,2)                    as [Quote Total $],
         productname                                                           as [Product],
         market                                                                as [Market],
         Quotes.DBO.fn_FormatCurrency(ProductILFAmount,1,2)                    as [Product ILF $],
         Quotes.DBO.fn_FormatCurrency(ProductAccessAmount,1,2)                 as [Product Access $],
         Quotes.DBO.fn_FormatCurrency(ProductAncillaryAmount,1,2)              as [Product Ancillary $],
         Quotes.DBO.fn_FormatCurrency(ProductTotalAmount,1,2)                  as [Product Total $]
  from  #Temp_QuotesToConsider with (nolock)
  --------------------------------------------------------------------
  --Final cleanup
  drop table #Temp_QuotesToConsider
  --------------------------------------------------------------------
END

GO
