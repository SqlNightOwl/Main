SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_PushTaxDetailToEpicor]
-- Description     : This procedure select tax data from invoiceitem table                
-- Revision History:
-- Author          : Shashi Bhsuhan
-- 03/13/2009      : Stored Procedure Created.
-- 09/08/2009      : Shashi Bhushan #6992 altered to select TaxableCountryCode column value
----------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_PushTaxDetailToEpicor]
   ( 
	 @TransactionIDSeq   varchar(22)
   )
AS
BEGIN
	select row_number() over(Order by II.TaxableCountryCode) as SequenceID,
           II.TaxableState,
		  SUM(II.NetChargeAmount + II.ShippingAndHandlingAmount) as TaxableAmount,
		  SUM(II.NetChargeAmount + II.ShippingAndHandlingAmount) as GrossAmount,
		  SUM(II.TaxAmount)       as TaxAmount,
		  SUM(II.TaxAmount)       as FinalTaxAmount,
          II.TaxableCountryCode   as TaxableCountryCode
	from invoices.dbo.invoiceitem II with (nolock) 
	where II.invoiceidseq = @TransactionIDSeq
    group by II.TaxableState,II.TaxableCountryCode
	 
END
GO
