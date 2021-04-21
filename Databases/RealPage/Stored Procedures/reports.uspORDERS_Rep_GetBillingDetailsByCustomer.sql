SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : uspORDERS_Rep_GetBillingDetailsByCustomer      
-- Description     : This procedure gets Billing Details based on Customer. And this is based on the Excel File 'Billings Detail ByCustomer.xls'     
-- Input Parameters: Except @IPDT_OrderStartDate and @IPDT_OrderEndDate other Input parameters are optional
--            
-- Code Example    : Exec [dbo].[uspORDERS_Rep_GetBillingDetailsByCustomer] '','','Jonathan Wyant','','','','06/01/2009','06/03/2009'
--       
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 08/08/2007      : Stored Procedure Created.
-- 12/09/2008      : Naval Kishore Modified, to add filters for  @ProductFamilyCode and  @ProductPlatformCode
-- 09/04/2009	   : Naval Kishore Modified, to change the column Names in correct format. Defect #5480          
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_GetBillingDetailsByCustomer]      
                                                                  (      
                                                                    @CompanyID           varchar(20)  ='',
                                                                    @CustomerName        varchar(100) ='',                                                                    
                                                                    @AccountManager      varchar(255) ='',                                                                    
                                                                    @ProductName         varchar(255) ='',
                                                                    @ProductFamilyCode   varchar(5)   ='',
                                                                    @ProductPlatformCode varchar(5)   ='',
                                                                    @InvoiceStartDate    Datetime     ,
                                                                    @InvoiceEndDate      Datetime     
                                                                  )      
