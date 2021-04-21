SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : uspORDERS_Rep_GetBillingDetailsByCategoryNEW      
-- Description     : This procedure gets Billing Details based on Customer. And this is based on the Excel File 'Billings Detail ByCustomer.xls'     
-- Input Parameters: Except @IPDT_OrderStartDate and @IPDT_OrderEndDate other Input parameters are optional
--            
-- Code Example    : Exec [dbo].[uspORDERS_Rep_GetBillingDetailsByCategoryNEW] '','','','','07/20/2008','09/20/2008'
--       
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 08/08/2007      : Stored Procedure Created.      
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_GetBillingDetailsByCategoryNEW]      
                                                                  (      
                                                                    @IPVC_CompanyID           varchar(20)  ='',
                                                                    @IPVC_CustomerName        varchar(100) ='',                                                                    
                                                                    @IPVC_AccountManager      varchar(255) ='',
                                                                    @IPDT_InvoiceStartDate    Datetime     ,
                                                                    @IPDT_InvoiceEndDate      Datetime     ,
                                                                    @IPVC_ProductName         varchar(255) ='',
                                                                    @IPVC_ProductFamilyCode   varchar(5)   ='',
                                                                    @IPVC_ProductPlatformcode varchar(5)   =''
                                                                  )      
AS      
BEGIN         
  SET NOCOUNT ON;   
  ------------------------------------------------------------
  set @IPVC_CompanyID           = nullif(@IPVC_CompanyID,'');  
  set @IPVC_AccountManager      = nullif(@IPVC_AccountManager,'');
  set @IPVC_ProductFamilyCode   = nullif(@IPVC_ProductFamilyCode,'');
  set @IPVC_ProductPlatformcode = nullif(@IPVC_ProductPlatformcode,'');
  ------------------------------------------------------------
  create table #LT_BillingDetails(sortseq                int not null identity(1,1),
                                  companyidseq           varchar(50),
                                  propertyidseq          varchar(50),
                                  companyname            varchar(500),
                                  propertyname           varchar(500),
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
                                  ILFStartDate           varchar(50),
                                  ILFCancelDate          varchar(50),
                                  ILFExtChargeAmount     numeric(30,2),
                                  ILFDiscAmount          numeric(30,2),
                                  ILFDiscPercent         numeric(30,5),
                                  ILFNetChargeamount     numeric(30,2),
                                  ILFBilledAmount        numeric(30,2),
                                  ILFCreditAmount        numeric(30,2),
                                  ILFPendingAmount       numeric(30,2),
                                  -------------------------------------
                                  ACSOrderitemstatus     varchar(100),
                                  ACSStartDate           varchar(50),
                                  ACSEndDate             varchar(50),
                                  ACSCancelDate          varchar(50),
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
                                  ANCStartDate           varchar(50),
                                  ANCEndDate             varchar(50),
                                  ANCCancelDate          varchar(50),
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
  Insert into #LT_BillingDetails(companyidseq,propertyidseq,companyname,propertyname,invoiceidseq,printflag,
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
         II.OrderIDSeq,II.ordergroupidseq,(case when OG.CustomBundleNameEnabledFlag = 1 then OG.Name
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
  and    (I.InvoiceDate   >= @IPDT_InvoiceStartDate
          and    
          I.InvoiceDate   <= @IPDT_InvoiceEndDate
         )
  and    I.CompanyIDSeq  = Coalesce(@IPVC_CompanyID,I.CompanyIDSeq)
  and    (I.CompanyName  like '%' + @IPVC_CustomerName + '%'
              OR
          I.PropertyName like '%' + @IPVC_CustomerName + '%'
         )  
  inner join
         Products.dbo.Product     P  with (nolock)
  on     II.productcode = P.code
  and    II.priceversion= P.priceversion
  inner join
         Products.dbo.Platform PF with (nolock)
  on     PF.Code = P.platformcode
  inner join
         Products.dbo.Family F with (nolock)
  on     F.Code = P.familycode
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
         (P.familycode  = coalesce(@IPVC_ProductFamilyCode,P.familycode)     and 
          P.platformcode= coalesce(@IPVC_ProductPlatformcode,P.platformcode) and
          P.Displayname like '%' + @IPVC_ProductName + '%'
          )
            OR
         (OG.CustomBundleNameEnabledFlag=1 and OG.IDSeq in (select OII.ordergroupidseq
                                                            from   Orders.dbo.Orderitem OII with (nolock)
                                                            inner join
                                                                   Products.dbo.Product PII  with (nolock)
                                                            on     OII.productcode = PII.code
                                                            and    OII.priceversion= PII.priceversion
                                                            and    PII.familycode    = coalesce(@IPVC_ProductFamilyCode,PII.familycode) 
                                                            and    PII.platformcode  = coalesce(@IPVC_ProductPlatformcode,PII.platformcode) 
                                                            and    PII.Displayname like '%' + @IPVC_ProductName + '%'
                                                           )
         )
        )
  group by I.companyIDSeq,I.PropertyIDSeq,I.CompanyName,I.propertyname,I.InvoiceIDSeq,I.PrintFlag,
         II.OrderIDSeq,II.ordergroupidseq,(case when OG.CustomBundleNameEnabledFlag = 1 then OG.Name
                                                else P.DisplayName
                                           end),OG.CustomBundleNameEnabledFlag,
         PF.Name,(case when OG.CustomBundleNameEnabledFlag = 1 then 'Custom Bundle' else F.Name end),
                 (case when OG.CustomBundleNameEnabledFlag = 1 then 'Custom Bundle' else Cat.Name end),
         II.productcode,P.DisplayName,II.TransactionItemName,
         II.BillingPeriodFromDate,
         II.BillingPeriodToDate 
  order by 
           (case when OG.CustomBundleNameEnabledFlag = 1 then 'Custom Bundle' else F.Name end)   asc,
           (case when OG.CustomBundleNameEnabledFlag = 1 then 'Custom Bundle' else Cat.Name end) asc,
           I.CompanyName asc,I.propertyname asc,           
           OG.CustomBundleNameEnabledFlag desc,
           ordergroupname asc,
           II.BillingPeriodFromDate asc,II.BillingPeriodToDate asc,
           productname asc

  ------------------------------------------------------------------------------
  Update #LT_BillingDetails set RecordIdentifier = (case when custombundleflag = 1 then 'CPR'
                                                         when ACSMeasure = 'Transaction' then 'TPR'
                                                         else 'APR'
                                                    end)

  Update D set D.QuoteSaleAgentName = coalesce(S.QuoteSaleAgentName,''),
               D.SalesAgentIDSeq    = S.SalesAgentIDSeq
  from   #LT_BillingDetails D with (nolock)
  inner join
         (select X.QuoteIDSeq,Min(X.SalesAgentName) as QuoteSaleAgentName,
                 Min(X.SalesAgentIDSeq) as SalesAgentIDSeq
          from  QUOTES.dbo.QuoteSaleAgent X with (nolock)
          where X.SalesAgentIDSeq = coalesce(@IPVC_AccountManager,X.SalesAgentIDSeq)
          group by X.QuoteIDSeq
         ) S
  on    D.QuoteIDSeq = S.QuoteIDSeq
  ------------------------------------------------------------------------------
  set identity_insert #LT_BillingDetails on;
  ---Roll Up for Custom Bundle
  Insert into #LT_BillingDetails(sortseq,companyidseq,propertyidseq,companyname,propertyname,invoiceidseq,printflag,orderidseq,ordergroupidseq,ordergroupname,
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
  from   #LT_BillingDetails S with (nolock)
  where  custombundleflag = 1 and RecordIdentifier = 'CPR'
  group  by S.companyidseq,S.propertyidseq,S.companyname,S.propertyname,S.invoiceidseq,S.printflag,S.orderidseq,S.ordergroupidseq,S.ordergroupname,
            S.BillingPeriodFromDate,S.BillingPeriodToDate; 
  set identity_insert #LT_BillingDetails off;  
 
  Update #LT_BillingDetails  set    
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
  set identity_insert #LT_BillingDetails on;
  --Dummy Record for transaction
  Insert into #LT_BillingDetails(sortseq,companyidseq,propertyidseq,companyname,propertyname,invoiceidseq,printflag,orderidseq,ordergroupidseq,ordergroupname,
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
  from   #LT_BillingDetails S with (nolock)
  where  custombundleflag = 0 and RecordIdentifier = 'TPR'
  group  by S.companyidseq,S.propertyidseq,S.companyname,S.propertyname,S.invoiceidseq,S.printflag,S.orderidseq,S.ordergroupidseq,S.ordergroupname,S.productcode,
            S.BillingPeriodFromDate,S.BillingPeriodToDate;
  set identity_insert #LT_BillingDetails off;   
   --------------------------------------------------------------------------
