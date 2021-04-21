SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- procedure  : [uspTAXRECALCINVOICES_InvoiceItemSelect]
-- purpose    : acquire items in a single group of an invoice
-- parameters : identify one Group within an Invoice
-- returns    : a set of invoice items
-- remarks    : exec Invoices.dbo.uspTAXRECALCINVOICES_InvoiceItemSelect @IPVC_InvoiceID = 'I1106000092'
	Observe that in this procedure, no control bits are even looked at. 
	Here we are given an InvoiceID, because the FindWork procedure determined that this invoice needs work. 
	Thus we are obliged to return all Invoice Items that are attached to said Invoice, without regard for whether 
	they seem to need recalculation, or whether recalculation has already been done.  Those two bits may be in
	any state, in various situations.  Here, it just doesn't matter. 
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2011-11-19   LWW             TFS 1657-catch up with inner [uspINVOICES_TaxableInvoiceItemsSelect], two added columns
-- 2011-06-15   SRS             TFS 725
-- 2010-04-12   Larry Wilson    Fold in resultset from regular Invoices proc, acquiring Denver algorithm (PCR-7522)
-- 2010-02-18   Larry Wilson    Add new TaxwareCompanyCode to result set (PCR-7522)
-- 2009-09-18   Larry Wilson        revised: test new filter conditions (PCR-6250)
-- 2007-11-26   Eric Font           initial implementation
--
-- Copyright  : copyright (c) 2010.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_InvoiceItemSelect] (@IPVC_InvoiceID        varchar(50),
                                                                 @IPI_InvoiceGroupIDSeq varchar(50)   ='',
                                                                 @IPVC_ChargeTypeCode   varchar(20)   ='',
                                                                 @IPI_CustomBundleNameEnabledFlag int = 0)
AS
BEGIN
    set nocount on;
/*
	Because there is business logic embedded in mainline proc [uspINVOICES_TaxableInvoiceItemsSelect], 
	which is also required here in this proc -- and yet we need a few more (and different) 
	columns in addition, here we catch the rows produced by the uspINVOICES proc, and then 
	add a few more, especially for TaxRecalc
*/
	DECLARE @invoiceLine table (
		 [AddressLine1]           varchar(255) NULL
		,[AddressLine2]           varchar(255) NULL
		,[City]                   varchar(70)  NULL
		,[State]                  varchar(8)   NULL
		,[Zip]                    varchar(10)  NULL
		,[CountryCode]            varchar(30)  NULL
		,[CustomerNumber]         varchar(11)  NULL
		,[InvoiceITemIDSeq]       bigint       NULL
		,[TaxWareCode]            varchar(50) NULL
		,[OrderItemIDSeq]         bigint      NULL
		,[FreightAmount]          money       NULL
		,[CreatedDate]            datetime    NULL
		,[NetChargeAmount]        money       NULL
		,[Taxablecounty]          varchar(70) NULL
                ,[TaxableCountryCode]     varchar(10) NULL
		,[TaxableAddressTypeCode] varchar(10) NULL
		,[TaxwareCompanyCode]     varchar(10) NULL
                ,[CalculateTaxFlag]       int         NULL
         ,[OrderIDSeq] varchar(22) NULL
         ,[OrderGroupIDSeq] bigint NULL
	)
	INSERT @invoiceLine ( 
		 [AddressLine1],[AddressLine2]
		,[City],[State],[Zip],[CountryCode]
		,[CustomerNumber]
		,[InvoiceITemIDSeq]
		,[TaxWareCode]
		,[OrderItemIDSeq]
		,[FreightAmount]
		,[CreatedDate]
		,[NetChargeAmount]
		,[Taxablecounty]
                ,[TaxableCountryCode]
		,[TaxableAddressTypeCode],[TaxwareCompanyCode]
                ,[CalculateTaxFlag]
         ,[OrderIDSeq]
         ,[OrderGroupIDSeq]
	) EXEC [dbo].[uspINVOICES_TaxableInvoiceItemsSelect] @IPVC_InvoiceID=@IPVC_InvoiceID
			                                    ,@IPI_InvoiceGroupIDSeq =@IPI_InvoiceGroupIDSeq
			                                    ,@IPVC_ChargeTypeCode=@IPVC_ChargeTypeCode
			                                    ,@IPI_CustomBundleNameEnabledFlag=1  -- force proc to fetch every item, although tax already calc
/*
	Next, fetch desired results from that proc's output and the InvoiceItems table
*/
	SELECT  l.[AddressLine1]                AS [AddressLine1]
		, l.[AddressLine2]              AS [AddressLine2]
		, l.[City]                      AS [City]
		, l.[CountryCode]               AS [CountryCode]
		, l.[CreatedDate]               AS [CreatedDate]
		, l.[CustomerNumber]            AS [CustomerNumber]
		, l.[TaxwareCompanyCode]        AS [TaxwareCompanyCode]
		, ii.[DefaultTaxwareCode]       AS [DefaultTaxwareCode]
		, l.[FreightAmount]             AS [FreightAmount]
		, l.[InvoiceITemIDSeq]          AS [InvoiceItemIDSeq]
		, l.[NetChargeAmount]           AS [NetChargeAmount]
		, l.[OrderItemIDSeq]            AS [OrderItemIDSeq]
		, ii.[RECALCNeeded]             AS [RECALCNeeded]
		, l.[State]                     AS [State]
		, l.[TaxableAddressTypeCode]    AS [TaxableAddressTypeCode]
		, l.[Taxablecounty]             AS [Taxablecounty]
		, l.[TaxWareCode]               AS [TaxwareCode]
		, l.[Zip]                       AS [Zip]
                , l.[TaxableCountryCode]        AS [TaxableCountryCode]
                , l.CalculateTaxFlag            as CalculateTaxFlag
	FROM @invoiceLine l
	LEFT OUTER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=l.[InvoiceITemIDSeq]

  RETURN(0)
END
GO
