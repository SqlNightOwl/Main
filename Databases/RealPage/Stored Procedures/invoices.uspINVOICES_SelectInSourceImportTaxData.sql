SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [invoices].[uspINVOICES_SelectInSourceImportTaxData] (@LI_Month SMALLINT,
                                                              @LI_Year  SMALLINT
                                                             )
AS 
BEGIN ---> Main Begin
  ----------------------------------------------------------------------------------------- 
  --procedure  : uspINVOICES_SelectInSourceImportTaxData
  -- DATABASE: INVOICES
  --Purpose:  This stored procedure takes the following arguments and
  --          returns the data required for the INsource import program.  
  --          It returns only states in which we are registered to tax 
  --          as populated in the table:  INVOICES.dbo.TAXABLE_STATES.
  --
  -- parameters : @LI_Month  SMALLINT		-- month
  --              @LI_Year SMALLINT		-- 4 digit year
  -- returns    : invoice and credit memo item detail the InSource Import is expecting
  -- example of how to call procedure:
  -- EXEC INVOICES.dbo.uspINVOICES_SelectInSourceImportTaxData 10, 2007
  -- Date         Author                  Comments
  -- -----------  -------------------     --------------------------- 
  -- 2007/12/06	Gwen Guidroz			Initial Creation
  --
  -- Copyright  : copyright (c) 2000.  RealPage Inc.
  -- This module is the confidential & proprietary property of RealPage Inc.
  ----------------------------------------------------------------------------------------- 
  set nocount on
  ----------------------------------------
  declare @LD_RunDateTime datetime
  set @LD_RunDateTime = getdate()

  declare @LD_BegApplyDate          smalldatetime
  declare @LD_EndApplyDate          smalldatetime
  declare @LI_EpicorBegApplyDateInt int
  declare @LI_EpicorEndApplyDateInt int

  set @LD_BegApplyDate = CAST(@LI_Month AS VARCHAR(2))+'/01/'+ CAST(@LI_Year AS VARCHAR(4))
  set @LD_EndApplyDate = dateadd(dd, -1, dateadd(mm, 1, @LD_BegApplyDate))
  set @LI_EpicorBegApplyDateInt = datediff(dd,'1/1/1753',@LD_BegApplyDate) + 639906
  set @LI_EpicorEndApplyDateInt = datediff(dd,'1/1/1753',@LD_EndApplyDate) + 639906
  
  --------------------------------------------------------------------------------------------
  SELECT 
         i.ShipToState     AS [State]	
         ,convert(varchar(10), @LD_BegApplyDate, 101) AS [Period Beginning]
         ,convert(varchar(10), @LD_EndApplyDate, 101) AS [Period Ending]
         ,CASE	WHEN isnull(ii.TaxwarePrimaryStateJurisdictionZipcode,'') = '' 
	           THEN	CASE i.ShipToState			
		          WHEN 'TX' 
                             THEN CASE CHARINDEX('-',g.addr3)
	  	                     WHEN 0 then right(g.addr3,5) 
		                     else substring(g.addr3, CHARINDEX('-',g.addr3) - 5, 5) 
	                          END--For Texas sales, the ship from address is used rather than this ship to address
		          ELSE left(i.ShipToZip,5) 
	                END
	        ELSE left(ii.TaxwarePrimaryStateJurisdictionZipcode,5)
         END as [Zipcode] 
        ,isnull(TaxwarePrimaryCityJurisdiction,'')   as [City Name] 
        ,isnull(TaxwarePrimaryCountyJurisdiction,'') as [County Name] 
        ,'RPI' AS [Location Code]
        ,'RPI' AS [Company Name]
        --, STR(SUM(case c.CreditTypeCode when 'TAXC' then 0  -- tax only credits should have $0 GROSS
        -- convert credits to negative
        ,STR(SUM(ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0)),15,2) AS 'Gross'-- net before tax + freight
        ,CASE TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN '0101' WHEN 'U' THEN '0104' ELSE '' END as [Tax Category Code]
        ,STR(SUM(CASE TaxwarePrimaryStateSalesUseTaxIndicator 
		     WHEN 'S' THEN (ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0))
		     ELSE 0 
		 END),15,2) as 'Gross Sales'	-- gross sales subject to sales tax
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator 
		     when 'U' THEN (ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0))
		     ELSE 0 END),15,2) as 'Gross Sales Subject to Use'	-- gross sales subject to use tax
         ------------ 'Exempt Amount' BELOW
         ,STR(SUM(CAST((ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0)) as decimal(15,2)) --Gross
  	                - isnull(ii.TaxwarePrimaryStateTaxBasisAmount,0)),15,2) --LESS Taxable
         AS 'Exempt Amount'
         ----------- 'Exempt Sales' BELOW
        ,STR(SUM(CASE TaxwarePrimaryStateSalesUseTaxIndicator 
		     when 'S' then CAST((ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0))as decimal(15,2))  --Gross
  		  					- (isnull(ii.TaxwarePrimaryStateTaxBasisAmount,0)) --Taxable
		     else 0
		end),15,2) as 'Exempt Sales'
        ,STR(0.00,15,2) as 'GSSU deductions-Sales For Resale'
        ---------- 'Exempt Sellers Use' BELOW
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator 
		     WHEN 'U' then CAST((ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0)) as decimal(15,2)) --Gross
  					- isnull(ii.TaxwarePrimaryStateTaxBasisAmount,0) --Taxable
		     ELSE 0
		END),15,2) as 'Exempt Sellers Use'
        ---------------------------------------------------
        ,STR(SUM(isnull(ii.TaxwarePrimaryStateTaxBasisAmount,0)),15,2) as 'Taxable'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator when 'S' then isnull(ii.TaxwarePrimaryStateTaxBasisAmount,0)
		     ELSE 0
		 end),15,2) as 'Taxable Sales'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator when 'U' then isnull(ii.TaxwarePrimaryStateTaxBasisAmount,0)
		     ELSE 0
		 end),15,2) as 'Taxable Sellers Use'
        ,STR(SUM(isnull(ii.TaxAmount,0)),15,2) as 'Total Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN isnull(ii.TaxwarePrimaryStateTaxAmount,0) 
		     ELSE 0 END),15,2) as 'State Sales Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN isnull(ii.TaxwarePrimaryCountyTaxAmount,0) 
		     ELSE 0 END),15,2) as 'County Sales Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN isnull(ii.TaxwarePrimaryCityTaxAmount,0) 
		     ELSE 0 END),15,2) as 'City Sales Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN isnull(ii.TaxwareSecondaryCountyTaxAmount,0) 
		     ELSE 0 END),15,2) as 'County Transit Sales Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN isnull(ii.TaxwareSecondaryCityTaxAmount,0) 
		     ELSE 0 END),15,2) as 'City Transit Sales Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN isnull(ii.TaxAmount,0) 
		     ELSE 0 END),15,2) as 'Total Sales Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'U' THEN isnull(ii.TaxwarePrimaryStateTaxAmount,0) 
		     ELSE 0 END),15,2) as 'State Sellers Use Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'U' THEN isnull(ii.TaxwarePrimaryCountyTaxAmount,0) 
		     ELSE 0 END),15,2) as 'County Sellers Use Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'U' THEN isnull(ii.TaxwarePrimaryCityTaxAmount,0) 
		     ELSE 0 END),15,2) as 'City Sellers Use Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'U' THEN isnull(ii.TaxwareSecondaryCountyTaxAmount,0) 
		     ELSE 0 END),15,2) as 'County Transit Sellers Use Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'U' THEN isnull(ii.TaxwareSecondaryCityTaxAmount,0) 
		     ELSE 0 END),15,2) as 'City Transit Sellers Use Tax'
        ,STR(SUM(case TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'U' THEN isnull(ii.TaxAmount,0) 
		     ELSE 0 END),15,2) as 'Total Sellers Use Tax'
        ,'14' as 'Back Calculation Code'
        ,case WHEN ii.TaxwareSecondaryStateJurisdictionZipCode is not null 
		     AND ISNULL(ii.TaxwarePrimaryStateJurisdictionZipcode,'') <> ii.TaxwareSecondaryStateJurisdictionZipCode
		THEN LEFT(ISNULL(ii.TaxwarePrimaryStateJurisdictionZipcode,''),5)	--shipped outside of Texas
	      ELSE ''
	 END AS [ZIP Code of Jurisdiction]	-- For Texas ship to's this is the ship from zip code (origin zip code)
        ,case WHEN ii.TaxwareSecondaryStateJurisdictionZipCode is not null 
		    AND ISNULL(ii.TaxwarePrimaryStateJurisdictionZipcode,'') <> ii.TaxwareSecondaryStateJurisdictionZipCode
		THEN LEFT(ii.TaxwareSecondaryStateJurisdictionZipCode,5)	--shipped outside of Texas
	      ELSE ''
	 END AS [Sec ZIP Code of Jurisdiction]	-- For Texas ship to's this is the ship to zip code (destination zip code)
        ,case WHEN ii.TaxwareSecondaryStateJurisdictionZipCode is not null 
	  	    AND ISNULL(ii.TaxwarePrimaryStateJurisdictionZipcode,'') <> ii.TaxwareSecondaryStateJurisdictionZipCode
		THEN 'X'
	      ELSE ''
	 END AS [MultipleJurisZipIndicator]	-- For Texas ship to's, this should be Y to indicate different origin/destination zip codes
        ,@LD_RunDateTime as [RunDateTime]
       ---------------------------------------------------------  
       -------details for testing only
       --,x.trx_ctrl_num as [Invoice]
       --,ii.IDSeq
       ----------------------------------------------------------
  from       OMSREPORTS.DBO.[artrx]    x with (nolock)
  inner	join INVOICES.dbo.Invoice      i with (nolock) 
  on          x.doc_ctrl_num = i.InvoiceIDSeq and x.trx_type='2031'
  and         x.date_applied >= @LI_EpicorBegApplyDateInt
  and         x.date_applied <= @LI_EpicorEndApplyDateInt
  inner join INVOICES.dbo.InvoiceItem ii (NOLOCK) 
  ON          i.InvoiceIDSeq = ii.InvoiceIDSeq
  AND         (ABS(ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0)) > 0
 	                OR	
               ABS(ii.TaxAmount) > 0
              )
  inner join INVOICES.dbo.TaxableStates TS (NOLOCK) ON i.ShipToState = TS.State
  left outer join OMSREPORTS.DBO.[glco] g on g.company_id = 1
  -------------------------------------------------------------------------------
  WHERE  x.date_applied >= @LI_EpicorBegApplyDateInt
  and    x.date_applied <= @LI_EpicorEndApplyDateInt
  and    x.trx_type='2031'
  and (ABS(ii.NetChargeAmount + isnull(ii.ShippingAndHandlingAmount,0)) > 0
 	     OR	
       ABS(ii.TaxAmount) > 0
      )
  -------------------------------------------------------------------------------
  GROUP BY i.ShipToState
           ,CASE WHEN isnull(ii.TaxwarePrimaryStateJurisdictionZipcode,'') = '' 
	           THEN	CASE i.ShipToState			
		          WHEN 'TX' 
                             THEN CASE CHARINDEX('-',g.addr3)
	  	                     WHEN 0 then right(g.addr3,5) 
		                     else substring(g.addr3, CHARINDEX('-',g.addr3) - 5, 5) 
	                          END--For Texas sales, the ship from address is used rather than this ship to address
		          ELSE left(i.ShipToZip,5) 
	                END
	        ELSE left(ii.TaxwarePrimaryStateJurisdictionZipcode,5)
            END 
           ,isnull(TaxwarePrimaryCityJurisdiction,'')
           ,isnull(TaxwarePrimaryCountyJurisdiction,'')
           ,CASE TaxwarePrimaryStateSalesUseTaxIndicator WHEN 'S' THEN '0101' WHEN 'U' THEN '0104' ELSE '' END
           ,ii.TaxwarePrimaryCityJurisdiction
           ,ii.TaxwarePrimaryStateJurisdictionZipcode
           ,ii.TaxwareSecondaryStateJurisdictionZipCode
  -------------------------------------------------------------------------------
  order by i.ShipToState
           ,CASE WHEN isnull(ii.TaxwarePrimaryStateJurisdictionZipcode,'') = '' 
	           THEN	CASE i.ShipToState			
		          WHEN 'TX' 
                             THEN CASE CHARINDEX('-',g.addr3)
	  	                     WHEN 0 then right(g.addr3,5) 
		                     else substring(g.addr3, CHARINDEX('-',g.addr3) - 5, 5) 
	                          END--For Texas sales, the ship from address is used rather than this ship to address
		          ELSE left(i.ShipToZip,5) 
	                END
	        ELSE left(ii.TaxwarePrimaryStateJurisdictionZipcode,5)
            END
           ,isnull(TaxwarePrimaryCityJurisdiction,'')
           ,isnull(TaxwarePrimaryCountyJurisdiction,'')
   -------------------------------------------------------------------------------
END ---> Main End

GO
