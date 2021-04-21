SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS       
-- Procedure Name  : [uspORDERS_Rep_PendingActivationsAgingSummary]      
-- Description     : This procedure gets Pending Activations for different time periods. 
--					 And this is based on the Excel File 'NewOrdersPendingActivationsAgingSummary.xls'
-- Input Parameters: Optional except @IPDT_CurrentDate  
-- Code Example    : Exec ORDERS.[dbo].[uspORDERS_Rep_PendingActivationsAgingSummary] '12/31/2009'
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 08/08/2007      : Stored Procedure Created.  
-- 03/18/2010      : Shashi Bhushan     #7574 - Need to work on the New Orders Pending Activations Aging Summary report   
-- 03/25/2010      : Shashi Bhushan     #7574 - Fixed wrong calculation of variance
-- 04/26/2010      : Naval Kishore Modified to get CreatedByUserName, Defect # 7759 
------------------------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_PendingActivationsAgingSummary] (@IPDT_CurrentDate   datetime     = '',
                                                                       @IPVC_CompanyID     varchar(50)  = '',
                                                                       @IPVC_CustomerName  varchar(100) = '',
                                                                       @IPC_AccountID      varchar(50)  = '',
                                                                       @IPC_PropertyID     varchar(50)  = '',
                                                                       @IPVC_PlatformCode  varchar(3)   = '',
                                                                       @IPVC_FamilyCode    varchar(3)   = '',
                                                                       @IPVC_ProductName   varchar(255) = '',
                                                                       @IPI_AccountManager bigint       = '',
                                                                       @IPI_CreatedBy      bigint       = ''
                                                                       )      
