SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE invoices.uspCREDITS_CreditDetails
	@IPBI_CreditIDSeq	varchar(50)
as
/*
----------------------------------------------------------------------------------------------------??
-- Database  Name  : CUSTOMERS??
-- Procedure Name  : [uspCUSTOMERS_CreditDetails]??
-- Description     : This procedure returns the Credit records based on the search parameters??
-- Input Parameters: 	1.  @IPBI_CreditIDSeq as bigint??
-- ??
-- OUTPUT          : RecordSet of ID,AccountName,City,State,Zip,AccountTypeCode,Units,PPU??
-- Code Example    : Exec Invoices.[dbo].[uspCREDITS_CreditDetails] @IPBI_CreditIDSeq = 'R1008000003'
-- ??
-- ??
-- Revision History:??
-- Author          : KRK, SRA Systems Limited ??
-- 05/11/2006      : Modified by STA. Modified as per the latest schema change.??
-- 10/01/2007      : Modified By Naval Kishore to get credittype
-- 04/17/2009	   : Naval Kishore Modified to change Credit Comments value.
-- 05/20/2009	   : Naval kishore Modified to get Country Info for other countries.
-- 2010-07-20	   : Larry. remove references to bogus column Address.Country (2010.07 regression)
-- 2010-07-21	   : Anand. Modified to get Credit Reason Column
-- 08/05/2010      : Shashi Bhushan - Defect#7952 - Credit Reversals in OMS
------------------------------------------------------------------------------------------------------??
*/
begin
  set nocount on;
  /****************************************************************/
  /************* Member Variable Declaration *********************/
  /****************************************************************/
  declare @IPVC_PropertyIDSeq    varchar(22)
  declare @LVC_ReversedCreditID  varchar(22)

  /****************************************************************/
  /************* Member Variable Initialization *******************/
  /****************************************************************/
  select      @IPVC_PropertyIDSeq = I.PropertyIDSeq 
  from        invoices.CreditMemo CM
  inner join  invoices.Invoice I 
    on        CM.InvoiceIDSeq = I.InvoiceIDSeq
  where       CM.CreditMemoIDSeq = @IPBI_CreditIDSeq

  select @LVC_ReversedCreditID = ApplyToCreditMemoIDSeq 
  from   invoices.CreditMemo 
  where  ApplyToCreditMemoIDSeq = @IPBI_CreditIDSeq and CreditMemoReversalFlag=1
  /****************************************************************/

