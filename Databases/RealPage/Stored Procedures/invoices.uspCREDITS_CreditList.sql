SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure invoices.uspCREDITS_CreditList
	@IPI_RowsPerPage		int
,	@IPI_PageNumber			int
,	@IPVC_CompanyIDSeq		varchar(22) 
,	@IPVC_EpicorID			varchar(50)
,	@IPVC_ProcessedBy		varchar(150)
,	@IPVC_RequestedDate		varchar(12)  
,	@IPVC_AccountID			varchar(22)
,	@IPVC_Status			varchar(5)
,	@IPVC_PropertyName		varchar(100)
,	@IPB_PropertyIncluded	bit
,	@IPI_DateSelected		int
,	@IPI_CrReverse			int
,	@IPVC_InvoiceID			varchar(22)
,	@IPVC_CountryCode		varchar(20)	= ''  
as
/*
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspCREDITS_CreditList]
-- Description     : This procedure returns the Credit records based on the search parameters
-- Input Parameters:  1.  @IPI_RowsPerPage as int,
--                    2.  @IPI_PageNumber as int,
--                    3.  @IPVC_InvoiceIDSeq as varchar(22),
--                    4.  @IPVC_CustomerName as varchar(100),
--                    5.  @IPVC_RequestedBy as varchar(70),
--                    6.  @IPVC_RequestedDate as varchar(12),  
--                    7.  @IPVC_ProductCode varchar(30),
--                    8.  @IPVC_AccountID varchar(22),
--                    9.  @IPVC_Status  varchar(5),
--                    10. @IPVC_PropertyName varchar(100),
--                    11. @IPB_PropertyIncluded bit,
--                    12. @IPI_DateSelected int
--                    13. @IPI_CrReverse int,
--					  14. @IPI_PrintFlag varchar(5),
--                    15. @IPVC_InvoiceID varchar(22),
--					  16. @IPVC_CountryCode     varchar(20)=''  
--
-- OUTPUT          : RecordSet of ID,AccountName,City,State,Zip,AccountTypeCode,Units,PPU
-- Code Example    : Exec INVOICES.[dbo].[uspCREDITS_CreditList] @IPI_RowsPerPage = 15,
--                                                                @IPI_PageNumber = 1,
--                                                                @IPVC_InvoiceIDSeq = '',
--                                                                @IPVC_CustomerName = '',
--                                                                @IPVC_RequestedBy = '',
--                                                                @IPVC_RequestedDate = '',  
--                                                                @IPVC_ProductCode = '',
--                                                                @IPVC_AccountID = '',
--                                                                @IPVC_Status  = '',
--                                                                @IPVC_PropertyName = '',
--                                                                @IPB_PropertyIncluded = 1,
--                                                                @IPI_DateSelected = 1 ,
--                                                                @IPI_CrReverse =0,
--													              @IPI_PrintFlag =0,
--                                                                @IPVC_InvoiceID ='',
--												                  @IPVC_CountryCode =''  
-- 
-- 
-- Revision History:
-- Author          : KRK, SRA Systems Limited 
-- 05/11/2006      : Modified by STA. Modified as per the latest schema change.
-- 04/22/2008      : Defect #4950
-- 06/02/2008	   : Naval Kishore Modified to get credit Amount.	
-- 12/13/2010	   : Damodar N (Defect# :8642 Replaced @IPVC_RequestedBy with @IPVC_ProcessedBy and Removed @IPI_PrintFlag )
-- 03/23/2011	   : Surya Kondapalli (Defect# 7952: Credit Reversal OMS changes)
-- 10/19/2011      : Mahaboob ( TFS #1151 - CountryCode has been added in the Search criteria. )
------------------------------------------------------------------------------------------------------
*/
begin	-->Main Begin
	set nocount on;
	declare @customerid   varchar(50);
	select  @customerid = (	select top 1 CompanyIDSeq
							from	invoices.Invoice	I	with (nolock) 
							join	invoices.CreditMemo CM	with (nolock)
									on   I.InvoiceIdSeq = CM.InvoiceIdSeq
							where ((I.accountidseq = @IPVC_AccountID)
								or (I.EpicorCustomerCode  = @IPVC_EpicorID ))
							and		I.AccountTypeCode = 'AHOFF')

if ((@IPVC_PropertyName = '') and (@customerid is null) and (@IPVC_CompanyIDSeq =''))
begin
set @IPB_PropertyIncluded = 1
end       

