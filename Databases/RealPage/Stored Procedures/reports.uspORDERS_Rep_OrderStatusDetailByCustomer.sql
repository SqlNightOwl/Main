SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : [uspORDERS_Rep_OrderStatusDetailByCustomer]      
-- Description     : This procedure gets Billing Details based on Customer. And this is based on the Excel File NewOrdersPendingActivationsDetailbyCustomer.xls     
-- Input Parameters: Optional except @IPD_StartDate and @IPD_EndDate
-- Code Example    : Exec [dbo].[uspORDERS_Rep_OrderStatusDetailByCustomer] 
--                                      @IPD_StartDate = '12/01/2009' ,@IPD_EndDate = '12/31/2009', @IPVC_CompanyID = '',@IPVC_CustomerName = '',
--					@IPC_AccountID = '',@IPC_PropertyID = '',@IPVC_PlatformCode = '',@IPVC_FamilyCode = '',@IPVC_ProductName = '',
--					@IPI_AccountManager = '',
--					@IPI_CreatedBy      = ''
--                   Exec [dbo].[uspORDERS_Rep_OrderStatusDetailByCustomer]  @IPD_StartDate='02/01/2010',@IPD_EndDate='02/28/2010'
-- Revision History:      
-- Author          : Naval Kishore      
-- 06/02/2010      : Stored Procedure Created.
-- 09/28/2010      : Naval Kishore Modified to get Quotetype, Quoteid and Renewal class. Defect # 8391. 
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_OrderStatusDetailByCustomer]        (@IPD_StartDate      datetime     = '',
                                                                           @IPD_EndDate        datetime     = '',
                                                                           @IPVC_CompanyID     varchar(50)  = '',
                                                                           @IPVC_CustomerName  varchar(100) = '',
                                                                           @IPC_AccountID      varchar(50)  = '',
                                                                           @IPC_PropertyID     varchar(50)  = '',
                                                                           @IPVC_PlatformCode  varchar(3)   = '',
                                                                           @IPVC_FamilyCode    varchar(3)   = '',
                                                                           @IPVC_ProductName   varchar(255) = '',
                                                                           @IPI_CreatedBy      varchar(255) = '',
                                                                           @IPVC_StatusCode    varchar(50)  = ''
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
  set @IPI_CreatedBy      = nullif(@IPI_CreatedBy,'')    ---> This is UserIDSeq of User.
  set @IPVC_StatusCode    = nullif(@IPVC_StatusCode,'')

  declare @LVC_UserName   varchar(100)
  select @LVC_UserName = customers.dbo.fnGetUserNamefromID(@IPI_CreatedBy)
 ---------------------------------------------------------------------------------
 -- Retrieving Required Column Details into the table Variable @LT_TempOrderDetail
 ----------------------------------------------------------------------------------
  -- Since we are listing by OrderitemIDSeq, introducing a group by clause removes the need for Expensive Distinct clause.
  select   O.CompanyIDSeq,O.PropertyIDSeq,
         Max(C.Name)                                                      as CompanyName,
         Max(C.SitemasterID)                                              as CompanySitemasterID,
         Max(coalesce(P.Name,C.Name))                                     as PropertyName,
         O.AccountIDSeq                                                   as AccountIDSeq,     
         Max(coalesce(P.SitemasterID,C.SitemasterID))                     as PropertySitemasterID,
         OI.OrderIDSeq                                                    as OrderIDSeq,
         Max(PRD.DisplayName)                                             as ProductName,
         OI.ChargeTypeCode                                                as [Type],
         convert(varchar(50),Max(OI.CreatedDate),101)                     as OrderDate,	
         OI.MeasureCode                                                   as MeasureCode,
         Max(FR.Name)                                                     as [Frequency],
         MAX(X.Name)                                                      as [Status],
         (convert(varchar(50),MAX(OI.StartDate),101))                     as ContractStartDate,
         (convert(varchar(50),MAX(OI.EndDate),101))                       as ContractEndDate,
         convert(varchar(50),Max(coalesce(OI.ModifiedDate,OI.CreatedDate)),101) 
                                                                          as ModifiedDate, 
         Min(coalesce(customers.dbo.fnGetUserNamefromID(OI.ModifiedByUserIDSeq),
                      customers.dbo.fnGetUserNamefromID(OI.CancelByIDSeq),
                      customers.dbo.fnGetUserNamefromID(OU.IDSeq),
                      customers.dbo.fnGetUserNamefromID(OI.RenewedByUserIDSeq),
                      'MIS Admin-Migrated Order/Renewal From Migrated Order'
                     )                                  
            )                                                             as ClientServiceRep,
         customers.dbo.fnGetUserNamefromID(@IPI_CreatedBy)                as CreatedByName, -- to be provided on SRS report
         Max(PLFT.Name)                                                   as PlatformName,
         Max(FMLY.Name)                                                   as FamilyName,
         Max(CAT.Name)                                                    as CategoryName,
         Max(OI.ProductCODE)                                              as ProductCode,
         MAx(OI.PriceVersion)                                             as PriceVersion,
		 Min(COALESCE(Q.QuoteIDSeq,'Migrated'))							  as QuoteIDSeq,
         Min(COALESCE(QT.Name,'N/A'))									  as QuoteTypeCode,
		 Max((CASE WHEN (OI.RenewalCount <> 0 and OI.MasterOrderItemIDSeq is null) 
		       THEN 'Renewal Migrated Order'
			   WHEN (OI.RenewalCount = 0 and OI.MasterOrderItemIDSeq is null) 
		       THEN 'Master Contract Order'      
			   WHEN  (OI.RenewalCount > 0 and OI.MasterOrderItemIDSeq is not null)  
			   THEN 'Renewal Order count : ' + convert(varchar(50),RenewalCount)
			   ELSE 'N/A'
		   END))														  as RenewalClass

  from   Orders.dbo.[Order]     O with (nolock)
  inner join
         Orders.dbo.[OrderItem] OI with (nolock)
  on     O.Orderidseq   = OI.Orderidseq
  and    OI.StatusCode  = coalesce(@IPVC_StatusCode,OI.StatusCode)
  and    OI.MeasureCode <> 'TRAN'   --> These are Tran Enabler Records orders which are autofulfilled by the system internally.
  and    convert(datetime,convert(varchar(50),coalesce(OI.ModifiedDate,OI.CreatedDate),101)) >= @IPD_StartDate
  and    convert(datetime,convert(varchar(50),coalesce(OI.ModifiedDate,OI.CreatedDate),101)) <= @IPD_EndDate
  Left outer Join
         Security.dbo.[User] OU with (nolock)
  on     OU.FirstName + ' ' + OU.LastName = coalesce(nullif(O.CreatedBy,''),O.ApprovedBy) collate SQL_Latin1_General_CP850_CI_AI
  inner join
         Orders.dbo.OrderGroup OG with (nolock)
  on     O.Orderidseq = OG.OrderIDSeq
  and    OI.Orderidseq = OG.OrderIDSeq
  and    OI.OrderGroupIDSeq = OG.IDSeq
  inner join
         Products.dbo.Product PRD with (nolock)
  on     OI.ProductCode   = PRD.Code
  and    OI.Priceversion  = PRD.PriceVersion
  and    PRD.FamilyCode   = coalesce(@IPVC_FamilyCode,PRD.FamilyCode)
  and    PRD.PlatFormCode = coalesce(@IPVC_PlatformCode,PRD.PlatFormCode)
  and    PRD.Displayname like '%' + @IPVC_ProductName + '%'
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
         Orders.dbo.OrderStatusType X with (nolock)
  on     X.Code = OI.StatusCode
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
  left outer join
         Customers.dbo.Property P with (nolock)
  on     O.PropertyIDSeq = P.IDSeq
  Left outer join
       Quotes.dbo.Quote Q with (nolock)
		on     O.Quoteidseq = Q.QuoteIdSeq
		and    O.CompanyIDSeq= Q.CustomerIDSeq
		Left Outer Join
			   Quotes.dbo.QuoteType QT with (nolock)
		on     Q.Quotetypecode = QT.Code

  where  (@IPI_CreatedBy is null 
              OR
          coalesce(OI.ModifiedByUserIDSeq,OI.CancelByIDSeq,OU.IDSeq,OI.RenewedByUserIDSeq,'0') = coalesce(@IPI_CreatedBy,OI.ModifiedByUserIDSeq,OI.CancelByIDSeq,OU.IDSeq,OI.RenewedByUserIDSeq,'0')
         )
  group by O.CompanyIDSeq,O.PropertyIDSeq,O.AccountIDSeq,OI.OrderIDSeq,OI.IDSeq,OI.ChargeTypeCode,OI.MeasureCode,OI.FrequencyCode
  order by CompanyName ASC,PropertyName ASC,ProductName ASC,OI.OrderIDSeq ASC
  
END -->Main END
GO
