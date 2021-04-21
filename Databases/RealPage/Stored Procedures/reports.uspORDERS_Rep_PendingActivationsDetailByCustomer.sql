SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : uspORDERS_Rep_PendingActivationsDetailByCustomer      
-- Description     : This procedure gets Billing Details based on Customer. And this is based on the Excel File NewOrdersPendingActivationsDetailbyCustomer.xls     
-- Input Parameters: Optional except @IPD_StartDate and @IPD_EndDate
-- Code Example    : Exec [dbo].[uspORDERS_Rep_PendingActivationsDetailByCustomer] 
--                                      @IPD_StartDate = '12/01/2009' ,@IPD_EndDate = '12/31/2009', @IPVC_CompanyID = '',@IPVC_CustomerName = '',
--					@IPC_AccountID = '',@IPC_PropertyID = '',@IPVC_PlatformCode = '',@IPVC_FamilyCode = '',@IPVC_ProductName = '',
--					@IPI_AccountManager = '',
--					@IPI_CreatedBy      = ''
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 07/24/2007      : Stored Procedure Created.
-- 01/03/2008	   : Naval Kishore Modified Datatypes
-- 04/26/2010      : Naval Kishore Modified to get CreatedByUserName, Defect # 7759 	      
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_PendingActivationsDetailByCustomer] (@IPD_StartDate      datetime     = '',
                                                                           @IPD_EndDate        datetime     = '',
                                                                           @IPVC_CompanyID     varchar(50)  = '',
                                                                           @IPVC_CustomerName  varchar(100) = '',
                                                                           @IPC_AccountID      varchar(50)  = '',
                                                                           @IPC_PropertyID     varchar(50)  = '',
                                                                           @IPVC_PlatformCode  varchar(3)   = '',
                                                                           @IPVC_FamilyCode    varchar(3)   = '',
                                                                           @IPVC_ProductName   varchar(255) = '',
                                                                           @IPI_CreatedBy      varchar(255) = ''
                                                                          )      
As      
BEGIN -->Main BEGIN         
  Set nocount on;   
  --------------------------------------------------------------------------
  set @IPVC_CompanyID     = nullif(@IPVC_CompanyID,'')
  set @IPVC_CustomerName  = ltrim(rtrim(@IPVC_CustomerName))
  set @IPC_AccountID      = nullif(@IPC_AccountID,'')
  set @IPC_PropertyID     = nullif(@IPC_PropertyID,'')
  set @IPVC_PlatformCode  = nullif(@IPVC_PlatformCode,'')
  set @IPVC_FamilyCode    = nullif(@IPVC_FamilyCode,'')
  set @IPVC_ProductName   = ltrim(rtrim(@IPVC_ProductName))
  set @IPI_CreatedBy      = nullif(@IPI_CreatedBy,'')  
 ---------------------------------------------------------------------------------
 -- Retrieving Required Column Details into the table Variable @LT_TempOrderDetail
 ----------------------------------------------------------------------------------
  select Max(C.Name)                                                      as CompanyName,
         Max(coalesce(P.Name,C.Name))                                     as PropertyName,
         OI.OrderIDSeq                                                    as OrderIDSeq,
         Max(PRD.DisplayName)                                             as ProductName,
         OI.ChargeTypeCode                                                as [Type],
         convert(datetime,convert(varchar(50),Max(O.CreatedDate),101))    as OrderDate,
         sum(OI.Netchargeamount)                                          as Net,
         sum(OI.NetExtYear1ChargeAmount)                                  as AnnualizedNet,
         OI.MeasureCode                                                   as MeasureCode,
         Max(FR.Name)                                                     as [Access Frequency],
         Min(Coalesce(Q.CreatedByDisplayName,ModifiedByDisplayName))      as ClientServiceRep,
         ''                                                               as ProductManager,
         customers.dbo.fnGetUserNamefromID(@IPI_CreatedBy)                as CreatedByName
  from   Orders.dbo.[Order]     O with (nolock)
  inner join
         Orders.dbo.[OrderItem] OI with (nolock)
  on     O.Orderidseq   = OI.Orderidseq
  and    convert(datetime,convert(varchar(50),OI.createddate,101)) >= @IPD_StartDate
  and    convert(datetime,convert(varchar(50),OI.createddate,101)) <= @IPD_EndDate
  and    O.AccountIDSeq = coalesce(@IPC_AccountID,O.AccountIDSeq)
  and    OI.StatusCode  =  'PEND'
  and    OI.MeasureCode <> 'TRAN'
  and    isdate(OI.StartDate) = 0
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
         Customers.dbo.Company C with (nolock)
  on     O.CompanyIDSeq   = C.IDSeq 
  and    O.CompanyIDSeq   = coalesce(@IPVC_CompanyID,O.CompanyIDSeq)
  and    C.IDSeq          = coalesce(@IPVC_CompanyID,C.IDSeq)
  and    C.Name           like '%' + @IPVC_CustomerName + '%'
  and    coalesce(O.PropertyIDSeq,'0') = coalesce(@IPC_PropertyID,coalesce(O.PropertyIDSeq,'0'))
  Left Outer join
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
  group by O.CompanyIDSeq,O.PropertyIDSeq,O.AccountIDSeq,OI.OrderIDSeq,OI.IDSeq,OI.ChargeTypeCode,OI.MeasureCode,OI.FrequencyCode
  order by CompanyName ASC,PropertyName ASC,ProductName ASC,OI.OrderIDSeq ASC
  
END -->Main END
GO