if @IPVC_PropertyIDSeq is null
  begin
    print 'entered if'
    /*************************************************************************************/
    select top 1          CM.CreditMemoIDSeq                                as CreditID,
                          CM.InvoiceIDSeq                                   as InvoiceID,
                          IG.OrderIDSeq                                     as OrderID,
                          I.AccountIDSeq                                    as AccountID,
                          I.PropertyIDSeq                                   as PropertyIDSeq, 
                          null                                              as Name,
                          I.CompanyIDSeq                                    as CompanyIDSeq,
                          (case when (CM.CreditTypeCode = 'FULC')
									                then 'Full Credit'
                                when (CM.CreditTypeCode = 'PARC')
                                  then 'Partial Credit'
			                          when (CM.CreditTypeCode = 'TAXC')
                                     then 'Tax Credit'
                            end)                                            as CreditType, 
		                  isnull(oms.fn_FormatCurrency ( 
                                                                convert(numeric(30,2),I.AccessChargeAmount) +
                                                                convert(numeric(30,2),I.ILFChargeAmount) +
                                                                convert(numeric(30,2),I.TransactionChargeAmount),2,2),'0'
                                                               )		    as Amount,
						  isnull( oms.fn_FormatCurrency(convert(numeric(30,2),I.TaxAmount),2,2),'0')		as Tax,
						  isnull( oms.fn_FormatCurrency( 
                                                                convert(numeric(30,2),I.AccessChargeAmount) +
                                                                convert(numeric(30,2),I.ILFChargeAmount) +
                                                                convert(numeric(30,2),I.TransactionChargeAmount)+
                                                                convert(numeric(30,2),I.TaxAmount),2,2),'0'
                                                               )		    as Total,

                          CM.RequestedBy                                    as RequestedBy,
                          CM.CreatedBy                                      as ProcessedBy,
                          CM.ApprovedBy                                     as ApprovedByFirst, 
                          CM.ApprovedBy                                     as ApprovedBySecond, 
                          CM.ApprovedBy                                     as ApprovedByThird,
                          convert(varchar(12),CM.RequestedDate,101)         as RequestedByDate,
                          convert(varchar(12),CM.CreatedDate,101)           as ProcessedByDate,    
                          convert(varchar(12),CM.ApprovedDate,101)          as ApprovedByDateFirst,   
                          convert(varchar(12),CM.ApprovedDate,101)          as ApprovedByDateSecond,
                          convert(varchar(12),CM.ApprovedDate,101)          as ApprovedByDateThird,
						  CM.RevisedBy										as RevisedBy,
						  convert(varchar(12),CM.RevisedDate,101)           as RevisedDate,
                          R.ReasonName                                      as CreditReasons,
						  case when CM.Comments='' 
								then 'N/A' 
								else CM.Comments end						as Comments,
                          null                                              as SiteMasterID,
                          null                                              as Units,
                          null                                              as PPUPercentage,
                          null                                              as AddressLine1,
                          null                                              as AddressLine2,
                          null                                              as City,
                          null                                              as State,
                          null                                              as Zip,
						  null												as Country,
	                      I.CompanyName                                     as CName,
                          AC.IDSeq                                          as CIDSeq,
                          isnull(c.SiteMasterId,'')                         as CSiteMasterId,
                          CA.Addressline1                                   as CAddressLine1,
                          CA.AddressLine2                                   as CAddressLine2,
                          CA.city                                           as CCity,
                          CA.state                                          as CState,
                          CA.zip                                            as CZip,
						  upper(CAC.[Name])                                 as CCountry,

                          isnull( oms.fn_FormatCurrency( convert(numeric(30,2),isnull((
                                  select top 1 TotalNetCreditAmount as CreditAmount  
						          from  invoices.CreditMemo with (nolock)
						          where CreditStatusCode = 'APPR' 
                                    and InvoiceIDSeq = (select top 1 InvoiceIDSeq 
									                    from invoices.CreditMemoItem 
									                    where CreditMemoIDSeq=CM.CreditMemoIDSeq)
                                    and CreatedDate not in (
                                                            select top 1 CreatedDate 
                                                            from invoices.CreditMemo 
                                                            where InvoiceIDSeq = (select top 1 InvoiceIDSeq 
									                                              from invoices.CreditMemoItem 
									                                              where CreditMemoIDSeq=CM.CreditMemoIDSeq) 
									                        Order by CreatedDate desc 
                                                            )
						          Order by CreatedDate desc),0)),2,2),'0')	as PreviousCreditNet,
							
						isnull( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(
                          (select top 1 
                          convert(numeric(30,2),TaxAmount) as TaxAmount 
						              from invoices.CreditMemo 
						              where CreditStatusCode = 'APPR' and  
                          InvoiceIDSeq =(select top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq )  
                                    and 
						                        CreatedDate not in(
											              select top 1 CreatedDate 
                                    from invoices.CreditMemo 
											              where InvoiceIDSeq =(select 
                                    top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq ) 
											              Order by CreatedDate desc ) 
						              Order by CreatedDate desc),0)),2,2),'0')							as PreviousCreditTax,

            --PreviousCreditTotal = Sum of all the Credits that are already approved for this Invoice excluding Current Invoice.
						(isnull( oms.fn_FormatCurrency( convert(numeric(30,2),isnull((
                                  select sum(TotalNetCreditAmount) 
                                  as CreditAmount  
						                      from  invoices.CreditMemo 
						                      where CreditStatusCode = 'APPR' 
                                  and InvoiceIDSeq = (
                                        select top 1 InvoiceIDSeq 
									                      from invoices.CreditMemoItem 
									                      where CreditMemoIDSeq=CM.CreditMemoIDSeq )
                                  and CreatedDate not in(
                                        select top 1 CreatedDate 
                                        from invoices.CreditMemo 
                                        where InvoiceIDSeq =
                                        ( select top 1 InvoiceIDSeq 
									                        from invoices.CreditMemoItem 
									                        where CreditMemoIDSeq=CM.CreditMemoIDSeq ) 
									                Order by CreatedDate desc )),0)) + convert(numeric(30,2),isnull(
                          (select sum(
                          convert(numeric(30,2),TaxAmount)) as TaxAmount 
						              from invoices.CreditMemo 
						              where CreditStatusCode = 'APPR' and  
                          InvoiceIDSeq =(select top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq  )  
                                    and 
						                        CreatedDate not in(
											              select top 1 CreatedDate 
                                    from invoices.CreditMemo 
											              where InvoiceIDSeq =(select 
                                    top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq  ) 
											              Order by CreatedDate desc)),0)),2,2),'0'))							as PreviousCreditTotal,