--set @IPVC_AccountID = nullif(@IPVC_AccountID,'');
set @customerid		   = nullif(@customerid,''); 			

  ----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------

	with tablefinal as 
       ----------------------------------------------------------  
       (select  tableinner.*
        from 
           ---------------------------------------------------------- 
			 (select  row_number() over(Order by source.CreditID        desc)
                                   as RowNumber,
                  source.*
          from
             ---------------------------------------------------------- 
            (select 
					I.CompanyIDSeq									  as CompanyID, 
                    CM.CreditMemoIDSeq                                as CreditID,
                    CM.InvoiceIDSeq                                   as InvoiceID,
                    I.AccountIDSeq                                    as AccountID,  
                    isnull(I.PropertyName, I.CompanyName)             as AccountName, 
                    CST.Name                                          as [Status],
--                    CST.Name   as [Status],
                    (case when (CM.CreditTypeCode = 'FULC')
									                then 'Full Credit'
                                when (CM.CreditTypeCode = 'PARC')
                                  then 'Partial Credit'
			                          when (CM.CreditTypeCode = 'TAXC')
                                     then 'Tax Credit'
                            end)                                                     as CreditType,
                    --convert(numeric(30,2),CM.TotalNetCreditAmount)    as CreditAmount,  
                    isnull( oms.fn_FormatCurrency(convert(numeric(30,2),CM.TotalNetCreditAmount + CM.TaxAmount + CM.ShippingAndHandlingCreditAmount) ,2,2),'0')  as CreditAmount,  
                    CM.ApprovedBy                                     as ApprovedBy,
                    convert(varchar(12),CM.RequestedDate,101)         as RequestedDate,
                    convert(varchar(12),CM.ApprovedDate,101)          as ApprovedDate,
                    CM.RequestedBy                                    as RequestedBy,
                    CM.ApplyToCreditMemoIDSeq                         as ApplyToCreditMemoIDSeq,
                    CM.CreditMemoReversalFlag                         as CreditMemoReversalFlag
                    
                    from          invoices.CreditMemo CM with (nolock)
                	
                    inner join    invoices.CreditStatusType CST with (nolock)
                      on          CM.CreditStatusCode = CST.Code

                    inner join    invoices.Invoice I with (nolock)
                      on          CM.InvoiceIDSeq = I.InvoiceIDSeq

                     where       --(@IPVC_EpicorID = '' OR I.EpicorCustomerCode LIKE '%' + @IPVC_EpicorID + '%')  
					(((@IPVC_EpicorID = '' or I.EpicorCustomerCode like '%' + @IPVC_EpicorID + '%'))-- and @IPI_PropertyIncluded = 0 AND (PropertyIDSeq is null))    )
              or  ((@IPB_PropertyIncluded = 1) and I.CompanyIDSeq  = coalesce(@customerid,I.CompanyIDSeq) and (@customerid is not null)))
	          and (((I.CompanyName  like '%' + @IPVC_PropertyName + '%') and @IPB_PropertyIncluded = 0 and (PropertyIDSeq is null))  
              or  ((I.CompanyName  like '%' + @IPVC_PropertyName + '%') or (I.PropertyName like '%' + @IPVC_PropertyName + '%')) and (@IPB_PropertyIncluded = 1))    
              and ((@IPVC_ProcessedBy     = '')  or (CM.CreatedBy      like '%' + @IPVC_ProcessedBy + '%'))   
              and ((@IPVC_Status          = '')  or (CM.CreditStatusCode like '%' + @IPVC_Status + '%'))   
              and (((@IPVC_AccountID       = '')  or (I.AccountIDSeq      = @IPVC_AccountID)) 
              or  ((@IPB_PropertyIncluded = 1) and I.CompanyIDSeq  = coalesce(@customerid,I.CompanyIDSeq) and (@customerid is not null)))
              and ((@IPVC_CompanyIDSeq    = '')  or (I.CompanyIDSeq     = @IPVC_CompanyIDSeq ))  
              and ((@IPVC_InvoiceID    = '')  or (CM.InvoiceIDSeq     = @IPVC_InvoiceID ))
			  and ((@IPVC_CountryCode    = '')  or (I.BillToCountryCode     = @IPVC_CountryCode ))   
--              AND ((@IPI_PrintFlag='')or  (CM.PrintFlag LIKE '%' + @IPI_PrintFlag + '%'))   
              and (     
                                  (@IPI_DateSelected = 4 and convert(varchar(12),CM.RequestedDate,101) = @IPVC_RequestedDate)  
                                   or  
                                  (@IPI_DateSelected = 1 and convert(varchar(12),CM.RequestedDate,101) = convert(varchar(12),getdate(),101))         
                                   or  
                                  (@IPI_DateSelected = 2 and CM.RequestedDate between (dateadd(week,-1,getdate())) and getdate())          
                                   or  
                                  (@IPI_DateSelected = 3 and CM.RequestedDate between (dateadd(m,-1,getdate())) and getdate())           
                                   or  
                                   @IPI_DateSelected = 0  
                          )
                -------------------------------------------------------------
                )Source
              -----------------------------------------------------------------
              )tableinner
             --------------------------------------------------------------------

