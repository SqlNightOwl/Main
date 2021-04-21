SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES    
-- Procedure Name  : [uspQUOTES_Rep_QuotesSummaryAndDetail]      
-- Description     : This procedure gets Quote Summary and Details. And this is based on the Excel File 'Quotes Summary and Detail.xls'     
-- Input Parameters: Optional except @IPD_StartDate and @IPD_EndDate
-- Code Example    : Exec [dbo].[uspQUOTES_Rep_QuotesSummaryAndDetail]  '','','02/25/2009','08/05/2009' 
--					 Exec [dbo].[uspQUOTES_Rep_QuotesSummaryAndDetail]  @IPD_StartDate='01/1/2008',@IPD_EndDate='08/16/2009',@IPVC_QuoteType='NEWQ'
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 07/24/2007      : Stored Procedure Created.   
-- 02/18/2009      : Naval Kishore Modified to add @IPVC_QuoteType parameter, Defect #5999. 
-- 07/27/2009      : Naval Kishore Modified to get columns Created Date, Expiration Date, Submitted Date, Approval Date
-- 04/13/2011      : Naval Kishore Modified to get column ApprovedBy, Defect #9123.    
-- 05/16/2011      : Mahaboob Modified to include ApprovalStartDate and ApprovalEndDate parameters Defect #241
-- 10/17/2011      : Mahaboob Modified to get DealDeskDecision and DealDeskActionDate columns. TFS #709
------------------------------------------------------------------------------------------------------      
Create Procedure [reports].[uspQUOTES_Rep_QuotesSummaryAndDetail]      
                                                (
						 @IPVC_Quoteid       varchar(22)  = '',
						 @IPVC_CompanyID     CHAR(11)     = '',
						 @IPD_StartDate      datetime     = '',
						 @IPD_EndDate        datetime     = '',
						 @IPVC_PlatformCode  varchar(3)   = '',
						 @IPVC_FamilyCode    varchar(3)   = '',
						 @IPVC_CategoryCode  varchar(3)   = '',
						 @IPVC_ProductName   varchar(255) = '',
						 @IPC_QuoteStatus    varchar(4)   = '',
						 @IPVC_CustomerName  varchar(100) = '',
						 @IPC_AccountID      varchar(50)  = '',
						 @IPC_PropertyID     varchar(50)  = '',
						 @IPI_AccountManager bigint       = '',
						 @IPI_CreatedBy      bigint       = '',  
						 @IPVC_QuoteType     varchar(4)   = '',
					     @IPD_ApprovalStartDate datetime  = '',  
					     @IPD_ApprovalEndDate   datetime  = ''    
                                                )
as      
BEGIN         
  set nocount on;
  -----------------------------------------------------------
  create table #Temp_Rep_SalesAgent (QuoteIDSeq		    varchar(22),
                                     SalesAgentName         varchar(100)
                                    )   
  -----------------------------------------------------------
  SET @IPVC_Quoteid       = nullif(@IPVC_Quoteid,'')
  SET @IPVC_PlatformCode  = nullif(@IPVC_PlatformCode,'')
  SET @IPVC_FamilyCode    = nullif(@IPVC_FamilyCode,'')
  SET @IPVC_CategoryCode  = nullif(@IPVC_CategoryCode,'')
  SET @IPVC_ProductName   = @IPVC_ProductName
  SET @IPC_QuoteStatus    = nullif(@IPC_QuoteStatus,'')
  SET @IPVC_CustomerName  = @IPVC_CustomerName
  SET @IPVC_CompanyID     = nullif(@IPVC_CompanyID,'')
  SET @IPC_AccountID      = nullif(@IPC_AccountID,'')
  SET @IPC_PropertyID     = nullif(@IPC_PropertyID,'')
  SET @IPI_AccountManager = nullif(@IPI_AccountManager,'')
  SET @IPI_CreatedBy      = nullif(@IPI_CreatedBy,'')
  SET @IPVC_QuoteType      = nullif(@IPVC_QuoteType,'')

  select @IPD_StartDate   = convert(datetime,convert(varchar(50),@IPD_StartDate,101))
  select @IPD_EndDate     = convert(datetime,convert(varchar(50),@IPD_EndDate,101))+1
	
  IF( @IPD_ApprovalStartDate = '' OR @IPD_ApprovalEndDate = '')
  BEGIN
		SET @IPD_ApprovalStartDate = ''
		SET @IPD_ApprovalEndDate = ''
  END

  IF( @IPD_ApprovalStartDate <> '' AND @IPD_ApprovalEndDate <> '')
  BEGIN
		SET @IPC_QuoteStatus = 'APR'
		select @IPD_ApprovalStartDate   = convert(datetime,convert(varchar(50),@IPD_ApprovalStartDate,101))
		select @IPD_ApprovalEndDate     = convert(datetime,convert(varchar(50),@IPD_ApprovalEndDate,101))+1
  END
 
  SET @IPD_ApprovalStartDate = nullif(@IPD_ApprovalStartDate, '')
  SET @IPD_ApprovalEndDate   = nullif(@IPD_ApprovalEndDate, '')

  -----------------------------------------------------------      
  -- An AccountID when passed and not null, will belong either to a company
  -- or property. Hence the following Select will suffice.
  IF (@IPC_AccountID is not null and @IPC_AccountID <> '')
  BEGIN
    SELECT @IPVC_CompanyID = A.CompanyIDSeq,
	   @IPC_PropertyID = A.PropertyIDSeq
    FROM   Customers.dbo.Account A WITH (NOLOCK)
    WHERE  A.IDSeq         = @IPC_AccountID
  END
  -----------------------------------------------------------
  insert into #Temp_Rep_SalesAgent(QuoteIDSeq,SalesAgentName)
  select X.Quoteidseq,Min(Coalesce(X.SalesAgentName,''))   as SalesAgentName
  From   QUOTES.dbo.QuoteSaleAgent X with (nolock)
  where  X.SalesAgentIDSeq =  coalesce(@IPI_AccountManager,X.SalesAgentIDSeq)
  group by X.Quoteidseq
  -----------------------------------------------------------  
  SELECT DISTINCT 
				Q.QuoteIDSeq                          AS QuoteIDSeq,
				QS.Name                               AS [Status],