As      
BEGIN --> Main BEGIN
  Set nocount on  
  --------------------------------------------------------------------------
  set @IPVC_CompanyID     = nullif(@IPVC_CompanyID,'')
  set @IPVC_CustomerName  = ltrim(rtrim(@IPVC_CustomerName))
  set @IPC_AccountID      = nullif(@IPC_AccountID,'')
  set @IPC_PropertyID     = nullif(@IPC_PropertyID,'')
  set @IPVC_PlatformCode  = nullif(@IPVC_PlatformCode,'')
  set @IPVC_FamilyCode    = nullif(@IPVC_FamilyCode,'')
  set @IPVC_ProductName   = ltrim(rtrim(@IPVC_ProductName))
  set @IPI_CreatedBy      = nullif(@IPI_CreatedBy,'')  
  set @IPI_AccountManager = nullif(@IPI_AccountManager,'') -- Not used
  ---------------------------------------------------------------------------------
  Declare @LT_FinalOrderAgeSummary Table (sortseq                    bigint not null identity(1,1) primary key,
                                          PlatformName               varchar(50),
                                          FamilyName                 varchar(50),
                                          CategoryName               varchar(70),
                                          ---------------------------------------
                                          AccPend_30_Orders          bigint,
                                          AccPend_30_OrderValue      numeric(18,2) null default 0.00,
                                          ---------------------------------------
                                          TotVal_30_Orders           bigint,
                                          TotVal_30_OrderValue       numeric(18,2) null default 0.00,
                                          Var_30_Orders              as convert(numeric(18,2),(convert(float,AccPend_30_OrderValue) * 100)
                                                                                               /
                                                                                              (case when TotVal_30_OrderValue = 0 then 1 else convert(float,TotVal_30_OrderValue) end)
                                                                               ),
                                          ---------------------------------------
                                          AccPend_30to90_Orders      bigint,
                                          AccPend_30to90_OrderValue  numeric(18,2) null default 0.00,
                                          ---------------------------------------
                                          TotVal_30to90_Orders       bigint,
                                          TotVal_30to90_OrderValue   numeric(18,2) null default 0.00,
                                          Var_30to90_Orders          as convert(numeric(18,2),(convert(float,AccPend_30to90_OrderValue) * 100)
                                                                                               /
                                                                                              (case when TotVal_30to90_OrderValue = 0 then 1 else convert(float,TotVal_30to90_OrderValue) end)
                                                                               ),
                                          ---------------------------------------
                                          AccPend_Above90_Orders     bigint,
                                          AccPend_Above90_OrderValue numeric(18,2) null default 0.00,
                                          ---------------------------------------
                                          TotVal_Above90_Orders      bigint,
                                          TotVal_Above90_OrderValue  numeric(18,2) null default 0.00,
                                          Var_Above90_Orders         as convert(numeric(18,2),(convert(float,AccPend_Above90_OrderValue) * 100)
                                                                                               /
                                                                                              (case when TotVal_Above90_OrderValue = 0 then 1 else convert(float,TotVal_Above90_OrderValue) end)
                                                                                ),
                                          ---------------------------------------
                                          AccPend_Total              bigint,
                                          AccPendValue_Total         numeric(18,2) null default 0.00,
                                          ---------------------------------------
                                          TotalNum_total             bigint,
                                          TotalValue_Total           numeric(18,2) null default 0.00,
                                          Total_Var                  as convert(numeric(18,2),(convert(float,AccPendValue_Total) * 100)
                                                                                               /
                                                                                              (case when TotalValue_Total = 0 then 1 else convert(float,TotalValue_Total) end)
                                                                                ),
										  CreatedByName              varchar(100)
                                          
                                          );
  ---------------------------------------------------------------------------------
  Insert into @LT_FinalOrderAgeSummary(PlatformName,FamilyName,CategoryName,
                                       AccPend_30_Orders,AccPend_30_OrderValue,
                                       TotVal_30_Orders,TotVal_30_OrderValue,
                                       ---------
                                       AccPend_30to90_Orders,AccPend_30to90_OrderValue,
                                       TotVal_30to90_Orders,TotVal_30to90_OrderValue,                                       
                                       ---------
                                       AccPend_Above90_Orders,AccPend_Above90_OrderValue,
                                       TotVal_Above90_Orders,TotVal_Above90_OrderValue,                                       
                                       ---------
                                       AccPend_Total,AccPendValue_Total,
                                       TotalNum_total,TotalValue_Total,CreatedByName
                                      )
  select S.PlatformName,S.FamilyName,S.CategoryName,
         sum((case when S.bucket = '00-30' then S.PENDbucketcount else 0 end))              as AccPend_30_Orders,
         sum((case when S.bucket = '00-30' then S.PENDAnnualizedbucketvalue else 0 end))    as AccPend_30_OrderValue,
         sum((case when S.bucket = '00-30' then S.Totalbucketcount else 0 end))             as TotVal_30_Orders,
         sum((case when S.bucket = '00-30' then S.TotalAnnualizedbucketvalue else 0 end))   as TotVal_30_OrderValue,
         ---------
         sum((case when S.bucket = '31-90' then S.PENDbucketcount else 0 end))              as AccPend_30to90_Orders,
         sum((case when S.bucket = '31-90' then S.PENDAnnualizedbucketvalue else 0 end))    as AccPend_30to90_OrderValue,
         sum((case when S.bucket = '31-90' then S.Totalbucketcount else 0 end))             as TotVal_30to90_Orders,
         sum((case when S.bucket = '31-90' then S.TotalAnnualizedbucketvalue else 0 end))   as TotVal_30to90_OrderValue,
         ---------
         sum((case when S.bucket = '91-900' then S.PENDbucketcount else 0 end))             as AccPend_Above90_Orders,
         sum((case when S.bucket = '91-900' then S.PENDAnnualizedbucketvalue else 0 end))   as AccPend_Above90_OrderValue,
         sum((case when S.bucket = '91-900' then S.Totalbucketcount else 0 end))            as TotVal_Above90_Orders,
         sum((case when S.bucket = '91-900' then S.TotalAnnualizedbucketvalue else 0 end))  as TotVal_Above90_OrderValue,
         ---------
         sum((case when S.bucket = '00-30'  then S.PENDbucketcount else 0 end)) +
         sum((case when S.bucket = '31-90'  then S.PENDbucketcount else 0 end)) + 
         sum((case when S.bucket = '91-900' then S.PENDbucketcount else 0 end))              as AccPend_Total,

         sum((case when S.bucket = '00-30'  then S.PENDAnnualizedbucketvalue else 0 end)) +
         sum((case when S.bucket = '31-90'  then S.PENDAnnualizedbucketvalue else 0 end)) +
         sum((case when S.bucket = '91-900' then S.PENDAnnualizedbucketvalue else 0 end))    as AccPendValue_Total,

         sum((case when S.bucket = '00-30'  then S.Totalbucketcount else 0 end)) +
         sum((case when S.bucket = '31-90'  then S.Totalbucketcount else 0 end)) +
         sum((case when S.bucket = '91-900' then S.Totalbucketcount else 0 end))             as TotalNum_total,

         sum((case when S.bucket = '00-30'  then S.TotalAnnualizedbucketvalue else 0 end)) +
         sum((case when S.bucket = '31-90'  then S.TotalAnnualizedbucketvalue else 0 end)) +
         sum((case when S.bucket = '91-900' then S.TotalAnnualizedbucketvalue else 0 end))   as TotalValue_Total,
		 customers.dbo.fnGetUserNamefromID(@IPI_CreatedBy)									 as CreatedByName
  from
      (          
       select Max(PLFT.Name)                                                   as PlatformName,
              Max(FMLY.Name)                                                   as FamilyName,
              Max(CAT.Name)                                                    as CategoryName,         
              (case when (datediff(day,convert(datetime,convert(varchar(50),OI.createddate,101)),@IPDT_CurrentDate) between 0  and 30)  then '00-30'
                    when (datediff(day,convert(datetime,convert(varchar(50),OI.createddate,101)),@IPDT_CurrentDate) between 31 and 90)  then '31-90'
                    when (datediff(day,convert(datetime,convert(varchar(50),OI.createddate,101)),@IPDT_CurrentDate) >= 91)              then '91-900'
                    else '0'
               end)                                                            as bucket,
               sum(OI.NetExtYear1ChargeAmount)                                 as TotalAnnualizedbucketvalue,
               count(OI.IDSeq)                                                 as Totalbucketcount,
               sum(case when OI.StatusCode = 'PEND' 
                          then OI.NetExtYear1ChargeAmount
                        else  0
                   end)                                                        as PENDAnnualizedbucketvalue,
               sum(case when OI.StatusCode = 'PEND' 
                          then 1
                        else 0  
                   end)                                                        as PENDbucketcount
    from   Orders.dbo.[Order]     O with (nolock)
    inner join
           Orders.dbo.[OrderItem] OI with (nolock)
    on     O.Orderidseq   = OI.Orderidseq  
    and    O.AccountIDSeq = coalesce(@IPC_AccountID,O.AccountIDSeq)  
    and    OI.MeasureCode <> 'TRAN' 
    and    OI.StatusCode  <> 'CNCL'  
    and    (datediff(day,convert(datetime,convert(varchar(50),OI.createddate,101)),@IPDT_CurrentDate)) >= 0
    /*and    exists (select top 1 1 from Orders.dbo.[OrderItem] OIX with (nolock)
                   where  OIX.OrderIDSeq = OI.OrderIDSeq
                   and    OIX.ChargetypeCode    = 'ACS'
                   and    OIX.StatusCode        <> 'CNCL' 
                   --and    isdate(OIX.StartDate) = 0
                   ) 
    */ 
    inner join
           Products.dbo.Product PRD with (nolock)
    on     OI.ProductCode   = PRD.Code
    and    OI.Priceversion  = PRD.PriceVersion
    and    PRD.FamilyCode   = coalesce(@IPVC_FamilyCode,PRD.FamilyCode)
    and    PRD.PlatFormCode = coalesce(@IPVC_PlatformCode,PRD.PlatFormCode)
    and    PRD.Displayname like '%' + @IPVC_ProductName + '%'
    inner join
           Products.dbo.Frequency FR with (nolock)
    on     OI.FrequencyCode = FR.Code
    inner join
           Products.dbo.PlatForm PLFT with (nolock)
    on     PRD.PlatformCode = PLFT.Code
    and    PRD.PlatFormCode = coalesce(@IPVC_PlatformCode,PRD.PlatFormCode)
    and    PLFT.Code        = coalesce(@IPVC_PlatformCode,PLFT.Code)
    inner join
           Products.dbo.Family FMLY with (nolock)
    on     PRD.FamilyCode = FMLY.Code
    and    PRD.FamilyCode = coalesce(@IPVC_FamilyCode,PRD.FamilyCode)
    and    FMLY.Code      = coalesce(@IPVC_FamilyCode,FMLY.Code)
    inner join
           Products.dbo.Category CAT with (nolock)
    on     PRD.CategoryCode = CAT.Code  
    inner join
           Customers.dbo.Company C with (nolock)
    on     O.CompanyIDSeq   = C.IDSeq 
    and    O.CompanyIDSeq   = coalesce(@IPVC_CompanyID,O.CompanyIDSeq)
    and    C.IDSeq          = coalesce(@IPVC_CompanyID,C.IDSeq)
    and    C.Name           like '%' + @IPVC_CustomerName + '%'
    and    coalesce(O.PropertyIDSeq,'0') = coalesce(@IPC_PropertyID,coalesce(O.PropertyIDSeq,'0'))
    Left outer join
           Quotes.dbo.Quote Q with (nolock)
    on     O.QuoteIDSeq = Q.Quoteidseq
    and    (@IPI_CreatedBy is null 
               OR
            Q.CreatedByIDSeq = @IPI_CreatedBy
           )
    left outer join
           Customers.dbo.Property P with (nolock)
    on     O.PropertyIDSeq = P.IDSeq
    where  (@IPI_CreatedBy is null 
              OR
            Q.CreatedByIDSeq = @IPI_CreatedBy
           )
    group by PLFT.Name,FMLY.Name,CAT.Name,
            (case when (datediff(day,convert(datetime,convert(varchar(50),OI.createddate,101)),@IPDT_CurrentDate) between 0  and 30)  then '00-30'
                  when (datediff(day,convert(datetime,convert(varchar(50),OI.createddate,101)),@IPDT_CurrentDate) between 31 and 90)  then '31-90'
                  when (datediff(day,convert(datetime,convert(varchar(50),OI.createddate,101)),@IPDT_CurrentDate) >= 91)              then '91-900'
                  else '0'
            end)
  ) S
  group by  S.PlatformName,S.FamilyName,S.CategoryName
  order by  S.PlatformName ASC,S.FamilyName ASC,S.CategoryName ASC
  --------------------------------------------------------------------
  ---Final Select to SRS Report
  --------------------------------------------------------------------
  select PlatformName,FamilyName,CategoryName,
         AccPend_30_Orders,AccPend_30_OrderValue,
         TotVal_30_Orders,TotVal_30_OrderValue,
         ---------
         AccPend_30to90_Orders,AccPend_30to90_OrderValue,
         TotVal_30to90_Orders,TotVal_30to90_OrderValue,                                       
         ---------
         AccPend_Above90_Orders,AccPend_Above90_OrderValue,
         TotVal_Above90_Orders,TotVal_Above90_OrderValue,                                       
         ---------
         AccPend_Total,AccPendValue_Total,
         TotalNum_total,TotalValue_Total,
         Total_Var,CreatedByName
  from @LT_FinalOrderAgeSummary
  order by SortSeq asc;
  --------------------------------------------------------------------
END
GO