--select * from #LT_BillingDetails
--return
   ---Final Select for the Report
   -------------------------------------------------------------------------- 
   select 
          (case when S.RecordIdentifier not in ('CPR','TPR') then platformname else NULL end)  as platformname,
          (case when S.RecordIdentifier not in ('CPR','TPR') then familyname else NULL end)    as familyname,
          (case when S.RecordIdentifier not in ('CPR','TPR') then categoryname else NULL end)  as categoryname,        
          (case when S.RecordIdentifier not in ('CPR','TPR') then companyname else NULL end)   as companyname,
          (case when S.RecordIdentifier not in ('CPR','TPR') then propertyname else NULL end)  as propertyname,
          (case when S.RecordIdentifier not in ('CPR','TPR') then orderidseq else NULL end)    as orderidseq,
          coalesce(productname,'')                                                            as productname,
          ---------------------------------------------
          coalesce(ILFOrderitemstatus,'')                                                            as ILFOrderitemstatus,
          coalesce(ILFStartDate,'')                                                                  as ILFStartDate,
          coalesce(ILFCancelDate,'')                                                                 as ILFCancelDate,
          (case when ILFExtChargeAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ILFExtChargeAmount,1,2) end)            as ILFListAmount,
          (case when ILFDiscAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ILFDiscAmount,1,2) end)                      as ILFDiscAmount,
          (case when ILFDiscPercent is null then '' else convert(varchar(50),ILFDiscPercent)  end)                                as ILFDiscPercent,
          (case when ILFNetChargeamount is null then '' else ORDERS.DBO.fn_FormatCurrency(ILFNetChargeamount,1,2) end)            as ILFNetChargeamount,
          (case when ILFBilledAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ILFBilledAmount,1,2) end)                  as ILFBilledAmount,
          (case when ILFCreditAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ILFCreditAmount,1,2) end)                  as ILFCreditAmount,
          (case when ILFPendingAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ILFPendingAmount,1,2) end)                as ILFPendingAmount,
          ---------------------------------------------
          coalesce(ACSOrderitemstatus,'')                                                            as ACSOrderitemstatus,
          (case when ACSEndDate is not null then (ACSStartDate + ' - ' + ACSEndDate)
                  else ''
           end)                                                                                      as ACSPeriod,
          coalesce(ACSCancelDate,'')                                                                 as ACSCancelDate,
          (case when ACSUnits is null then '' else ACSUnits end)                                     as Units,
          (case when ACSBeds is null then '' else ACSBeds end)                                       as Beds,
          (case when ACSPPU is null then '' else ACSPPU end)                                         as PPU,
          coalesce(ACSMeasure,'')                                                                    as ACSMeasure,
          coalesce(ACSFrequency,'')                                                                  as ACSFrequency,
          (case when ACSUnitPrice is null then '' else convert(varchar(50),ACSUnitPrice) end)                                     as ACSUnitPrice,
          (case when ACSExtChargeAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ACSExtChargeAmount,1,2) end)            as ACSListAmount,
          (case when ACSDiscAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ACSDiscAmount,1,2) end)                      as ACSDiscAmount,
          (case when ACSDiscPercent is null then '' else convert(varchar(50),ACSDiscPercent) end)                                 as ACSDiscPercent,
          (case when ACSNetChargeamount is null then '' else ORDERS.DBO.fn_FormatCurrency(ACSNetChargeamount,1,2) end)            as ACSNetChargeamount,
          (case when ACSBilledAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ACSBilledAmount,1,2) end)                  as ACSBilledAmount,
          (case when ACSCreditAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ACSCreditAmount,1,2) end)                  as ACSCreditAmount,
          (case when ACSPendingAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ACSPendingAmount,1,2) end)                as ACSPendingAmount,
          ---------------------------------------------
          coalesce(ANCOrderitemstatus,'')                                                            as ANCOrderitemstatus,
          (case when ANCEndDate is not null then (ANCStartDate + ' - ' + ANCEndDate)
                else ''
          end)                                                                                       as ANCPeriod,
          coalesce(ANCCancelDate,'')                                                                 as ANCCancelDate,
          coalesce(ANCMeasure,'')                                                                    as ANCMeasure,
          coalesce(ANCFrequency,'')                                                                  as ANCFrequency,
          (case when ANCUnitPrice is null then '' else convert(varchar(50),ANCUnitPrice) end)                                     as ANCUnitPrice,
          (case when ANCExtChargeAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ANCExtChargeAmount,1,2) end)            as ANCListAmount,
          (case when ANCDiscAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ANCDiscAmount,1,2) end)                      as ANCDiscAmount,
          (case when ANCDiscPercent is null then '' else convert(varchar(50),ANCDiscPercent) end)                                 as ANCDiscPercent,
          (case when ANCNetChargeamount is null then '' else ORDERS.DBO.fn_FormatCurrency(ANCNetChargeamount,1,2) end)            as ANCNetChargeamount,
          (case when ANCBilledAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ANCBilledAmount,1,2) end)                  as ANCBilledAmount,
          (case when ANCCreditAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ANCCreditAmount,1,2) end)                  as ANCCreditAmount,
          (case when ANCPendingAmount is null then '' else ORDERS.DBO.fn_FormatCurrency(ANCPendingAmount,1,2) end)                as ANCPendingAmount,
          ---------------------------------------------   
          (case when S.RecordIdentifier in ('TDB') then ''
                  else  ORDERS.DBO.fn_FormatCurrency((coalesce(ILFPendingAmount,0)+ coalesce(ACSPendingAmount,0)+coalesce(ANCPendingAmount,0)),1,2) 
           end)                                                                                                                      as TotalPendingAmount,
          (case when S.RecordIdentifier not in ('CPR','TPR') then coalesce(QuoteSaleAgentName,'') else '' end)                       as AccountManager,
          (case when S.RecordIdentifier not in ('CPR','TPR') then (BillingPeriodFromDate + ' - ' + BillingPeriodToDate) else '' end) as BillingPeriod,           
          ---------------------------------------------
          (case when S.RecordIdentifier in ('CBB','TDB') then 'Header'
                else 'Detail'
           end) as InternalRecordIdentifier
  from    #LT_BillingDetails S with (nolock)
  where   S.SalesAgentIDSeq = coalesce(@IPVC_AccountManager,S.SalesAgentIDSeq)  
  --and (RecordIdentifier in ('APR') or RecordIdentifier in ('CBB','CPR'))
  --and RecordIdentifier in ('APR')
  --and RecordIdentifier in ('CBB','CPR')
  --and RecordIdentifier in ('TDB','TPR')
  order by sortseq asc,RecordIdentifier asc
  --------------------------------------------------------------------------          
END 
GO