AS      
BEGIN         
  SET NOCOUNT ON;   
  set ANSI_WARNINGS off;
  ------------------------------------------------------------
  set @CompanyID           = nullif(@CompanyID,'');  
  set @AccountManager      = nullif(@AccountManager,'');
  set @ProductFamilyCode   = nullif(@ProductFamilyCode,'');
  set @ProductPlatformCode = nullif(@ProductPlatformCode,'');
  ------------------------------------------------------------
  create table #LT_BillingDetailsByCustomer(sortseq                int not null identity(1,1),
                                  companyidseq           varchar(50),
                                  propertyidseq          varchar(50),
                                  companyname            varchar(500),
                                  propertyname           varchar(500),
                                  accountname            as coalesce(nullif(propertyname,''),companyname),
                                  invoiceidseq           varchar(50),
                                  printflag              int    not null default(0),
                                  orderidseq             varchar(50),
                                  ordergroupidseq        bigint,
                                  ordergroupname         varchar(500),
                                  custombundleflag       int    not null default(0),
                                  platformname           varchar(255),
                                  familyname             varchar(255),
                                  categoryname           varchar(255),
                                  productcode            varchar(30),
                                  productname            varchar(500),                                  
                                  ILFOrderitemstatus     varchar(100),
                                  ILFStartDate           varchar(30),
                                  ILFCancelDate          varchar(30),
                                  ILFExtChargeAmount     numeric(30,2),
                                  ILFDiscAmount          numeric(30,2),
                                  ILFDiscPercent         numeric(30,5),
                                  ILFNetChargeamount     numeric(30,2),
                                  ILFBilledAmount        numeric(30,2),
                                  ILFCreditAmount        numeric(30,2),
                                  ILFPendingAmount       numeric(30,2),
                                  -------------------------------------
                                  ACSOrderitemstatus     varchar(100),
                                  ACSStartDate           varchar(30),
                                  ACSEndDate             varchar(30),
                                  ACSCancelDate          varchar(30),
                                  ACSUnitPrice           numeric(30,2),                                  
                                  ACSExtChargeAmount     numeric(30,2),
                                  ACSDiscAmount          numeric(30,2),
                                  ACSDiscPercent         numeric(30,5),
                                  ACSNetChargeamount     numeric(30,2),
                                  ACSBilledAmount        numeric(30,2),
                                  ACSCreditAmount        numeric(30,2),
                                  ACSPendingAmount       numeric(30,2),
                                  ACSUnits               int,
                                  ACSBeds                int,
                                  ACSPPU                 int,
                                  ACSMeasure             varchar(50),
                                  ACSFrequency           varchar(50),                                  
                                  -------------------------------------
                                  ANCOrderitemstatus     varchar(100),
                                  ANCStartDate           varchar(30),
                                  ANCEndDate             varchar(30),
                                  ANCCancelDate          varchar(30),
                                  ANCUnitPrice           numeric(30,2),                                  
                                  ANCExtChargeAmount     numeric(30,2),
                                  ANCDiscAmount          numeric(30,2),
                                  ANCDiscPercent         numeric(30,5),
                                  ANCNetChargeamount     numeric(30,2),
                                  ANCBilledAmount        numeric(30,2),
                                  ANCCreditAmount        numeric(30,2),
                                  ANCPendingAmount       numeric(30,2),                                  
                                  ANCMeasure             varchar(50),
                                  ANCFrequency           varchar(50),                                  
                                  ---------------------------------------
                                  BillingPeriodFromDate  varchar(50),
                                  BillingPeriodToDate    varchar(50),
                                  QuoteIDSeq             varchar(50),
                                  SalesAgentIDSeq        bigint not null default (-1),
                                  QuoteSaleAgentName     varchar(200) not null default (''),
                                  RecordIdentifier       varchar(10)  
                                 )
  ------------------------------------------------------------
  Insert into #LT_BillingDetailsByCustomer(companyidseq,propertyidseq,companyname,propertyname,invoiceidseq,printflag,
                                 orderidseq,ordergroupidseq,ordergroupname,custombundleflag,platformname,familyname,categoryname,
                                 productcode,productname,BillingPeriodFromDate,BillingPeriodToDate,QuoteIDSeq,
                                 ILFOrderitemstatus,ILFStartDate,ILFCancelDate,ILFExtChargeAmount,ILFDiscAmount,ILFDiscPercent,ILFNetChargeamount,ILFBilledAmount,ILFCreditAmount,ILFPendingAmount,
                                 ACSOrderitemstatus,ACSStartDate,ACSEndDate,ACSCancelDate,
                                 ACSUnitPrice,
                                 ACSExtChargeAmount,ACSDiscAmount,ACSDiscPercent,ACSNetChargeamount,ACSBilledAmount,ACSCreditAmount,ACSPendingAmount,
                                 ACSUnits,ACSBeds,ACSPPU,ACSMeasure,ACSFrequency,
                                 ANCOrderitemstatus,ANCStartDate,ANCEndDate,ANCCancelDate,
                                 ANCUnitPrice,
                                 ANCExtChargeAmount,ANCDiscAmount,ANCDiscPercent,ANCNetChargeamount,ANCBilledAmount,ANCCreditAmount,ANCPendingAmount,
                                 ANCMeasure,ANCFrequency
                                )
  select I.companyIDSeq,I.PropertyIDSeq,I.CompanyName,I.propertyname,I.InvoiceIDSeq,I.PrintFlag,
         II.OrderIDSeq,II.ordergroupidseq,(case when OG.CustomBundleNameEnabledFlag = 1 then  OG.Name
                                                else P.DisplayName
                                           end)   as ordergroupname,
         OG.CustomBundleNameEnabledFlag as custombundleflag,
         PF.Name as platformname,
         (case when OG.CustomBundleNameEnabledFlag = 1 then 'Custom Bundle' else F.Name end)    as familyname, 
         (case when OG.CustomBundleNameEnabledFlag = 1 then 'Custom Bundle' else Cat.Name end)  as categoryname,
         II.productcode,
         (case when Max(case when II.Chargetypecode = 'ACS' then II.Measurecode else NULL end) = 'TRAN'
                  then II.TransactionItemName
               else P.DisplayName 
          end) as productname,
         convert(varchar(50),II.BillingPeriodFromDate,101),
         convert(varchar(50),II.BillingPeriodToDate,101), 
         Max(O.QuoteIDSeq)  as QuoteIDSeq,
         ------------------------------------------------------------------------
         (select top 1 X.Name from Orders.dbo.Orderstatustype X with (nolock) where X.Code =
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then OI.Statuscode
                   else NULL
              end)
            )) as ILFOrderitemstatus,
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then convert(varchar(50),OI.StartDate,101)
               else NULL
              end)
             ) as ILFStartDate,
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then convert(varchar(50),OI.CancelDate,101)
                   else NULL
              end)
            ) as ILFCancelDate, 
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.ExtChargeAmount
                   else NULL
              end)
            )  as ILFExtChargeAmount, 
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.DiscountAmount
                   else NULL
              end)
            )  as ILFDiscAmount,
         ((
           Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.ExtChargeAmount
                     else NULL
                end)
               ) -        
              Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.NetChargeamount
                        else NULL
                   end)
                 )
         ) * 100) / (case when Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.ExtChargeAmount
                                         else 0
                                    end)
                                  ) = 0 then 1
                          else Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.ExtChargeAmount
                                         else NULL
                                    end)
                                  )
                     end) as ILFDiscPercent,
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.NetChargeamount
                   else NULL
              end)
            )  as ILFNetChargeamount, 
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') and I.PrintFlag = 1 then II.NetChargeamount
                   else NULL
              end)
            )  as ILFBilledAmount, 
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') then II.CreditAmount
                   else NULL
              end)
            )  as ILFCreditAmount, 
         Max((Case when (II.Chargetypecode = 'ILF' and II.Reportingtypecode = 'ILFF') and I.PrintFlag = 0 then II.NetChargeamount
                   else NULL
              end)
            )  as ILFPendingAmount,  
         ------------------------------------------------------------------------
         (select top 1 X.Name from Orders.dbo.Orderstatustype X with (nolock) where X.Code =
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then OI.Statuscode
                   else NULL
              end)
            ))  as ACSOrderitemstatus,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF' and II.Measurecode <> 'TRAN') then convert(varchar(50),OI.StartDate,101)
                   when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF' and II.Measurecode = 'TRAN') then convert(varchar(50),II.TransactionDate,101)
               else NULL
              end)
             ) as ACSStartDate,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF' and II.Measurecode <> 'TRAN') then convert(varchar(50),OI.EndDate,101)
                   when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF' and II.Measurecode = 'TRAN') then convert(varchar(50),II.TransactionDate,101) 
               else NULL
              end)
             ) as ACSEndDate,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then convert(varchar(50),OI.CancelDate,101)
                   else NULL
              end)
            ) as ACSCancelDate, 
 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF' and II.PricingTiers = 1 and OG.CustomBundleNameEnabledFlag=0) 
                      then (II.ExtChargeAmount)
                   else NULL
              end)
            )/
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF' and II.PricingTiers = 1 and OG.CustomBundleNameEnabledFlag=0) 
                      then (case when II.Effectivequantity = 0 then 1 else II.Effectivequantity end)
              end)
            )   as ACSUnitPrice, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.ExtChargeAmount
                   else NULL
              end)
            )  as ACSExtChargeAmount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.DiscountAmount
                   else NULL
              end)
            )  as ACSDiscAmount,
         ((
           Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.ExtChargeAmount
                     else NULL
                end)
               ) -        
              Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.NetChargeamount
                        else NULL
                   end)
                 )
         ) * 100) / (case when Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.ExtChargeAmount
                                         else 0
                                    end)
                                  ) = 0 then 1
                          else Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.ExtChargeAmount
                                         else NULL
                                    end)
                                  )
                     end) as ACSDiscPercent,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.NetChargeamount
                   else NULL
              end)
            )  as ACSNetChargeamount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') and I.PrintFlag = 1 then II.NetChargeamount
                   else NULL
              end)
            )  as ACSBilledAmount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then II.CreditAmount
                   else NULL
              end)
            )  as ACSCreditAmount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF' and I.PrintFlag = 0) then II.NetChargeamount
                   else NULL
              end)
            )  as ACSPendingAmount,  
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then coalesce(II.Units,I.Units,OI.Units)
                   else NULL
              end)
            )  as ACSUnits, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then coalesce(II.Beds,I.Beds,OI.Beds)
                   else NULL
              end)
            )  as ACSBeds,  
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then coalesce(II.PPUPercentage,I.PPUPercentage,OI.PPUPercentage)
                   else NULL
              end)
            )  as ACSPPUPercentage,
         (select top 1 Z.Name from Products.dbo.Measure Z with (nolock) where Z.Code = 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then  II.MeasureCode 
                   else NULL
              end)
            ))  as ACSMeasure,
         (select top 1 Y.Name from Products.dbo.Frequency Y with (nolock) where Y.Code = 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ACSF') then  II.Frequencycode
                   else NULL
              end)
             ))  as ACSFrequency,
         ------------------------------------------------------------------------
         (select top 1 X.Name from Orders.dbo.Orderstatustype X with (nolock) where X.Code =
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then OI.Statuscode
                   else NULL
              end)
            ))  as ANCOrderitemstatus,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF' and II.Measurecode <> 'TRAN') then convert(varchar(50),OI.StartDate,101)
                   when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF' and II.Measurecode = 'TRAN') then convert(varchar(50),II.TransactionDate,101)
               else NULL
              end)
             ) as ANCStartDate,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF' and II.Measurecode <> 'TRAN') then convert(varchar(50),OI.EndDate,101)
                   when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF' and II.Measurecode = 'TRAN') then convert(varchar(50),II.TransactionDate,101) 
               else NULL
              end)
             ) as ANCEndDate,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then convert(varchar(50),OI.CancelDate,101)
                   else NULL
              end)
            ) as ANCCancelDate, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF' and II.PricingTiers = 1 and OG.CustomBundleNameEnabledFlag=0) 
                      then (II.ExtChargeAmount)
                   else NULL
              end)
            )/
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF' and II.PricingTiers = 1 and OG.CustomBundleNameEnabledFlag=0) 
                      then (case when II.Effectivequantity = 0 then 1 else II.Effectivequantity end)
              end)
            )   as ANCUnitPrice, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.ExtChargeAmount
                   else NULL
              end)
            )  as ANCExtChargeAmount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.DiscountAmount
                   else NULL
              end)
            )  as ANCDiscAmount,
         ((
           Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.ExtChargeAmount
                     else NULL
                end)
               ) -        
              Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.NetChargeamount
                        else NULL
                   end)
                 )
         ) * 100) / (case when Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.ExtChargeAmount
                                         else 0
                                    end)
                                  ) = 0 then 1
                          else Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.ExtChargeAmount
                                         else NULL
                                    end)
                                  )
                     end) as ANCDiscPercent,
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.NetChargeamount
                   else NULL
              end)
            )  as ANCNetChargeamount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') and I.PrintFlag = 1 then II.NetChargeamount
                   else NULL
              end)
            )  as ANCBilledAmount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then II.CreditAmount
                   else NULL
              end)
            )  as ANCCreditAmount, 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF' and I.PrintFlag = 0) then II.NetChargeamount
                   else NULL
              end)
            )  as ANCPendingAmount,           
         (select top 1 Z.Name from Products.dbo.Measure Z with (nolock) where Z.Code = 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then  II.MeasureCode 
                   else NULL
              end)
            ))  as ANCMeasure,
         (select top 1 Y.Name from Products.dbo.Frequency Y with (nolock) where Y.Code = 
         Max((Case when (II.Chargetypecode = 'ACS' and II.Reportingtypecode = 'ANCF') then  II.Frequencycode
                   else NULL
              end)
             ))  as ANCFrequency 
         -----------------------------------------------------------------------------------         
  from   Invoices.dbo.Invoice     I  with (nolock)
  inner join
         Invoices.dbo.InvoiceItem II with (nolock)
  on     I.InvoiceIDSeq  = II.InvoiceIDSeq
  and    I.MarkasPrintedFlag = 0
  and    (I.InvoiceDate   >= @InvoiceStartDate
          and    
          I.InvoiceDate   <= @InvoiceEndDate
         )
  and    I.CompanyIDSeq  = Coalesce(@CompanyID,I.CompanyIDSeq)
  and    (I.CompanyName  like '%' + @CustomerName + '%'
              OR
          I.PropertyName like '%' + @CustomerName + '%'
         )  
  inner join
         Products.dbo.Product     P  with (nolock)
  on     II.productcode = P.code
  and    II.priceversion= P.priceversion
  inner join
         Products.dbo.Platform PF with (nolock)
  on     PF.Code = P.platformcode
  and    P.platformcode = isnull(@ProductPlatformCode,P.platformcode)
  inner join
         Products.dbo.Family F with (nolock)
  on     F.Code = P.familycode
  and    P.familycode = isnull(@ProductFamilyCode,P.familycode)
  inner join
         Products.dbo.category CAT with (nolock)
  on     CAT.Code = P.categorycode
  inner join
         Orders.dbo.Orderitem OI with (nolock)
  on     II.Orderitemidseq = OI.IDSeq
  and    II.orderidseq     = OI.Orderidseq
  and    II.ordergroupidseq= OI.Ordergroupidseq
  inner join
         Orders.dbo.[Order] O  with (nolock)
  on     OI.Orderidseq = O.Orderidseq
  inner join
         Orders.dbo.Ordergroup OG with (nolock)
  on     II.orderidseq     = OG.Orderidseq
  and    II.ordergroupidseq= OG.IDSeq
  and    OI.orderidseq     = OG.Orderidseq
  and    OI.ordergroupidseq= OG.IDSeq
  and   (
         (F.Code  = coalesce(null,F.Code)  and 
          PF.Code = coalesce(null,PF.Code) and
          P.Displayname like '%' + @ProductName + '%'
         )
            OR
         (OG.CustomBundleNameEnabledFlag=1 and OG.IDSeq in (select OII.ordergroupidseq
                                                            from   Orders.dbo.Orderitem OII with (nolock)
                                                            inner join
                                                                   Products.dbo.Product PII  with (nolock)
                                                            on     OII.productcode = PII.code
                                                            and    OII.priceversion= PII.priceversion
                                                            and    PII.familycode    = coalesce(@ProductFamilyCode,PII.familycode) 
                                                            and    PII.platformcode  = coalesce(@ProductPlatformCode,PII.platformcode) 
                                                            and    PII.Displayname like '%' + @ProductName + '%'
                                                           )
         )
        )
  group by I.companyIDSeq,I.PropertyIDSeq,I.CompanyName,I.propertyname,I.InvoiceIDSeq,I.PrintFlag,
         II.OrderIDSeq,II.ordergroupidseq,(case when OG.CustomBundleNameEnabledFlag = 1 then OG.Name
                                                else P.DisplayName
                                           end),OG.CustomBundleNameEnabledFlag,
         PF.Name,F.Name, Cat.Name,
         II.productcode,P.DisplayName,II.TransactionItemName,
         II.BillingPeriodFromDate,
         II.BillingPeriodToDate,II.IDSeq 
  order by I.CompanyName asc,I.propertyname asc,           
           OG.CustomBundleNameEnabledFlag asc,
           ordergroupname asc,
           II.BillingPeriodFromDate asc,II.BillingPeriodToDate asc,
           productname asc

  ------------------------------------------------------------------------------
  Update #LT_BillingDetailsByCustomer set RecordIdentifier = (case when custombundleflag = 1 then 'CPR'
                                                         when ACSMeasure = 'Transaction' then 'TPR'
                                                         else 'APR'
                                                    end)

  Update D set D.QuoteSaleAgentName = coalesce(S.QuoteSaleAgentName,''),
               D.SalesAgentIDSeq    = S.SalesAgentIDSeq
  from   #LT_BillingDetailsByCustomer D with (nolock)
  inner join
         (select X.QuoteIDSeq,Min(X.SalesAgentName) as QuoteSaleAgentName,
                 Min(X.SalesAgentIDSeq) as SalesAgentIDSeq
          from  QUOTES.dbo.QuoteSaleAgent X with (nolock)
          where X.SalesAgentIDSeq = coalesce(@AccountManager,X.SalesAgentIDSeq)
          group by X.QuoteIDSeq
         ) S
  on    D.QuoteIDSeq = S.QuoteIDSeq
  ------------------------------------------------------------------------------
  set identity_insert #LT_BillingDetailsByCustomer on;
  ---Roll Up for Custom Bundle
  Insert into #LT_BillingDetailsByCustomer(sortseq,companyidseq,propertyidseq,companyname,propertyname,invoiceidseq,printflag,orderidseq,ordergroupidseq,ordergroupname,
  custombundleflag,platformname,familyname,categoryname,productcode,productname,
  ILFOrderitemstatus,ILFStartDate,ILFCancelDate,ILFExtChargeAmount,ILFDiscAmount,ILFDiscPercent,ILFNetChargeamount,ILFBilledAmount,ILFCreditAmount,ILFPendingAmount,
  ACSOrderitemstatus,ACSStartDate,ACSEndDate,ACSCancelDate,ACSUnitPrice,ACSExtChargeAmount,ACSDiscAmount,ACSDiscPercent,ACSNetChargeamount,ACSBilledAmount,ACSCreditAmount,ACSPendingAmount,
  ACSUnits,ACSBeds,ACSPPU,ACSMeasure,ACSFrequency,
  ANCOrderitemstatus,ANCStartDate,ANCEndDate,ANCCancelDate,ANCUnitPrice,ANCExtChargeAmount,ANCDiscAmount,ANCDiscPercent,ANCNetChargeamount,ANCBilledAmount,ANCCreditAmount,ANCPendingAmount,
  ANCMeasure,ANCFrequency,

  BillingPeriodFromDate,BillingPeriodToDate,
  QuoteIDSeq,SalesAgentIDSeq,QuoteSaleAgentName,RecordIdentifier)
  select  Min(S.sortseq) as sortseq,
          S.companyidseq,S.propertyidseq,S.companyname,S.propertyname,S.invoiceidseq,S.printflag,S.orderidseq,S.ordergroupidseq,S.ordergroupname,
          1 as custombundleflag,
          Max(S.platformname),
          'Custom Bundle' as familyname,
          'Custom Bundle' as categoryname,
          NULL productcode,
          S.ordergroupname as productname,
          --------------------------------------
          Max(S.ILFOrderitemstatus), Max(S.ILFStartDate),Max(S.ILFCancelDate),
          sum(S.ILFExtChargeAmount),sum(S.ILFDiscAmount),
          ((sum(S.ILFExtChargeAmount)-sum(S.ILFNetChargeamount))*100)/(case when sum(S.ILFExtChargeAmount)=0 then 1 else sum(S.ILFExtChargeAmount) end),
           sum(S.ILFNetChargeamount),sum(S.ILFBilledAmount),sum(S.ILFCreditAmount),sum(S.ILFPendingAmount),
         ---------------------------------------
          Max(S.ACSOrderitemstatus),Max(S.ACSStartDate),Max(S.ACSEndDate),Max(S.ACSCancelDate),
          NULL as ACSUnitPrice,sum(S.ACSExtChargeAmount),sum(S.ACSDiscAmount),
         ((sum(S.ACSExtChargeAmount)-sum(S.ACSNetChargeamount))*100)/(case when sum(S.ACSExtChargeAmount)=0 then 1 else sum(S.ACSExtChargeAmount) end),
         sum(S.ACSNetChargeamount),sum(S.ACSBilledAmount),
         sum(S.ACSCreditAmount),sum(S.ACSPendingAmount),
         Max(S.ACSUnits),Max(S.ACSBeds),Max(S.ACSPPU),
         Max(S.ACSMeasure),Max(S.ACSFrequency),
         ---------------------------------------
         Max(S.ANCOrderitemstatus),Max(S.ANCStartDate),Max(S.ANCEndDate),Max(S.ANCCancelDate),
          NULL as ANCUnitPrice,sum(S.ANCExtChargeAmount),sum(S.ANCDiscAmount),
         ((sum(S.ANCExtChargeAmount)-sum(S.ANCNetChargeamount))*100)/(case when sum(S.ANCExtChargeAmount)=0 then 1 else sum(S.ANCExtChargeAmount) end),
         sum(S.ANCNetChargeamount),sum(S.ANCBilledAmount),
         sum(S.ANCCreditAmount),sum(S.ANCPendingAmount),         
         Max(S.ANCMeasure),Max(S.ANCFrequency), 
         ---------------------------------------
         S.BillingPeriodFromDate,S.BillingPeriodToDate,
         Max(S.QuoteIDSeq),Max(S.SalesAgentIDSeq),Max(S.QuoteSaleAgentName),
         'CBB' as RecordIdentifier
  from   #LT_BillingDetailsByCustomer S with (nolock)
  where  custombundleflag = 1 and RecordIdentifier = 'CPR'
  group  by S.companyidseq,S.propertyidseq,S.companyname,S.propertyname,S.invoiceidseq,S.printflag,S.orderidseq,S.ordergroupidseq,S.ordergroupname,
            S.BillingPeriodFromDate,S.BillingPeriodToDate; 
  set identity_insert #LT_BillingDetailsByCustomer off;  
 
  Update #LT_BillingDetailsByCustomer  set    
         ILFOrderitemstatus=NULL,ILFStartDate=NULL,ILFCancelDate=NULL,ILFExtChargeAmount=NULL,ILFDiscAmount=NULL,ILFDiscPercent=NULL,
         ILFNetChargeamount=NULL,ILFBilledAmount=NULL,ILFCreditAmount=NULL,ILFPendingAmount=NULL,
         ACSOrderitemstatus=NULL,ACSStartDate=NULL,ACSEndDate=NULL,ACSCancelDate=NULL,ACSUnitPrice=NULL,ACSExtChargeAmount=NULL,ACSDiscAmount=NULL,ACSDiscPercent=NULL,
         ACSNetChargeamount=NULL,ACSBilledAmount=NULL,ACSCreditAmount=NULL,ACSPendingAmount=NULL,
         ACSUnits=NULL,ACSBeds=NULL,ACSPPU=NULL,ACSMeasure=NULL,ACSFrequency=NULL,
         ANCOrderitemstatus=NULL,ANCStartDate=NULL,ANCEndDate=NULL,ANCCancelDate=NULL,ANCUnitPrice=NULL,ANCExtChargeAmount=NULL,ANCDiscAmount=NULL,ANCDiscPercent=NULL,
         ANCNetChargeamount=NULL,ANCBilledAmount=NULL,ANCCreditAmount=NULL,ANCPendingAmount=NULL,
         ANCMeasure=NULL,ANCFrequency=NULL
  where  custombundleflag = 1 and RecordIdentifier = 'CPR'
  ------------------------------------------------------------------------------
  set identity_insert #LT_BillingDetailsByCustomer on;
  --Dummy Record for transaction
  Insert into #LT_BillingDetailsByCustomer(sortseq,companyidseq,propertyidseq,companyname,propertyname,invoiceidseq,printflag,orderidseq,ordergroupidseq,ordergroupname,
  custombundleflag,platformname,familyname,categoryname,productcode,productname,
  ILFOrderitemstatus,ILFStartDate,ILFCancelDate,ILFExtChargeAmount,ILFDiscAmount,ILFDiscPercent,ILFNetChargeamount,ILFBilledAmount,ILFCreditAmount,ILFPendingAmount,
  ACSOrderitemstatus,ACSStartDate,ACSEndDate,ACSCancelDate,ACSUnitPrice,ACSExtChargeAmount,ACSDiscAmount,ACSDiscPercent,ACSNetChargeamount,ACSBilledAmount,ACSCreditAmount,ACSPendingAmount,
  ACSUnits,ACSBeds,ACSPPU,ACSMeasure,ACSFrequency,
  ANCOrderitemstatus,ANCStartDate,ANCEndDate,ANCCancelDate,ANCUnitPrice,ANCExtChargeAmount,ANCDiscAmount,ANCDiscPercent,ANCNetChargeamount,ANCBilledAmount,ANCCreditAmount,ANCPendingAmount,
  ANCMeasure,ANCFrequency,
  BillingPeriodFromDate,BillingPeriodToDate,
  QuoteIDSeq,SalesAgentIDSeq,QuoteSaleAgentName,RecordIdentifier)
  select Min(S.sortseq) as sortseq,
         S.companyidseq,S.propertyidseq,S.companyname,S.propertyname,S.invoiceidseq,S.printflag,S.orderidseq,S.ordergroupidseq,S.ordergroupname,
         0 as custombundleflag,
         Max(S.platformname),
         Max(S.familyname)   as familyname,
         Max(S.categoryname) as categoryname,
         S.productcode,
         S.ordergroupname    as productname,
         ILFOrderitemstatus=NULL,ILFStartDate=NULL,ILFCancelDate=NULL,ILFExtChargeAmount=NULL,ILFDiscAmount=NULL,ILFDiscPercent=NULL,
         ILFNetChargeamount=NULL,ILFBilledAmount=NULL,ILFCreditAmount=NULL,ILFPendingAmount=NULL,
         ACSOrderitemstatus=NULL,ACSStartDate=NULL,ACSEndDate=NULL,ACSCancelDate=NULL,ACSUnitPrice=NULL,ACSExtChargeAmount=NULL,ACSDiscAmount=NULL,ACSDiscPercent=NULL,
         ACSNetChargeamount=NULL,ACSBilledAmount=NULL,ACSCreditAmount=NULL,ACSPendingAmount=NULL,
         ACSUnits=NULL,ACSBeds=NULL,ACSPPU=NULL,ACSMeasure=NULL,ACSFrequency=NULL,
         ANCOrderitemstatus=NULL,ANCStartDate=NULL,ANCEndDate=NULL,ANCCancelDate=NULL,ANCUnitPrice=NULL,ANCExtChargeAmount=NULL,ANCDiscAmount=NULL,ANCDiscPercent=NULL,
         ANCNetChargeamount=NULL,ANCBilledAmount=NULL,ANCCreditAmount=NULL,ANCPendingAmount=NULL,
         ANCMeasure=NULL,ANCFrequency=NULL, 
         S.BillingPeriodFromDate,S.BillingPeriodToDate, 
         Max(S.QuoteIDSeq),Max(S.SalesAgentIDSeq),Max(S.QuoteSaleAgentName),
         'TDB' as RecordIdentifier
  from   #LT_BillingDetailsByCustomer S with (nolock)
  where  custombundleflag = 0 and RecordIdentifier = 'TPR'
  group  by S.companyidseq,S.propertyidseq,S.companyname,S.propertyname,S.invoiceidseq,S.printflag,S.orderidseq,S.ordergroupidseq,S.ordergroupname,S.productcode,
            S.BillingPeriodFromDate,S.BillingPeriodToDate;
  set identity_insert #LT_BillingDetailsByCustomer off;   
   --------------------------------------------------------------------------
   --Final Select to Report
   -------------------------------------------------------------------------- 
   select 
          (case when s.recordidentifier not in ('CPR','TPR') then coalesce(companyname,'')  else '' end)						as [Company Name],
