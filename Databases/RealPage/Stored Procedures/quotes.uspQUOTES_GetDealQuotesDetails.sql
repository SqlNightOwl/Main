SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES       
-- Procedure Name  : [uspQUOTES_GetDealQuotesDetails]      
-- Description     : This procedure gets Deal Sheet Quote Details based on Customer and other input parameters. 

-- Input Parameters: Optional
-- Code Example    : Exec Quotes.dbo.[uspQUOTES_GetDealQuotesDetails] 'C0000018367','Q0000002581',1,'','','','','',''
--					Exec Quotes.dbo.[uspQUOTES_GetDealQuotesDetails] 'C0000018367','Q0000002581',2,'','','','','','Q0000002579'
--					Exec Quotes.dbo.[uspQUOTES_GetDealQuotesDetails] 'C0000018367','Q0000002581',3,'','','','','',''
-- Revision History:      
-- Author          : Shashi Bhushan      
-- 09/03/2007      : Stored Procedure Created.    
------------------------------------------------------------------------------------------------------      
Create Procedure [quotes].[uspQUOTES_GetDealQuotesDetails] 
(
@IPC_CompanyID     char(11),
 @IPVC_QuoteID      varchar(22)  = '',
 @QFlag				int,
 @IPVC_QuoteDesc    varchar(255) = '',
 @IPVC_CreatedBy    varchar(70)  = '',
 @IPC_QuoteStatusCode char(4)    = '',
 @IPDT_StartDate    varchar(12)  = '',
 @IPDT_EndDate      varchar(12)  = '',
 @IPVC_NewQuoteID   varchar(22)  = '' 
)      
as      
BEGIN         
Set nocount on  
-------------------------------------------------------------------------- 		
--Initialize Local Variables
-------------------------------------------------------------------------- 		
if (@IPDT_StartDate is null or @IPDT_StartDate = '')
  begin
    set @IPDT_StartDate = (select convert(varchar(50),CreatedDate,101) from Customers..Company where IDSeq=@IPC_CompanyID) 
  end

if (@IPDT_EndDate is null or @IPDT_EndDate = '')
  begin
    set @IPDT_EndDate =  convert(varchar(50),getdate(),101)
  end	 
--------------------------------------------------------------------------
--Declaring local table variables          
--------------------------------------------------------------------------      
Declare @LT_TempQuoteDetails Table  
(
 CustomerID        char(11), 
 CustomerDesc      varchar(255),
 QuoteID           varchar(22),
 QuoteDesc         varchar(255),
 QuoteStatusCode   char(4),
 ILF               money,
 Access1Year       money
)
--------------------------------------------------------------------------
if(@QFlag=1) -- When Page Loads (Only One Record will be retrieved)
  Begin
    Insert into @LT_TempQuoteDetails (CustomerID,CustomerDesc,QuoteID,QuoteDesc,QuoteStatusCode,ILF,Access1Year)
    select Q.customeridseq                 as CustomerID,
           C.Name                          as CustomerDesc,
           Q.QuoteIDSeq                    as QuoteID,
           Q.Description                   as QuoteDesc,
           Q.QuoteStatusCode               as QuoteStatusCode,
           Q.ILFNetExtYearChargeAmount     as ILF,
           Q.AccessNetExtYear1ChargeAmount as Access1Year
    from  Quotes..Quote Q (nolock)
      Join Customers..Company C on Q.CustomerIDSeq=C.IDSeq
      Join [Security]..[User] U on Q.modifiedByIDSeq = U.IDseq
       WHERE Q.customeridseq=@IPC_CompanyID 
       and Q.QuoteIDSeq =@IPVC_QuoteID
       --and Q.CreateDate >= convert(varchar(50),@IPDT_StartDate,101) and Q.CreateDate <= convert(varchar(50),@IPDT_EndDate,101)
  End