--						              convert(numeric(30,2),
--                            isnull(TotalNetCreditAmount,0))				          as CurrentCreditAmt,

							isnull( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(TotalNetCreditAmount,0)),2,2),'0')		as CurrentCreditAmt,
                          
                          convert(numeric(30,2),isnull(CM.TaxAmount,0))			as CurrentCreditTax,

							 --CurrentCreditTotal = CurrentCreditAmount + CurrentTaxAmount
--							(ISNULL( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(TotalNetCreditAmount,0))
--								+ isnull(CM.ShippingAndHandlingCreditAmount,0.00) +  convert(numeric(30,2),isnull(CM.TaxAmount,0)),2,2),'0'))						as CurrentCreditTotal,
                    ------------------------------------------------------------                      convert(numeric(30,2),  
                      (select  (isnull( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(CrM.TotalNetCreditAmount,0))
								      + isnull(sum(CrI.ShippingAndHandlingCreditAmount),0.00) +  convert(numeric(30,2),isnull(sum(CrI.TaxAmount),0)),2,2),'0'))  
                              from    invoices.CreditMemoItem CrI with (nolock)
                              inner join   
									  invoices.CreditMemo CrM with (nolock)
                                on CrM.CreditMemoIDSeq = CrI.CreditMemoIDSeq
                              where  CrI.CreditMemoIDSeq =  @IPBI_CreditIDSeq
                              Group by CrM.TotalNetCreditAmount )                    as CurrentCreditTotal,  
                    ------------------------------------------------------------

                          isnull(TotalNetCreditAmount,0) +	
                            isnull(CM.TaxAmount,0)                          as AdjustedTotal,
                          (case when (CM.CreditStatusCode = 'APPR' and @LVC_ReversedCreditID is null)
									 then 'Approved'
                                when (CM.CreditStatusCode = 'DENY')
                                     then 'Denied'
			                    when (CM.CreditStatusCode = 'PAPR')
                                     then 'Pending'
								when (CM.CreditStatusCode = 'RVSD')
									 then 'Revised'
								when (CM.CreditStatusCode = 'CNCL')
									 then 'Cancelled'
                                when (CM.CreditStatusCode = 'APPR' and @LVC_ReversedCreditID is not null)
									 then 'Reversed'
                                 end)                               as Status,
                          isnull(CM.EpicorBatchCode, 'N/A')         as EpicorBatchCode,
                          isnull(CM.SentToEpicorStatus, 'NOT SENT') as SentToEpicorStatus,
                          isnull(I.EpicorCustomerCode, 'N/A')       as EpicorCustomerCode,
--						  isnull(CM.ApplyToCreditMemoIDSeq, 'N/A')  as ReversedCreditID   
                          isnull(CM.ApplyToCreditMemoIDSeq,'N/A')   as ReversedCreditID,
                                CM.CreditMemoReversalFlag           as CreditMemoReversalFlag,
                                CM.ReversedBy                       as ReversedBy,
                          convert(varchar(12),CM.ReversedDate,101)  as ReversedDate,
						  CM.CancelledBy							as CancelledBy,
						  convert(varchar(12),CM.CancelledDate,101) as CancelledDate
                
    from                  invoices.CreditMemo CM

    left outer join       invoices.CreditMemoItem CMI
      on                  CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq 

    left outer join       invoices.Invoice I 
      on                  CM.InvoiceIDSeq = I.InvoiceIDSeq

    left outer join	  orders.Reason R (nolock)
      on				  CM.CreditReasonCode   = R.Code	

    left outer join       invoices.InvoiceItem II 
      on                  CMI.InvoiceITEMIDSeq  = II.IDSeq

    left outer join       invoices.InvoiceGroup IG
      on                  II.InvoiceGroupIDSeq = IG.IDSeq

    left outer join       customers.[Company] C (nolock)
      on                  I.CompanyIDSeq = C.IDSeq

	inner join            customers.[Account] AC (nolock)
      on                  AC.CompanyIDSeq = C.IDSeq
      and                 AC.ActiveFlag = 1

    left outer join       customers.Address CA (nolock)
      on                  CA.CompanyIDSeq = C.IDSeq  
	left outer join customers.[Country] CAC with (nolock) on CAC.[Code]=CA.[CountryCode]

    where                 CM.CreditMemoIDSeq =  @IPBI_CreditIDSeq
    /*************************************************************************************/
  end