--          (case when s.recordidentifier not in ('CPR','TPR') then coalesce(propertyname,'') else '' end)						as [Property Name],
          (case when s.recordidentifier not in ('CPR','TPR') then coalesce(accountname,'') else '' end)							as [Account Name],
          (case when acsunits is null then '' else acsunits end)																as Units,
          (case when acsbeds is null then '' else acsbeds end)																	as Beds,
          (case when acsppu is null then '' else acsppu end)																	as PPU, 
          (case when s.recordidentifier not in ('CPR','TPR') then coalesce(orderidseq,'')   else '' end)						as [Order ID],
          coalesce(productname,'')																								as [Product Name],
          ---------------------------------------------
          coalesce(ilforderitemstatus,'')																						as [ILF OrderItem Status],
          Convert(datetime,ilfstartdate)																						as [ILF Start Date],
          Convert(datetime,ilfcanceldate)																						as [ILF Cancel Date],
          convert(numeric(10,2),ilfextchargeamount)																		        as [ILF List Amount],
          convert(numeric(10,2),ilfdiscamount)																	                as [ILF Disc Amount],
          convert(numeric(10,2),ilfdiscpercent)																                    as [ILF Disc Percent],
          convert(numeric(10,2),ilfnetchargeamount)																			    as [ILF NetCharge Amount],
          convert(numeric(10,2),ilfbilledamount)																				as [ILF Billed Amount],
          convert(numeric(10,2),ilfcreditamount)																			    as [ILF Credit Amount],
          convert(numeric(10,2),ilfpendingamount)																				as [ILF Pending Amount],
          ---------------------------------------------
          coalesce(acsorderitemstatus,'')																						as [ACS OrderItem Status],
          (case when acsenddate is not null then (acsstartdate + ' - ' + acsenddate)
                  else ''
           end)																													as [ACS Period],
          Convert(datetime,acscanceldate)																						as [ACS Cancel Date],
          coalesce(acsmeasure,'')																								as [ACS Measure],
          coalesce(acsfrequency,'')																								as [ACS Frequency],
          convert(numeric(10,2),acsunitprice)													                                as [ACS Unit Price],
          convert(numeric(10,2),acsextchargeamount)																			    as [ACS List Amount],
          convert(numeric(10,2),acsdiscamount)																					as [ACS Disc Amount],
          convert(numeric(10,2),acsdiscpercent)																				    as [ACS Disc Percent],
          convert(numeric(10,2),acsnetchargeamount)																				as [ACS NetCharge Amount],
          convert(numeric(10,2),acsbilledamount)																				as [ACS Billed Amount],
          convert(numeric(10,2),acscreditamount)																				as [ACS Credit Amount],
          convert(numeric(10,2),acspendingamount)																				as [ACS Pending Amount],
          ---------------------------------------------
          coalesce(ancorderitemstatus,'')																						as [ANC OrderItem Status],
          (case when ancenddate is not null then (ancstartdate + ' - ' + ancenddate)
                else ''
          end)																													as [ANC Period],
          Convert(datetime,anccanceldate)																						as [ANC Cancel Date],
          coalesce(ancmeasure,'')																								as [ANC Measure],
          coalesce(ancfrequency,'')																								as [ANC Frequency],
          convert(numeric(10,2),ancunitprice)														                            as [ANC Unit Price],
          convert(numeric(10,2),ancextchargeamount)																				as [ANC List Amount],
          convert(numeric(10,2),ancdiscamount)																					as [ANC Disc Amount],
          convert(numeric(10,2),ancdiscpercent)																					as [ANC Disc Percent],
          convert(numeric(10,2),ancnetchargeamount)																				as [ANC NetCharge Amount],
          convert(numeric(10,2),ancbilledamount)																				as [ANC Billed Amount],
          convert(numeric(10,2),anccreditamount)																				as [ANC Credit Amount],
          convert(numeric(10,2),ancpendingamount)																				as [ANC Pending Amount],
          ---------------------------------------------   
          (case when s.recordidentifier not in ('CPR','TPR') then (billingperiodfromdate + ' - ' + billingperiodtodate) else '' end) as [Billing Period],
		  (case when s.recordidentifier in ('TDB') then null
                  else  (convert(numeric(30,2),coalesce(ilfpendingamount,0))+ convert(numeric(30,2),coalesce(acspendingamount,0))+ convert(numeric(30,2),coalesce(ancpendingamount,0)))
           end)                                                                                                                 as [Total Pending Amount],
          (case when s.recordidentifier not in ('CPR','TPR') then coalesce(quotesaleagentname,'') else '' end)                  as [Account Manager],
                     
          ---------------------------------------------
          (case when s.recordidentifier in ('CBB','TDB') then 'Header'
                else 'Detail'
           end)																													as InternalRecordIdentifier
  from    #LT_BillingDetailsByCustomer S with (nolock)
  where   S.SalesAgentIDSeq = coalesce(@AccountManager,S.SalesAgentIDSeq)  
  order by sortseq asc,RecordIdentifier asc
  -------------------------------------------------------------------------- 
  --Final CleanUp
  if (object_id('tempdb.dbo.#LT_BillingDetailsByCustomer') is not null) 
  begin
    drop table #LT_BillingDetailsByCustomer
  end 
  -------------------------------------------------------------------------- 
          
END 
GO