--             WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage  
--             AND tableinner.RowNumber   <= @IPI_PageNumber * @IPI_RowsPerPage 
         )

				select  tablefinal.RowNumber,
						tablefinal.CompanyID				as  CompanyID,
						tablefinal.CreditID                 as CreditID,
						tablefinal.InvoiceID                as InvoiceID,
						tablefinal.AccountID                as AccountID,
						tablefinal.AccountName              as AccountName,
                        tablefinal.[Status]                 as [Status],
--						'Credit Reversed'                   as [Status],
						tablefinal.CreditType               as CreditType,
						tablefinal.CreditAmount             as CreditAmount, 
						tablefinal.ApprovedBy               as ApprovedBy,
						tablefinal.RequestedDate            as RequestedDate,
						tablefinal.ApprovedDate             as ApprovedDate,
						tablefinal.RequestedBy              as RequestedBy,
                        tablefinal.ApplyToCreditMemoIDSeq   as ApplyToCreditMemoIDSeq,
                        tablefinal.CreditMemoReversalFlag   as CreditMemoReversalFlag
                into    #temp_tbl
				from    tablefinal 
  ----------------------------------------------------------------------------
  --Retrieving Final Recordset
  ----------------------------------------------------------------------------
            if (@IPI_CrReverse = 1)
              begin
                select   row_number() over (Order by  RowNumber) as seq,
						 CompanyID				  as CompanyID ,
						 CreditID                 as CreditID,
						 InvoiceID                as InvoiceID,
						 AccountID                as AccountID,
						 AccountName              as AccountName,
						'Credit Reversed'         as [Status],
						 CreditType               as CreditType,
						 CreditAmount             as CreditAmount, 
						 ApprovedBy               as ApprovedBy,
						 RequestedDate            as RequestedDate,
						 ApprovedDate             as ApprovedDate,
						 RequestedBy              as RequestedBy	 
                into     #temp_Finaltbl      
				from     #temp_tbl with (nolock)
                where CreditMemoReversalFlag=0
                 and CreditID in (select ApplyToCreditMemoIDSeq from #temp_tbl)

                select * 
                from #temp_Finaltbl
                where #temp_Finaltbl.seq > (@IPI_PageNumber-1) * @IPI_RowsPerPage  
                and #temp_Finaltbl.seq   <= @IPI_PageNumber * @IPI_RowsPerPage 	

                drop table #temp_Finaltbl					
              end
           else 
            if (@IPI_CrReverse = 0 and @IPVC_Status <> '')
              begin
				select   row_number() over (Order by  RowNumber) as seq,
						 CompanyID				  as CompanyID,
						 CreditID                 as CreditID,
						 InvoiceID                as InvoiceID,
						 AccountID                as AccountID,
						 AccountName              as AccountName,
						 [Status]                 as [Status],
						 CreditType               as CreditType,
						 CreditAmount             as CreditAmount, 
						 ApprovedBy               as ApprovedBy,
						 RequestedDate            as RequestedDate,
						 ApprovedDate             as ApprovedDate,
						 RequestedBy              as RequestedBy	      
                into    #temp_Finaltbl1
				from    #temp_tbl 
                where   CreditID not in (select ApplyToCreditMemoIDSeq from #temp_tbl where ApplyToCreditMemoIDSeq is not null)
                
                 select * 
                from #temp_Finaltbl1
                where #temp_Finaltbl1.seq > (@IPI_PageNumber-1) * @IPI_RowsPerPage  
                and #temp_Finaltbl1.seq   <= @IPI_PageNumber * @IPI_RowsPerPage 
                
                drop table #temp_Finaltbl1
                
              end
           else
            if (@IPI_CrReverse = 0 and @IPVC_Status = '')
              begin
				select   row_number() over (Order by  RowNumber) as seq,
						 CompanyID				  as CompanyID, 
						 CreditID                 as CreditID,
						 InvoiceID                as InvoiceID,
						 AccountID                as AccountID,
						 AccountName              as AccountName,
						 [Status]		=		  case when ApplyToCreditMemoIDSeq is not null 
													   then 'Credit Reversed'
												  else [Status] end,
						 CreditType               as CreditType,
						 CreditAmount             as CreditAmount, 
						 ApprovedBy               as ApprovedBy,
						 RequestedDate            as RequestedDate,
						 ApprovedDate             as ApprovedDate,
						 RequestedBy              as RequestedBy	      
                into    #temp_Finaltbl2
				from    #temp_tbl 
                

                select * 
                from  #temp_Finaltbl2
                where #temp_Finaltbl2.seq  > (@IPI_PageNumber-1) * @IPI_RowsPerPage  
                  and #temp_Finaltbl2.seq  <= @IPI_PageNumber * @IPI_RowsPerPage 
	
                drop table #temp_Finaltbl2					
              end

	drop table #temp_tbl
          
end;	-->Main End
GO