--				(case when Q.QuoteStatusCode = 'APR' then convert(datetime,convert(varchar(50),Max(Q.ApprovalDate),101))
--                                      when Q.QuoteStatusCode = 'SUB' then convert(datetime,convert(varchar(50),Max(Q.SubmittedDate),101))
--                                      when Q.QuoteStatusCode = 'CNL' then convert(datetime,convert(varchar(50),Max(Q.ModifiedDate),101))
--                                      else convert(datetime,convert(varchar(50),Max(Q.CreateDate),101))
--                                end)                                                                          as ExpirationDate,
				 Max(Q.CreateDate)							 					       as CreatedDate,
				 Max(Q.SubmittedDate)											       as SubmittedDate,
				 Max(Q.ApprovalDate)											       as ApprovalDate,
				 Max(Q.ModifiedDate)				                            	   as ModifiedDate,
				 Max(Q.ExpirationDate)                                                 as ExpirationDate,
				COM.Name,
				max(Q.Sites)                                                                  as Sites,
				max(Q.Units)                                                                  as Units,
				convert(numeric(30,2),(max(Q.ILFNetExtYearChargeAmount)+max(Q.AccessNetExtYear1ChargeAmount))) AS TotalValue,
				convert(numeric(30,2),max(Q.ILFExtYearChargeAmount))        AS ILF_List,
				convert(numeric(30,2),max(Q.ILFDiscountPercent))            AS ILF_DiscPercent,
				convert(numeric(30,2),max(Q.ILFDiscountAmount))             AS ILF_DiscAmount,
				convert(numeric(30,2),max(Q.ILFNetExtYearChargeAmount))     AS ILF_NetAmount,
				convert(numeric(30,2),max(Q.AccessExtYear1ChargeAmount))    AS ACS_List,
				convert(numeric(30,2),max(Q.AccessYear1DiscountPercent))    AS ACS_DiscPercent,
				convert(numeric(30,2),max(Q.AccessYear1DiscountAmount))     AS ACS_DiscAmount,
				convert(numeric(30,2),max(Q.AccessNetExtYear1ChargeAmount)) AS ACS_NetAmount_Year1,
				convert(numeric(30,2),max(Q.AccessNetExtYear2ChargeAmount)) AS ACS_NetAmount_Year2,
				convert(numeric(30,2),max(Q.AccessNetExtYear3ChargeAmount)) AS ACS_NetAmount_Year3,
				Min(Coalesce(QSA.SalesAgentName,''))                        AS AccountManager,
				customers.dbo.fnGetUserNamefromID(max(Q.CreatedByIDSeq))    AS ClientServiceRep,
				customers.dbo.fnGetUserNamefromID(max(Q.ModifiedByIDSeq))   AS ApprovedBy,  
			    QT.Name                                                     AS QuoteType,
				DQS.Name														AS DealDeskDecision,
				coalesce(max(Q.DealDeskResolvedDate), max(Q.DealDeskQueuedDate))      AS DealDeskActionDate  
  from   QUOTES.dbo.Quote       Q   with (nolock)
  inner join  
         Quotes.dbo.QuoteType QT with (nolock)  
  on     Q.QuoteTypeCode = QT.Code  
  and    Q.QuoteTypeCode = isnull(@IPVC_QuoteType,Q.QuoteTypeCode) 

  inner join
         CUSTOMERS.dbo.Company  COM with (nolock)
  on     Q.CustomerIDSeq = COM.IDSeq
  and    Q.QuoteIDSeq    = coalesce(@IPVC_Quoteid,Q.Quoteidseq)
  and    coalesce(Q.CreatedByIDSeq,'')= coalesce(@IPI_CreatedBy,coalesce(Q.CreatedByIDSeq,''))
  and    Q.QuoteStatusCode = coalesce(@IPC_QuoteStatus,Q.QuoteStatusCode)
  and    Q.CustomerIDSeq = coalesce(@IPVC_CompanyID,Q.CustomerIDSeq)
  and    COM.IDSeq       = coalesce(@IPVC_CompanyID,COM.IDSeq)
  and    COM.Name        like '%' + @IPVC_CustomerName + '%'
  and     (
            --------------------------------------------------
           (
            (@IPC_QuoteStatus = 'NSU' or @IPC_QuoteStatus is null or @IPC_QuoteStatus = '')
                       and
             convert(datetime,convert(varchar(50),Q.CreateDate,101)) >= @IPD_StartDate 
                       and
             convert(datetime,convert(varchar(50),Q.CreateDate,101)) < @IPD_EndDate
            )
           --------------------------------------------------
                       OR   
           (       
            (@IPC_QuoteStatus = 'SUB') 
                       and
             convert(datetime,convert(varchar(50),Q.SubmittedDate,101)) >= @IPD_StartDate 
                       and
             convert(datetime,convert(varchar(50),Q.SubmittedDate,101)) < @IPD_EndDate
            )
           --------------------------------------------------
                       OR        
           (  
            (@IPC_QuoteStatus = 'APR') 
                       and
             convert(datetime,convert(varchar(50),Q.ApprovalDate,101)) >= coalesce(@IPD_ApprovalStartDate, @IPD_StartDate) 
                       and
             convert(datetime,convert(varchar(50),Q.ApprovalDate,101)) <  coalesce(@IPD_ApprovalEndDate, @IPD_EndDate) 
            ) 
           --------------------------------------------------
                       OR      
           (    
            (@IPC_QuoteStatus = 'CNL') 
                       and
             convert(datetime,convert(varchar(50),Q.ModifiedDate,101)) >= @IPD_StartDate 
                       and
             convert(datetime,convert(varchar(50),Q.ModifiedDate,101)) < @IPD_EndDate
            ) 
           --------------------------------------------------
         )
  inner join
         Quotes.dbo.QuoteStatus QS with (nolock)
  on     Q.QuoteStatusCode = QS.Code
  and    Q.QuoteStatusCode = coalesce(@IPC_QuoteStatus,Q.QuoteStatusCode)
  and    QS.Code           = coalesce(@IPC_QuoteStatus,QS.Code)
  and    exists (select Top 1 1 
                 from   QUOTES.dbo.Quoteitem QI with (nolock)
                 inner join
                        Products.dbo.Product  PRD with (nolock)
                 on     QI.Quoteidseq  = Q.Quoteidseq
                 and    QI.Productcode = PRD.Code
                 and    QI.priceversion= PRD.priceversion
                 and    PRD.PlatformCode = coalesce(@IPVC_PlatformCode, PRD.PlatformCode)
                 and    PRD.FamilyCode   = coalesce(@IPVC_FamilyCode,   PRD.FamilyCode)
                 and    PRD.CategoryCode = coalesce(@IPVC_CategoryCode, PRD.CategoryCode)
                 and    PRD.DisplayName  like '%' + @IPVC_ProductName + '%'
				 and ((@IPC_PropertyID is null) or EXISTS(select 1 from Quotes..GroupProperties GP (nolock)     
								where GP.QuoteIDSeq=Q.QuoteIDSeq and GP.PropertyIDSeq= @IPC_PropertyID)) 
				 and ((@IPI_AccountManager is null) or EXISTS(select 1 from  Quotes..QuoteSaleAgent QSA (nolock)  
								where QSA.QuoteIDSeq=Q.QuoteIDSeq and QSA.SalesAgentIDSeq = @IPI_AccountManager))  
                )  
  left outer join
         #Temp_Rep_SalesAgent QSA
  on    Q.Quoteidseq = QSA.Quoteidseq 
  left outer join
         Quotes.dbo.QuoteStatus DQS with (nolock)
  on     Q.DealDeskStatusCode = DQS.Code

  Group by Q.QuoteIDSeq,Q.QuoteStatusCode,QS.Name,
           COM.IDSeq,COM.Name,QT.Name, DQS.Name
  Order by COM.Name,Q.QuoteIDSeq
END

--exec uspQUOTES_Rep_QuotesSummaryAndDetail @IPVC_QuoteID='',@IPC_QuoteStatus=N'',@IPVC_CompanyID=N'',@IPD_StartDate='2009-07-01',@IPD_EndDate='2009-07-27',@IPVC_PlatformCode=N'',@IPVC_FamilyCode=N'',@IPVC_CategoryCode=N'',@IPVC_ProductName=N'',@IPVC_CustomerName=N'',@IPC_AccountID=N'',@IPC_PropertyID=N'',@IPI_AccountManager=N'',@IPI_CreatedBy=N''
GO