else
  begin
    print 'Entered else'
    /*************************************************************************************/
    select top 1          CM.CreditMemoIDSeq                                  as CreditID,
                          CM.InvoiceIDSeq                                     as InvoiceID,
                          IG.OrderIDSeq                                       as OrderID,
                          I.AccountIDSeq                                      as AccountID,
                          I.PropertyIDSeq                                     as PropertyIDSeq, 
                          I.CompanyIDSeq                                      as CompanyIDSeq,
                          
                          (case when (CM.CreditTypeCode = 'FULC')
									                then 'Full Credit'
                                when (CM.CreditTypeCode = 'PARC')
                                  then 'Partial Credit'
			                          when (CM.CreditTypeCode = 'TAXC')
                                     then 'Tax Credit'
                            end)                                             as CreditType,

							isnull( oms.fn_FormatCurrency( convert(numeric(30,2),I.AccessChargeAmount) +
											convert(numeric(30,2),I.ILFChargeAmount) +
											convert(numeric(30,2),I.TransactionChargeAmount),2,2),'0')		as Amount,

						isnull( oms.fn_FormatCurrency(convert(numeric(30,2),I.TaxAmount),2,2),'0')		as Tax,

						isnull( oms.fn_FormatCurrency( convert(numeric(30,2),I.AccessChargeAmount) +
                          convert(numeric(30,2),I.ILFChargeAmount) +
                          convert(numeric(30,2),I.TransactionChargeAmount)+
                          convert(numeric(30,2),I.TaxAmount),2,2),'0')		as Total,


                          CM.RequestedBy                                      as RequestedBy,
                          CM.CreatedBy                                        as ProcessedBy,
                          CM.ApprovedBy                                       as ApprovedByFirst, 
                          CM.ApprovedBy                                       as ApprovedBySecond, 
                          CM.ApprovedBy                                       as ApprovedByThird,
                          convert(varchar(12),CM.RequestedDate,101)           as RequestedByDate,
                          convert(varchar(12),CM.CreatedDate,101)             as ProcessedByDate,    
                          convert(varchar(12),CM.ApprovedDate,101)            as ApprovedByDateFirst,   
                          convert(varchar(12),CM.ApprovedDate,101)            as ApprovedByDateSecond,
                          convert(varchar(12),CM.ApprovedDate,101)            as ApprovedByDateThird,
						  CM.RevisedBy										  as RevisedBy,
						  convert(varchar(12),CM.RevisedDate,101)             as RevisedDate,
                          R.ReasonName	                                      as CreditReasons,
						  case when CM.Comments='' 
								then 'N/A' 
								else CM.Comments end						as Comments,
                          I.PropertyName                                      as [Name],
                          p.SiteMasterID                                      as SiteMasterID,
                          p.Units                                             as Units,
                          p.PPUPercentage                                     as PPUPercentage,
                          I.BillToAddressLine1                                as AddressLine1,
                          I.BillToAddressLine2                                as AddressLine2,
                          I.BillToCity                                        as City,
                          I.BillToState                                       as State,
                          I.BillToZip                                         as Zip,
						  upper(I.BillToCountry)							  as Country,
	                      I.CompanyName                                       as CName,
                          AC.IDSeq                                            as CIDSeq,
                          isnull(c.SiteMasterId,'')                           as CSiteMasterId,
                          CA.Addressline1                                     as CAddressLine1,
                          CA.AddressLine2                                     as CAddressLine2,
                          CA.city                                             as CCity,
                          CA.state                                            as CState,
                          CA.zip                                              as CZip,
						  upper(CAC.[Name])                                   as CCountry,
                          isnull( oms.fn_FormatCurrency( convert(numeric(30,2),isnull((
                                  select top 1 TotalNetCreditAmount 
                                  as CreditAmount  
						                      from  invoices.CreditMemo 
						                      where CreditStatusCode = 'APPR' 
                                  and InvoiceIDSeq = (
                                        select top 1 InvoiceIDSeq 
									                      from invoices.CreditMemoItem 
									                      where CreditMemoIDSeq=CM.CreditMemoIDSeq )
                                  and CreatedDate not in(
                                        select top 1 CreatedDate 
                                        from invoices.CreditMemo 
                                        where InvoiceIDSeq =
                                        ( select top 1 InvoiceIDSeq 
									                        from invoices.CreditMemoItem 
									                        where CreditMemoIDSeq=CM.CreditMemoIDSeq ) 
									                Order by CreatedDate desc ) 
						                      Order by CreatedDate desc),0)),2,2),'0')		as PreviousCreditNet,

						isnull( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(
                          (select top 1 
                          convert(numeric(30,2),TaxAmount) as TaxAmount 
						              from invoices.CreditMemo 
						              where CreditStatusCode = 'APPR' and  
                          InvoiceIDSeq =(select top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq )  
                                    and 
						                        CreatedDate not in(
											              select top 1 CreatedDate 
                                    from invoices.CreditMemo 
											              where InvoiceIDSeq =(select 
                                    top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq ) 
											              Order by CreatedDate desc ) 
						              Order by CreatedDate desc),0)),2,2),'0')							as PreviousCreditTax,

             --PreviousCreditTotal = Sum of all the Credits that are already approved for this Invoice excluding Current Invoice.
						(isnull( oms.fn_FormatCurrency( convert(numeric(30,2),isnull((
                                  select sum(TotalNetCreditAmount) 
                                  as CreditAmount  
						                      from  invoices.CreditMemo 
						                      where CreditStatusCode = 'APPR' 
                                  and InvoiceIDSeq = (
                                        select top 1 InvoiceIDSeq 
									                      from invoices.CreditMemoItem 
									                      where CreditMemoIDSeq=CM.CreditMemoIDSeq  )
                                  and CreatedDate not in(
                                        select top 1 CreatedDate 
                                        from invoices.CreditMemo 
                                        where InvoiceIDSeq =
                                        ( select top 1 InvoiceIDSeq 
									                        from invoices.CreditMemoItem 
									                        where CreditMemoIDSeq=CM.CreditMemoIDSeq  ) 
									                Order by CreatedDate desc )),0)) + convert(numeric(30,2),isnull(
                          (select sum(
                          convert(numeric(30,2),TaxAmount)) as TaxAmount 
						              from invoices.CreditMemo 
						              where CreditStatusCode = 'APPR' and  
                          InvoiceIDSeq =(select top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq  )  
                                    and 
						                        CreatedDate not in(
											              select top 1 CreatedDate 
                                    from invoices.CreditMemo 
											              where InvoiceIDSeq =(select 
                                    top 1 InvoiceIDSeq 
											              from invoices.CreditMemoItem 
											              where CreditMemoIDSeq=CM.CreditMemoIDSeq  ) 
											              Order by CreatedDate desc )),0)),2,2),'0'))							as PreviousCreditTotal,

						isnull( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(TotalNetCreditAmount,0)),2,2),'0')		as CurrentCreditAmt,
                          
						convert(numeric(30,2), isnull(CM.TaxAmount,0))                  as CurrentCreditTax,

						 	--CurrentCreditTotal = CurrentCreditAmount + CurrentTaxAmount

                    ------------------------------------------------------------                      convert(numeric(30,2),  
                      (select  (isnull( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(CrM.TotalNetCreditAmount,0))
								      + isnull(sum(CrI.ShippingAndHandlingCreditAmount),0.00) +  convert(numeric(30,2),isnull(sum(CrI.TaxAmount),0)),2,2),'0'))  
                              from    invoices.CreditMemoItem CrI with (nolock)
                              inner join   
									  invoices.CreditMemo CrM with (nolock)
                                on CrM.CreditMemoIDSeq = CrI.CreditMemoIDSeq
                              where  CrI.CreditMemoIDSeq =  @IPBI_CreditIDSeq 
                              Group by CrM.TotalNetCreditAmount)                    as CurrentCreditTotal,  
                    ------------------------------------------------------------
