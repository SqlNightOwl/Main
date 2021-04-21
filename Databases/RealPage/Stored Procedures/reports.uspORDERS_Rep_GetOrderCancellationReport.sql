SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------- 
-- procedure   : uspORDERS_Rep_GetOrderCancellationReport
-- server      : OMS
-- Database    : ORDERS
 
-- purpose     :  This procedure gets all cancelled order for the passed Input parameters
-- Input Parameters: 1. @IPDT_FromDate  as DateTime
--                   2. @IPDT_ToDate  as DateTime 
--
-- returns     : resultset as below

-- Example of how to call this stored procedure:
-- EXEC ORDERS.dbo.uspORDERS_Rep_GetOrderCancellationReport @IPVC_FromDate = '01/01/2007', @IPVC_ToDate = '05/31/2009',@IPVC_FamilyCode = 'CFR'

-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2009-June-11	SRS  	        Initial creation
-- 2010-June-29	ShashiBhushan  	Defect#7753 - Modified to Remove comma in CancelledbyUser column as per kemi's comments in QC
-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
----------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspORDERS_Rep_GetOrderCancellationReport] (@IPVC_FromDate     varchar(20) ='',
                                                                   @IPVC_ToDate       varchar(20) ='',
                                                                   @IPVC_CompanyID    varchar(50) ='',
                                                                   @IPVC_PropertyID   varchar(50) ='',
                                                                   @IPVC_AccountID    varchar(50) ='',
                                                                   @IPVC_CompanyName  varchar(255)='',
                                                                   @IPVC_PropertyName varchar(255)='',
                                                                   @IPVC_ProductName  varchar(255)='',
                                                                   @IPVC_FamilyCode   varchar(255)=''                                                                   
                                                                   ) 
