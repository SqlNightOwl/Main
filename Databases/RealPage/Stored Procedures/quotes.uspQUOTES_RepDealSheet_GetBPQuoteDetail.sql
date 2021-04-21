SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
--bpquotesummary
Exec Quotes.dbo.uspQUOTES_RepDealSheet_GetBPQuoteDetail 
@IPC_CompanyID='C0000002003',@IPVC_QuoteID='Q0000004538',@IPVC_Fees = 'Initial License Fees'

Exec Quotes.dbo.uspQUOTES_RepDealSheet_GetBPQuoteDetail 
@IPC_CompanyID='C0000009826',@IPVC_QuoteID='Q0000002548',@IPVC_Fees = 'Access Fees - Year I'
----------------------------------------------------------------------
*/
CREATE PROCEDURE [quotes].[uspQUOTES_RepDealSheet_GetBPQuoteDetail]
                                                         (@IPC_CompanyID     varchar(50),
                                                          @IPVC_QuoteID      varchar(8000),                                                          
                                                          @IPVC_Fees         varchar(100) = 'Access Fees - Year I' ,
                                                          @IPVC_Delimiter    varchar(1)= '|'                                                                                                                                                                                                                                                                                                       
                                                          )
AS
BEGIN   
  set nocount on;
  -----------------------------------------------------------------------------------
  declare @LT_Quotes  TABLE (QuoteID varchar(50)) 
  -----------------------------------------------------------------------------------
  --Parse the string to get all the Quotes.
  insert into @LT_Quotes(QuoteID)
  select Items as QuoteID from QUOTES.dbo.fnSplitDelimitedString(@IPVC_QuoteID,@IPVC_Delimiter)
  -----------------------------------------------------------------------------------
  --Declaring Local Variables 
  select @IPC_CompanyID = ltrim(rtrim(@IPC_CompanyID))
  -----------------------------------------------------------------------------------  
  -->Begining of bpquotedetail 
  --------------------------------------------------------
  create table #LT_Finalbpquotedetail 
                                 (                                  
                                  sortseq                      bigint not null identity(1,1),
                                  QuoteIDSeq                   varchar(50),
                                  GroupIDSeq                   bigint, 
                                  QuoteitemIDSeq               bigint,
                                  CustomBundleNameEnabledFlag  int    not null default 0,                                  
                                  productname            varchar(500)  default '',                                 
                                  sites                  varchar(100)  default '',
                                  units                  varchar(100)  default '',
                                  unitofmeasure          varchar(100)  default '',
                                  priceby                varchar(20)   default '',
                                  pricefrequency         varchar(20)   default '',    
                                  price                  varchar(100)  default '',  
                                  ListILF                varchar(100)  default '', 
                                  ILFdiscountpercent     varchar(100)  default '',
                                  ILFdiscountamount      varchar(100)  default '',                            
                                  NetILF                 varchar(100)  default '',                                  
                                  ListAccess             varchar(100)  default '',
                                  Accessdiscountpercent  varchar(100)  default '',
                                  Accessdiscountamount   varchar(100)  default '',  
                                  NetAccess              varchar(100)  default '',
                                  Period                 varchar(20)   default '',                                  
                                  Producttype            varchar(5)    default 'PR'                         
                                  )
  --Declaring Local Variable Table #LT_bpquotedetail 
  create table #LT_bpquotedetail   (sortseq                      bigint not null identity(1,1),
                                    QuoteIDSeq                   varchar(50),
                                    GroupIDSeq                   bigint, 
                                    QuoteitemIDSeq               bigint,
                                    CustomBundleNameEnabledFlag  int    not null default 0, 
                                    ordergroupname               varchar(255),            
                                    productname                  varchar(255),
                                    productcode                  varchar(50), 
                                    ILFsites                     bigint,
                                    ILFunits                     bigint,
                                    ILFunitofmeasure             numeric(30,0),

                                    ACSsites                     bigint,
                                    ACSunits                     bigint,
                                    ACSunitofmeasure             numeric(30,0),
     
                                    sites                        as  (case   when ACSmeasurename<>'' then ACSsites 
                                                                             when ACSmeasurename ='' then ILFsites 
                                                                      else 0 end),
                                    units                        as  (case   when ACSmeasurename<>'' then ACSunits
                                                                             when ACSmeasurename ='' then ILFunits
                                                                      else 0 end),
                                    unitofmeasure                as  (case   when ACSmeasurename<>'' then ACSunitofmeasure
                                                                             when ACSmeasurename ='' then ILFunitofmeasure
                                                                      else 0 end),                                      
                                    ILFmeasurename               varchar(50),
                                    ILFfrequencyname             varchar(50),
                                    
                                    ACSmeasurename               varchar(50),                                   
                                    ACSfrequencyname             varchar(50),
                                    
                                    measurename                        as  (case   when ACSmeasurename<>'' then ACSmeasurename
                                                                                   when ACSmeasurename ='' then ILFmeasurename
                                                                            else '' end),
                                    frequencyname                      as  (case   when ACSmeasurename<>'' then ACSfrequencyname
                                                                                   when ACSmeasurename ='' then ILFfrequencyname
                                                                            else '' end),
                                    accesspresentindicator       as        (case  when ACSmeasurename<>'' then 1
                                                                                  else 0
                                                                            end),
                                    Period                       as        (case when ACSfrequencyname in ('MN','Monthly','Month','Months')
                                                                                    then 12
                                                                                else 1
                                                                            end),
                                    ListExtILF                   numeric(30,2), 
                                    NetExtILF                    numeric(30,2),
                                
                                    ILFdiscountpercent           numeric(30,2),
                                    ILFdiscountamount            numeric(30,2),

                                    ListExtAccess                numeric(30,2),
                                    NetExtAccess                 numeric(30,2),                                    
                                    Accessdiscountpercent        numeric(30,2),
                                    Accessdiscountamount         numeric(30,2),
                                    ACSUnitPrice                 Float                                     
                                    )
  ---------------------------------------------------------------------------------------------------------------------------
  insert into #LT_bpquotedetail(QuoteIDSeq,GroupIDSeq,QuoteitemIDSeq,CustomBundleNameEnabledFlag,ordergroupname,productname,productcode,
                                ILFsites,ILFunits,ILFunitofmeasure,
                                ACSsites,ACSunits,ACSunitofmeasure,
                                ILFmeasurename,ILFfrequencyname,
                                ACSmeasurename,ACSfrequencyname,
                                ListExtILF,NetExtILF,ILFdiscountpercent,ILFdiscountamount,
                                ListExtAccess,NetExtAccess,Accessdiscountpercent,Accessdiscountamount,
                                ACSUnitPrice            
                               )
  select QI.Quoteidseq,QI.GroupIDSeq,max(QI.IDSeq),
         G.CustomBundleNameEnabledFlag,G.Name as ordergroupname,
         PRD.Displayname as productname,QI.productcode as productcode,
         Max(case when (QI.chargetypecode = 'ILF') then QI.Sites
		  else 0
	     end) as ILFSites,
         Max(case when (QI.chargetypecode = 'ILF') then QI.units
		  else 0
	     end) as ILFUnits,
         Max(case when (QI.chargetypecode = 'ILF') then QI.unitofmeasure
		  else 0
	     end) as ILFunitofmeasure,
         Max(case when (QI.chargetypecode = 'ACS') then QI.Sites
		  else 0
	     end) as ACSSites,
         Max(case when (QI.chargetypecode = 'ACS') then QI.units
		  else 0
	     end) as ACSUnits,
         Max(case when (QI.chargetypecode = 'ACS'  and 
                        QI.Measurecode    = 'UNIT' and   
                        PRD.Familycode    = 'LSD'
                       )                          then QI.Multiplier
                 when (QI.chargetypecode = 'ACS') then QI.unitofmeasure
		  else 0
	     end) as ACSunitofmeasure,
         ------------------------------------
         Max(case when (QI.chargetypecode = 'ILF') then M.Code
		  else ''
	     end)	                                                   as ILFMeasureName,
         Max(case when (QI.chargetypecode = 'ILF') then F.Code
		  else ''
	     end)	                                                   as ILFFrequencyName,
         ------------------------------------
         Max(case when (QI.chargetypecode = 'ACS') then M.Code
		  else ''
	     end)	                                                   as ACSMeasureName,
         Max(case when (QI.chargetypecode = 'ACS') then F.Code
		  else ''
	     end)	                                                   as ACSFrequencyName,
         ------------------------------------
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),QI.ExtYear1ChargeAmount)                                                                 
		  else 0
	     end)	                                                   as ListExtILF,          
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),QI.NetExtYear1ChargeAmount)
		  else 0
	     end)	                                                   as NetExtILF, 
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),QI.TotalDiscountPercent)
		  else 0
	     end)	                                                   as ILFdiscountpercent, 
         Sum(case when (QI.chargetypecode = 'ILF') then convert(NUMERIC(30,2),QI.TotalDiscountamount)
		  else 0
	     end)	                                                   as ILFdiscountamount, 
         ------------------------------------
         Sum(case when (QI.chargetypecode = 'ACS') then convert(NUMERIC(30,2),QI.ExtYear1ChargeAmount)                                                                 
		  else 0
	     end)	                                                   as ListExtACS,          
         Sum(case when (QI.chargetypecode = 'ACS') then convert(NUMERIC(30,2),QI.NetExtYear1ChargeAmount)
		  else 0
	     end)	                                                   as NetExtACS, 
         Sum(case when (QI.chargetypecode = 'ACS') then convert(NUMERIC(30,2),QI.TotalDiscountPercent)
		  else 0
	     end)	                                                   as ACSdiscountpercent, 
         Sum(case when (QI.chargetypecode = 'ACS') then convert(NUMERIC(30,2),QI.TotalDiscountamount)
		  else 0
	     end)	                                                   as ACSdiscountamount, 
         Sum(case when (QI.chargetypecode = 'ACS') then  convert(float,
                                                                  Convert(float,QI.NetExtYear1ChargeAmount)
                                                                  /(CASE when
                                                                           (case when (QI.chargetypecode = 'ACS'  and 
                                                                                       QI.Measurecode    = 'UNIT' and   
                                                                                       PRD.Familycode    = 'LSD'
                                                                                       )                          then QI.Multiplier
                                                                                 when (QI.chargetypecode = 'ACS') then QI.unitofmeasure
		                                                             else 1 end) > 0 then (case when (QI.chargetypecode = 'ACS'  and 
                                                                                                            QI.Measurecode    = 'UNIT' and   
                                                                                                            PRD.Familycode    = 'LSD'
                                                                                                            ) then QI.Multiplier
                                                                                                      when (QI.chargetypecode = 'ACS') then QI.unitofmeasure
		                                                                                  else 1 end)
                                                                   ELSE 1 END)
                                                                )
		  else 0
	     end)	                                                   as ACSUnitPrice
  from Quotes.dbo.Quoteitem   QI with (nolock)
  inner join
       @LT_Quotes QQ
  on   QI.Quoteidseq = QQ.QuoteID
  inner join
       Quotes.dbo.[Group]    G with (nolock)
  on   QI.Quoteidseq = G.Quoteidseq
  and  QI.Groupidseq = G.IDSeq
  inner join
         Products.dbo.Product  PRD with (nolock)
  on     QI.Productcode = PRD.Code
  and    QI.priceversion= PRD.priceversion
  inner join
         Products.dbo.Measure M with (nolock)
  on     QI.Measurecode   = M.code
  inner join
         Products.dbo.Frequency F with (nolock)
  on     QI.Frequencycode = F.code
  Group by QI.QuoteIDSeq,QI.GroupIDSeq,G.IDSeq,G.Name,G.CustomBundleNameEnabledFlag,QI.ProductCode,PRD.DisplayName
  ---------------------------------------------------------------------------------------------------
  ----Insert Just the Alacart Products.
  Insert into #LT_Finalbpquotedetail(QuoteIDSeq,GroupIDSeq,QuoteitemIDSeq,
                                     CustomBundleNameEnabledFlag,productname,
                                     sites,units,unitofmeasure,priceby,pricefrequency,
                                     price,
                                     ListILF,ILFdiscountpercent,ILFdiscountamount,NetILF,
                                     ListAccess,Accessdiscountpercent,Accessdiscountamount,NetAccess,
                                     Period,Producttype
                                     )
  select S.QuoteIDSeq,S.GroupIDSeq,S.QuoteitemIDSeq,
         S.CustomBundleNameEnabledFlag,S.productname,
         S.Sites,S.Units,Quotes.DBO.fn_FormatCurrency(S.unitOfMeasure,0,0) as unitOfMeasure,
         S.measurename as priceby,S.frequencyname               as pricefrequency, 
         (case when S.accesspresentindicator = 1
                then Quotes.DBO.fn_FormatCurrency(
                                                 Convert(numeric(30,2),
                                                         Convert(float,S.ACSUnitPrice)/(case when S.Period > 0 then S.Period else 1 end)
                                                        )
                     ,1,2)
               else '' 
         end)                                                   as price,
         Quotes.DBO.fn_FormatCurrency(S.ListExtILF,0,0)         as ListILF,
         Quotes.DBO.fn_FormatCurrency(S.ILFdiscountpercent,1,2) as ILFdiscountpercent,
         Quotes.DBO.fn_FormatCurrency(S.ILFdiscountamount,0,0)  as ILFdiscountamount,
         Quotes.DBO.fn_FormatCurrency(S.NetExtILF,0,0)          as NetILF,
         Quotes.DBO.fn_FormatCurrency(S.ListExtAccess,0,0)      as ListAccess,
         Quotes.DBO.fn_FormatCurrency(S.Accessdiscountpercent,1,2) as Accessdiscountpercent,
         Quotes.DBO.fn_FormatCurrency(S.Accessdiscountamount,0,0)  as Accessdiscountamount,
         Quotes.DBO.fn_FormatCurrency(S.NetExtAccess,0,0)          as NetAccess,
         S.Period                                                  as Period,
         'PR' as Producttype
  from  #LT_bpquotedetail S with (nolock)
  where S.CustomBundleNameEnabledFlag = 0
  order by productname ASC
  ---------------------------------------------------------------------
  ----Insert Just the Custom Bundles as products.
  Insert into #LT_Finalbpquotedetail(QuoteIDSeq,GroupIDSeq,QuoteitemIDSeq,
                                     CustomBundleNameEnabledFlag,productname,
                                     sites,units,unitofmeasure,priceby,pricefrequency,
                                     price,
                                     ListILF,ILFdiscountpercent,ILFdiscountamount,NetILF,
                                     ListAccess,Accessdiscountpercent,Accessdiscountamount,NetAccess,
                                     Period,Producttype
                                     )
  select S.QuoteIDSeq,S.GroupIDSeq,max(S.QuoteitemIDSeq) as QuoteitemIDSeq,
         1 as CustomBundleNameEnabledFlag,S.ordergroupname as productname,
         max(S.Sites) as Sites,max(S.Units) as Units,
         Quotes.DBO.fn_FormatCurrency(max(S.unitOfMeasure),0,0) as unitOfMeasure,
         max(S.measurename) as priceby,max(S.frequencyname)     as pricefrequency,
         (case when Max(S.accesspresentindicator) = 1 
                      then Quotes.DBO.fn_FormatCurrency(
                                                           Convert(numeric(30,2),
                                                                     Convert(float,(sum(S.NetExtAccess)/(case when max(S.unitOfMeasure)=0 then 1 
                                                                                                              else max(S.unitOfMeasure)
                                                                                                         end) 
                                                                                    )/(case when Max(S.Period) > 0 then Max(S.Period) else 1 end)
                                                                             )
                                                                  )
                                                        ,1,2)
          else '' end) as price,         
         Quotes.DBO.fn_FormatCurrency(SUM(S.ListExtILF),0,0)    as ListILF,
         Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtILF)-SUM(S.NetExtILF))*100 /(CASE WHEN SUM(S.ListExtILF)>0 THEN SUM(S.ListExtILF) ELSE 1 END)
                                      ,1,2)                                      AS ILFdiscountpercent,
         Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtILF)-SUM(S.NetExtILF)),0,0)  AS ILFdiscountamount,
         Quotes.DBO.fn_FormatCurrency(SUM(S.NetExtILF),0,0)                      as NetILF,
         Quotes.DBO.fn_FormatCurrency(SUM(S.ListExtAccess),0,0)                  as ListAccess,
         Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtAccess)-SUM(S.NetExtAccess))*100 /(CASE WHEN SUM(S.ListExtAccess)>0 THEN SUM(S.ListExtAccess) ELSE 1 END)
                                      ,1,2)                                       AS Accessdiscountpercent,
         Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtAccess)-SUM(S.NetExtAccess)),1,2) AS Accessdiscountamount,
         Quotes.DBO.fn_FormatCurrency(SUM(S.NetExtAccess),0,0)                        as NetAccess,
         Max(S.Period)                                                                as Period,
         'CB' as Producttype
  from  #LT_bpquotedetail S with (nolock)
  where S.CustomBundleNameEnabledFlag = 1
  group by S.QuoteIDSeq,S.GroupIDSeq,S.ordergroupname,S.measurename,S.frequencyname
  order by ordergroupname ASC
  ---------------------------------------------------------------------
  ----Insert Just the products for Custom Bundles.
  set identity_insert #LT_Finalbpquotedetail on;
  Insert into #LT_Finalbpquotedetail(sortseq,QuoteIDSeq,GroupIDSeq,QuoteitemIDSeq,
                                     CustomBundleNameEnabledFlag,productname,
                                     sites,units,unitofmeasure,priceby,pricefrequency,
                                     price,
                                     ListILF,ILFdiscountpercent,ILFdiscountamount,NetILF,
                                     ListAccess,Accessdiscountpercent,Accessdiscountamount,NetAccess,
                                     Period,Producttype
                                     )
 select S.sortseq,S.QuoteIDSeq,S.GroupIDSeq,S.QuoteitemIDSeq as QuoteitemIDSeq,
        1 as CustomBundleNameEnabledFlag,D.productname as productname,
        '' as sites,'' as units,'' as unitofmeasure,'' as priceby,'' as pricefrequency,
        '' as price,
        '' as ListILF,'' as ILFdiscountpercent,'' as ILFdiscountamount,'' as NetILF,
        '' as ListAccess,'' as Accessdiscountpercent,'' as Accessdiscountamount,'' as NetAccess,
        '' as Period,
        'CR' as Producttype
 from   #LT_bpquotedetail      D with (nolock)    
 inner join 
        #LT_Finalbpquotedetail S with (nolock)
 on     D.QuoteIDSeq = S.QuoteIDSeq
 and    D.GroupIDSeq = S.GroupIDSeq
 and    D.CustomBundleNameEnabledFlag = S.CustomBundleNameEnabledFlag
 and    D.CustomBundleNameEnabledFlag = 1
 and    S.CustomBundleNameEnabledFlag = 1
 order by D.ordergroupname ASC,D.productname ASC

 ---------------------------------------------------------------------
 ----Insert as Final Total 
 Insert into #LT_Finalbpquotedetail(sortseq,QuoteIDSeq,GroupIDSeq,QuoteitemIDSeq,
                                     CustomBundleNameEnabledFlag,productname,
                                     sites,units,unitofmeasure,priceby,pricefrequency,
                                     price,
                                     ListILF,ILFdiscountpercent,ILFdiscountamount,NetILF,
                                     ListAccess,Accessdiscountpercent,Accessdiscountamount,NetAccess,
                                     Period,Producttype
                                     )
 select 999999999999999999 as sortseq,NULL as QuoteIDSeq,NULL as GroupIDSeq,NULL as QuoteitemIDSeq,
        0 as CustomBundleNameEnabledFlag,'Total' as productname,
        '' as sites,'' as units,'' as unitofmeasure,
        '' as priceby,'' as pricefrequency,
        '' as price,
        Quotes.DBO.fn_FormatCurrency(SUM(S.ListExtILF),0,0)    as ListILF,
        Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtILF)-SUM(S.NetExtILF))*100 /(CASE WHEN SUM(S.ListExtILF)>0 THEN SUM(S.ListExtILF) ELSE 1 END)
                                      ,1,2)                                      AS ILFdiscountpercent,
        Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtILF)-SUM(S.NetExtILF)),0,0)  AS ILFdiscountamount,
        Quotes.DBO.fn_FormatCurrency(SUM(S.NetExtILF),0,0)                      as NetILF,
        Quotes.DBO.fn_FormatCurrency(SUM(S.ListExtAccess),0,0)                  as ListAccess,
        Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtAccess)-SUM(S.NetExtAccess))*100 /(CASE WHEN SUM(S.ListExtAccess)>0 THEN SUM(S.ListExtAccess) ELSE 1 END)
                                      ,1,2)                                       AS Accessdiscountpercent,
        Quotes.DBO.fn_FormatCurrency((SUM(S.ListExtAccess)-SUM(S.NetExtAccess)),1,2) AS Accessdiscountamount,
        Quotes.DBO.fn_FormatCurrency(SUM(S.NetExtAccess),0,0)                        as NetAccess,
        ''   as Period,
        'ZZ' as Producttype
  from  #LT_bpquotedetail S
 set identity_insert #LT_Finalbpquotedetail off;
 ---------------------------------------------------------------------
 --Final Select 
 select productname,
        sites,units,unitofmeasure,
        (case when priceby='TRAN' then 'TRANSACTION'
              else upper(priceby)
            end) as priceby,
        (case when pricefrequency = 'SG' then 'INITIAL FEE'
              when (pricefrequency = 'OT' and priceby='TRAN') then 'PER OCCURRENCE'
              when pricefrequency = 'OT' then 'ONE-TIME'
              when pricefrequency = 'OC' then 'USAGE'
            else upper(pricefrequency)
           end)                                                      as pricefrequency,
        price,
        Period,
        ListILF,ILFdiscountpercent,ILFdiscountamount,NetILF,
        ListAccess,Accessdiscountpercent,Accessdiscountamount,NetAccess 
 from   #LT_Finalbpquotedetail
 order  by sortseq asc,producttype asc
 ----------------------------------------------------------------------
 --Final cleanup
 drop table #LT_bpquotedetail
 drop table #LT_Finalbpquotedetail
 ----------------------------------------------------------------------
END
GO