--							(ISNULL( oms.fn_FormatCurrency(convert(numeric(30,2),isnull(TotalNetCreditAmount,0))
--								+ isnull(CM.ShippingAndHandlingCreditAmount,0.00) +  convert(numeric(30,2),isnull(CM.TaxAmount,0)),2,2),'0')) as CurrentCreditTotal,


 --AdjustedTotal =    PreviousCreditTotal + CurrentCreditTotal
                       isnull(TotalNetCreditAmount,0) +	
                            isnull(CM.TaxAmount,0) + 
                            (isnull( oms.fn_FormatCurrency( convert(numeric(30,2),isnull((
                                  select sum(TotalNetCreditAmount) 
                                  as CreditAmount  
						                      from  invoices.CreditMemo 
						                      where CreditStatusCode = 'APPR' 
                                  and InvoiceIDSeq = (
                                        select top 1 InvoiceIDSeq 
									                      from invoices.CreditMemoItem 
									                      where CreditMemoIDSeq=CM.CreditMemoIDSeq  )
                                  and CreatedDate not in(
                                        select top 1 CreatedDate 
                                        from invoices.CreditMemo 
                                        where InvoiceIDSeq =
                                        ( select top 1 InvoiceIDSeq 
									                        from invoices.CreditMemoItem 
									                        where CreditMemoIDSeq=CM.CreditMemoIDSeq  ) 
									                Order by CreatedDate desc )),0)) + convert(numeric(30,2),isnull(
                                  (select sum(
                                  convert(numeric(30,2),TaxAmount)) as TaxAmount 
						                      from invoices.CreditMemo 
						                      where CreditStatusCode = 'APPR' and  
                                  InvoiceIDSeq =(select top 1 InvoiceIDSeq 
											                      from invoices.CreditMemoItem 
											                      where CreditMemoIDSeq=CM.CreditMemoIDSeq  )  
                                            and 
						                                CreatedDate not in(
											                      select top 1 CreatedDate 
                                            from invoices.CreditMemo 
											                      where InvoiceIDSeq =(select 
                                            top 1 InvoiceIDSeq 
											                      from invoices.CreditMemoItem 
											                      where CreditMemoIDSeq=CM.CreditMemoIDSeq  ) 
											                      Order by CreatedDate desc)),0)),2,2),'0'))				                         as AdjustedTotal,

                         (case when (CM.CreditStatusCode = 'APPR' and @LVC_ReversedCreditID is null)
									 then 'Approved'
                                when (CM.CreditStatusCode = 'DENY')
                                     then 'Denied'
			                    when (CM.CreditStatusCode = 'PAPR')
                                     then 'Pending'
								when (CM.CreditStatusCode = 'RVSD')
									 then 'Revised'
								when (CM.CreditStatusCode = 'CNCL')
									 then 'Cancelled'
                                when (CM.CreditStatusCode = 'APPR' and @LVC_ReversedCreditID is not null)
									 then 'Reversed'
                                 end)                               as Status,
                          isnull(CM.EpicorBatchCode, 'N/A')         as EpicorBatchCode,
                          isnull(CM.SentToEpicorStatus, 'NOT SENT') as SentToEpicorStatus,
                          isnull(I.EpicorCustomerCode, 'N/A')       as EpicorCustomerCode,