AS
BEGIN
  set nocount on;
  declare @LDT_FromDate datetime,
          @LDT_ToDate   datetime
  
  ------------------------------------------------------
  select @IPVC_CompanyID = nullif(@IPVC_CompanyID,''),
         @IPVC_PropertyID= nullif(@IPVC_PropertyID,''),
         @IPVC_AccountID = nullif(@IPVC_AccountID,''),
         @IPVC_FamilyCode= nullif(@IPVC_FamilyCode,'')

  if isdate(@IPVC_FromDate)=0 
  begin
    select @LDT_FromDate = '01/01/1900'
  end
  else
  begin
    select @LDT_FromDate = convert(datetime,@IPVC_FromDate)
  end

  if isdate(@IPVC_ToDate)=0 
  begin
    select @LDT_ToDate = '12/31/2099'
  end
  else
  begin
    select @LDT_ToDate = convert(datetime,@IPVC_ToDate)
  end
  
  ------------------------------------------------------
  --Get Results for cancellation report
  Select O.CompanyIDSeq        as CompanyID,
         Max(C.Name)           as CompanyName,
         O.PropertyIDSeq       as PropertyID,
         Max(PRP.Name)         as PropertyName,
         O.AccountIDSeq        as AccountID,
         Max(coalesce(NULLIF(Q.QuoteIDSeq,''),'Siebel System')) as OrginationQuoteID,
         Max(coalesce(QT.Name,''))                              as OrginationQuoteType,
         OI.OrderIDSeq         as OrderIDSeq,
         OI.IDSeq              as OrderItemIDSeq,
         Max((Case when OG.CustombundleNameEnabledFlag=1 
                    then OG.Name 
                   else ''
              end)
            )                  as CustomBundleName,
         Max((Case when OG.CustombundleNameEnabledFlag=1 
                    then 'Yes' 
                   else 'No'
              end)
            )                   as IsCustomBundle,
         Max(OI.ProductCode)    as ProductCode,
         Max(PRD.DisplayName)   as ProductName,
         Max(OI.RenewalCount)   as RenewalNumber,
         Max(OI.ChargeTypeCode) as ChargeTypeCode,
         Max(OI.MeasureCode)    as MeasureCode,
         Max(FRQ.Name)          as Frequency,
         Max(OI.NetChargeAmount)         as NetChargeAmount,
         Max(OI.NetExtYear1ChargeAmount) as AnnualizedNetChargeAmount,
         convert(varchar(20),Max(OI.StartDate),101)     as ContractStartDate,
         convert(varchar(20),Max(OI.EndDate),101)       as ContractEndDate,
         convert(varchar(20),Max(OI.Canceldate),101)    as ContractCancelDate,
         Max(coalesce(CRT.ReasonName,'Not Captured'))       as CancelReason,
         Max(coalesce(OI.CancelNotes,''))               as UserCancelNotes,
         Max(coalesce(U.FirstName+' '+U.LastName,'Not Captured'))
                                              as CancelledbyUser,
         Max(coalesce(Convert(varchar(50),OI.ModifiedDate,22),'Not Captured')) as CancelledOnByUserDate      

  from   Orders.dbo.[Order]   O  with (nolock)
  inner join
         Orders.dbo.OrderItem OI with (nolock)
  on     O.OrderIDSeq = OI.OrderIDSeq
  and    OI.StatusCode   = 'CNCL'  
  and    convert(datetime,convert(varchar(50),coalesce(OI.ModifiedDate,OI.Createddate,OI.Canceldate),101)) >= @LDT_FromDate
  and    convert(datetime,convert(varchar(50),coalesce(OI.ModifiedDate,OI.Createddate,OI.Canceldate),101)) <= @LDT_ToDate
  and    O.AccountIDSeq  = Coalesce(@IPVC_AccountID,O.AccountIDSeq)
  and    O.CompanyIDSeq  = Coalesce(@IPVC_CompanyID,O.CompanyIDSeq)
  and    coalesce(O.PropertyIDSeq,'0') = Coalesce(@IPVC_PropertyID,coalesce(O.PropertyIDSeq,'0'))  
  inner join
         Orders.dbo.OrderGroup OG with (nolock)
  on     OG.Orderidseq = O.Orderidseq
  and    OG.Orderidseq = OI.Orderidseq
  and    OG.IDSeq      = OI.OrderGroupIDSeq
  and    OI.StatusCode   = 'CNCL'
  inner join
         Products.dbo.Product PRD with (nolock)
  on     OI.Productcode  = PRD.Code
  and    OI.PriceVersion = PRD.PriceVersion
  and    PRD.DisplayName like '%' + @IPVC_ProductName + '%' 
  inner join
         Products.dbo.Family F with (nolock)
  on     PRD.FamilyCode = F.Code
  and    F.Code         = coalesce(@IPVC_FamilyCode,F.Code)
  inner join
         Products.dbo.Frequency FRQ with (nolock)
  on     OI.FrequencyCode = FRQ.Code
  inner join
         Customers.dbo.Company C with (nolock)
  on     O.CompanyIDSeq = C.IDSeq
  and    C.IDSeq        = Coalesce(@IPVC_CompanyID,C.IDSeq)
  and    C.Name like '%' + @IPVC_CompanyName + '%'
  left outer join
         Customers.dbo.Property PRP with (nolock)
  on     O.PropertyIDSeq = PRP.IDSeq
  and    coalesce(PRP.Name,C.Name) like '%' + @IPVC_PropertyName + '%' 
  left outer join
         Orders.dbo.Reason CRT with (nolock)
  on     OI.CancelReasonCode = CRT.Code
  left outer join
         Security.dbo.[User] U with (nolock)
  on     OI.CancelByIDSeq = U.IDSeq
  left outer join
         Quotes.dbo.Quote Q with (nolock)
  on     O.QuoteIDSeq = Q.QuoteIDSeq
  left outer join 
         Quotes.dbo.QuoteType QT with (nolock)
  on     Q.QuoteTypeCode = QT.Code
  where  C.Name                    like '%' + @IPVC_CompanyName  + '%'
  and    coalesce(PRP.Name,C.Name) like '%' + @IPVC_PropertyName + '%'
  /*
  and    O.AccountIDSeq  = Coalesce(@IPVC_AccountID,O.AccountIDSeq)
  and    O.CompanyIDSeq  = Coalesce(@IPVC_CompanyID,O.CompanyIDSeq)
  and    coalesce(O.PropertyIDSeq,'') = Coalesce(@IPVC_PropertyID,coalesce(O.PropertyIDSeq,'')) 
  and    PRD.DisplayName like '%' + @IPVC_ProductName  + '%'
  and    F.Code         = coalesce(@IPVC_FamilyCode,F.Code) 
  */
  -----------------------------------
  group by O.CompanyIDSeq,O.PropertyIDSeq,O.AccountIDSeq,OI.OrderIDSeq,OI.IDSeq
  -----------------------------------
  Order by CompanyName asc,PropertyName asc,OrderIDSeq asc,RenewalNumber asc,
           CustomBundleName asc,ProductName asc,Chargetypecode asc
END
GO