--------------------------------------------------------------------------
if(@QFlag=2)  -- Insert only two records with default QuoteID passed and new quoteID @IPVC_NewQuoteID
  Begin  
     -- Inserting the default quote Record
    Insert into @LT_TempQuoteDetails (CustomerID,CustomerDesc,QuoteID,QuoteDesc,QuoteStatusCode,ILF,Access1Year)
    select Q.customeridseq                 as CustomerID,
           C.Name                          as CustomerDesc,
           Q.QuoteIDSeq                    as QuoteID,
           Q.Description                   as QuoteDesc,
           Q.QuoteStatusCode               as QuoteStatusCode,
           Q.ILFNetExtYearChargeAmount     as ILF,
           Q.AccessNetExtYear1ChargeAmount as Access1Year
    from Quotes..Quote Q (nolock)
      Join Customers..Company C on Q.CustomerIDSeq=C.IDSeq
      Join [Security]..[User] U on Q.modifiedByIDSeq = U.IDseq
       WHERE Q.customeridseq=@IPC_CompanyID 
       and Q.QuoteIDSeq =@IPVC_QuoteID
       --and Q.CreateDate >= convert(varchar(50),@IPDT_StartDate,101) and Q.CreateDate <= convert(varchar(50),@IPDT_EndDate,101)
 		
		-- Inserting the new QuoteID record
	 if(@IPVC_NewQuoteID <> '' and @IPVC_NewQuoteID is not null and @IPVC_NewQuoteID <>@IPVC_QuoteID )
		Begin
		  Insert into @LT_TempQuoteDetails (CustomerID,CustomerDesc,QuoteID,QuoteDesc,QuoteStatusCode,ILF,Access1Year)
		  select Q.customeridseq                 as CustomerID,
		         C.Name                          as CustomerDesc,
				 Q.QuoteIDSeq                    as QuoteID,
				 Q.Description                   as QuoteDesc,
				 Q.QuoteStatusCode               as QuoteStatusCode,
				 Q.ILFNetExtYearChargeAmount     as ILF,
				 Q.AccessNetExtYear1ChargeAmount as Access1Year
		   from Quotes..Quote Q (nolock)
		     Join Customers..Company C on Q.CustomerIDSeq=C.IDSeq
		     Join [Security]..[User] U on Q.modifiedByIDSeq = U.IDseq
		      WHERE --Q.customeridseq=@IPC_CompanyID 
                Q.customeridseq = (case when (@IPC_CompanyID <> '' and @IPC_CompanyID is not null)
                                 then @IPC_CompanyID else Q.customeridseq end)
			  and --Q.QuoteIDSeq = @IPVC_NewQuoteID
            Q.QuoteIDSeq = (case when (@IPVC_NewQuoteID <> '' and @IPVC_NewQuoteID is not null)
                                 then @IPVC_NewQuoteID else Q.QuoteIDSeq end)
			  and (Q.Description like '%' + @IPVC_QuoteDesc + '%' or isnull(Q.Description,'')=isnull(@IPVC_QuoteDesc,isnull(Q.Description,'')))
			  and  U.IDseq = (case when (@IPVC_CreatedBy <> '' and @IPVC_CreatedBy is not null)
                                 then @IPVC_CreatedBy else U.IDseq end)
			  and Q.QuoteStatusCode <> 'CNL'
			  and Q.QuoteStatusCode = (case when (@IPC_QuoteStatusCode <> '' and @IPC_QuoteStatusCode is not null)
										  then @IPC_QuoteStatusCode else Q.QuoteStatusCode end)
			  and  Q.CreateDate >= convert(varchar(50),@IPDT_StartDate,101) and Q.CreateDate <= convert(varchar(50),@IPDT_EndDate,101)
		End
   End