--						  isnull(CM.ApplyToCreditMemoIDSeq, 'N/A') as ReversedCreditID
                          isnull(CM.ApplyToCreditMemoIDSeq,'N/A')   as ReversedCreditID,
                          CM.CreditMemoReversalFlag                 as CreditMemoReversalFlag,
                          CM.ReversedBy                             as ReversedBy,
                          convert(varchar(12),CM.ReversedDate,101)  as ReversedDate,
						  CM.CancelledBy							as CancelledBy,
						  convert(varchar(12),CM.CancelledDate,101) as CancelledDate
                 
   
      from                invoices.CreditMemo CM

      left outer join     invoices.CreditMemoItem CMI
        on                CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq 

      left outer join     invoices.Invoice I 
        on                CM.InvoiceIDSeq = I.InvoiceIDSeq

      left outer join	  orders.Reason R (nolock)
        on				  CM.CreditReasonCode   = R.Code	
		
      left outer join     invoices.InvoiceItem II 
        on                CMI.InvoiceITEMIDSeq  = II.IDSeq

      left outer join     invoices.InvoiceGroup IG
        on                II.InvoiceGroupIDSeq = IG.IDSeq

      inner join          customers.[Property] P (nolock)
        on                I.PropertyIDSeq = P.IDSeq

      inner join          customers.[Company] C (nolock)
        on                I.CompanyIDSeq = C.IDSeq
      
      inner join          customers.[Account] AC (nolock)
        on                AC.CompanyIDSeq = C.IDSeq
        and               AC.ActiveFlag = 1
      inner join          customers.Address CA (nolock)
        on                CA.CompanyIDSeq=c.IDSeq  
	left outer join customers.[Country] CAC with (nolock) on CAC.[Code]=CA.[CountryCode]

      inner join          customers.[Address] PA (nolock) 
        on                PA.PropertyIDSeq = P.IDSeq 

      where               CM.CreditMemoIDSeq =  @IPBI_CreditIDSeq
      /*************************************************************************************/
  end 
end
GO