--------------------------------------------------------------------------
if(@QFlag=3) -- To get all the quoteID with default QuoteID at top
	Begin  -- Inserting the default quote Record
		Insert into @LT_TempQuoteDetails (CustomerID,CustomerDesc,QuoteID,QuoteDesc,QuoteStatusCode,ILF,Access1Year)
		select Q.customeridseq                 as CustomerID,
			   C.Name                          as CustomerDesc,
			   Q.QuoteIDSeq                    as QuoteID,
			   Q.Description                   as QuoteDesc,
			   Q.QuoteStatusCode               as QuoteStatusCode,
			   Q.ILFNetExtYearChargeAmount     as ILF,
			   Q.AccessNetExtYear1ChargeAmount as Access1Year
		from Quotes..Quote Q (nolock)
		  Join Customers..Company C on Q.CustomerIDSeq=C.IDSeq
		  Join [Security]..[User] U on Q.modifiedByIDSeq = U.IDseq
		   WHERE Q.customeridseq=@IPC_CompanyID 
		   and  Q.QuoteIDSeq =@IPVC_QuoteID
		  --and  Q.CreateDate >= convert(varchar(50),@IPDT_StartDate,101) and Q.CreateDate <= convert(varchar(50),@IPDT_EndDate,101)
 
			-- Inserting all the quote Records except the default quote
		Insert into @LT_TempQuoteDetails (CustomerID,CustomerDesc,QuoteID,QuoteDesc,QuoteStatusCode,ILF,Access1Year)
		select Q.customeridseq                 as CustomerID,
			   C.Name                          as CustomerDesc,
			   Q.QuoteIDSeq                    as QuoteID,
			   Q.Description                   as QuoteDesc,
		       Q.QuoteStatusCode               as QuoteStatusCode,
			   Q.ILFNetExtYearChargeAmount     as ILF,
			   Q.AccessNetExtYear1ChargeAmount as Access1Year
		from Quotes..Quote Q (nolock)
		  Join Customers..Company C on Q.CustomerIDSeq=C.IDSeq
		  Join [Security]..[User] U on Q.modifiedByIDSeq = U.IDseq
		   WHERE Q.customeridseq = (case when (@IPC_CompanyID <> '' and @IPC_CompanyID is not null)
                                 then @IPC_CompanyID else Q.customeridseq end) 
			and Q.QuoteIDSeq = (case when (@IPVC_NewQuoteID <> '' and @IPVC_NewQuoteID is not null and @IPVC_NewQuoteID <>@IPVC_QuoteID)
                                 then @IPVC_NewQuoteID else Q.QuoteIDSeq end)	
			and Q.QuoteIDSeq not in (select distinct Q.QuoteIDSeq where Q.QuoteIDSeq=@IPVC_QuoteID)				
		   and (Q.Description like '%' + @IPVC_QuoteDesc + '%' or isnull(Q.Description,'')=isnull(@IPVC_QuoteDesc,isnull(Q.Description,'')))
           and  U.IDseq = (case when (@IPVC_CreatedBy <> '' and @IPVC_CreatedBy is not null)
                                 then @IPVC_CreatedBy else U.IDseq end)
		   and Q.QuoteStatusCode <> 'CNL'
		   and Q.QuoteStatusCode = (case when (@IPC_QuoteStatusCode <> '' and @IPC_QuoteStatusCode is not null)
										  then @IPC_QuoteStatusCode else Q.QuoteStatusCode end)		 
		   and convert(datetime,convert(varchar(50),Q.CreateDate,101))  >= convert(datetime,convert(varchar(50),@IPDT_StartDate,101))  
                  and  convert(datetime,convert(varchar(50),Q.CreateDate,101)) <= convert(datetime,convert(varchar(50),@IPDT_EndDate,101))
	End
--------------------------------------------------------------------------
---Final Select for the data
-------------------------------------------------------------------------- 
select CustomerID,CustomerDesc,QuoteID,QuoteDesc,ILF,Access1Year
from @LT_TempQuoteDetails 

select count(QuoteID)--,CustomerID,CustomerDesc,QuoteID,QuoteDesc,ILF,Access1Year
from @LT_TempQuoteDetails 
END  
 
/*
Exec [Quotes].[dbo].[uspQUOTES_GetDealQuotesDetails] @IPC_CompanyID='C0000002363',@IPVC_QuoteID='Q0809000302',@QFlag=3,@IPVC_QuoteDesc='',
@IPVC_CreatedBy='',@IPC_QuoteStatusCode='',@IPDT_StartDate='',@IPDT_EndDate='',@IPVC_NewQuoteID=''
*/
GO
