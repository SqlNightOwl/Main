SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspCredits_CreditMemoItemUpdate]
-- Description     : This procedure gets the list of Credit Invoice Items for the list of ID's passed.
-- Input Parameters: @CreditAmount    numeric(10,2),
--                   @TaxAmount  numeric(10,2),@NetPrice    numeric(10,2),@CreditFieldStatus        bit          
--                   
-- OUTPUT          : RecordSet of IDSEq is generated
--
--                   
-- Code Example    : Exec Invoices..[uspCredits_CreditMemoItemUpdate] '242','','I0710000230','519','',12000,0,12000,'True','ACS','PartialCredit',13800
-- 
-- Revision History:
-- Author          : Shashi Bhushan
-- 10/11/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspCredits_CreditMemoItemUpdate] (
														  @CreditMemoIDSeq          varchar(50),
														  @CreditMemoItemIDSeq      bigint,
														  @InvoiceIDSeq			    varchar(22),
														  @InvoiceGroupIDSeq	    bigint,
														  @InvoiceItemIDSeq		    bigint,
														  @CreditAmount             numeric(10,2),
														  @TaxAmount                numeric(10,2),
														  @NetCreditAmount          numeric(10,2),
														  @CustomBundleNameEnabledFlag bit,
														  @ChargeTypeCode			varchar(3),
														  @CreditType               varchar(12),
														  @NetPrice                 numeric(10,2)						
														  )  
AS  
BEGIN ---------BEGIN OF CUSTOMBUNDLEENABLEDFLAG IS 0

   IF @CustomBundleNameEnabledFlag = 0
     BEGIN
	   IF @CreditMemoItemIDSeq <> ''
	     BEGIN  
		    UPDATE INVOICES..CREDITMEMOITEM 
		    SET    ExtCreditAmount = @CreditAmount, 
			       TaxAmount = @TaxAmount, 
                   NetCreditAmount = @NetCreditAmount
		    WHERE IDSeq = @CreditMemoItemIDSeq
	     END
	   ELSE
	     BEGIN 
		    INSERT INTO INVOICES..CREDITMEMOITEM (CreditMemoIDSeq, InvoiceItemIdSeq,InvoiceGroupIDSeq,CustomBundleNameEnabledFlag, 
		  	                                      UnitCreditAmount,EffectiveQuantity,ExtCreditAmount,TaxAmount,NetCreditAmount,InvoiceIDSeq)
		    VALUES (@CreditMemoIDSeq,@InvoiceItemIDSeq,@InvoiceGroupIDSeq,@CustomBundleNameEnabledFlag,
		  	        @CreditAmount,1,@CreditAmount,@TaxAmount, (@CreditAmount + @TaxAmount), @InvoiceIDSeq)
	     END
    END---------END OF CUSTOMBUNDLEENABLEDFLAG IS 0
ELSE 
  BEGIN---------BEGIN OF CUSTOMBUNDLEENABLEDFLAG IS 1 
    --------------------------------------------------------
    -- Declaring Local Variables
    --------------------------------------------------------
	DECLARE @LV_Counter                int
	DECLARE @LV_RowCount               int
	DECLARE @GroupNetPriceAmount       money
	DECLARE @InvoiceItemNetPricePercent numeric(10,8)
	DECLARE @InvoiceItemCreditAmount   money
	DECLARE @InvoiceItemTaxAmount      money
	DECLARE @InvoiceItemNetPriceAmount money
    DECLARE @FinalCreditLineItem       money
    DECLARE @FinalCreditLineItemTax    money
		    
        ---------Getting the Invoice Items for the Custom Bundle        
    DECLARE @LT_InvoiceItemSummary TABLE (RowNumber         int identity(1,1),
                                          InvoiceItemIDSeq  bigint,
		                                  CreditItemIDSeq   bigint,
                                          CreditAmount      money,
                                          TaxAmount         money,
                                          NetPrice          money)

    INSERT INTO @LT_InvoiceItemSummary (InvoiceItemIDSeq,CreditItemIDSeq,CreditAmount,TaxAmount,NetPrice)
    SELECT II.IDSeq,CI.IDSeq,II.CreditAmount,II.TaxAmount,II.NetChargeAmount
    FROM   Invoices..InvoiceItem II
     INNER JOIN Invoices..CreditMemoItem CI
	 ON CI.InvoiceItemIDSeq = II.IDSeq
	WHERE II.InvoiceGroupIDSeq = @InvoiceGroupIDSeq
	 AND ChargeTypeCode = @ChargeTypeCode
	 AND CI.CreditMemoIDSeq = @CreditMemoIDSeq
	 ------------------------------------------------------------------------
	SELECT @GroupNetPriceAmount = SUM(NetPrice)
    FROM   @LT_InvoiceItemSummary

	IF @GroupNetPriceAmount = 0
	SELECT @GroupNetPriceAmount = 1

	SELECT @LV_RowCount = count(*) FROM @LT_InvoiceItemSummary
  
    SET @LV_Counter = 1
    SET @FinalCreditLineItem = 0
    SET @FinalCreditLineItemTax = 0
        
	IF ( @LV_RowCount > 0)       
       BEGIN----------------------BEGIN OF ROW COUNT IS > 0
	      WHILE @LV_Counter < = @LV_RowCount
		     BEGIN
			   SELECT @InvoiceItemIDSeq = InvoiceItemIDSeq, @CreditMemoItemIDSeq = CreditItemIDSeq FROM @LT_InvoiceItemSummary WHERE
			   RowNumber = @LV_Counter 
	           
               SELECT @InvoiceItemNetPricePercent = ((NetPrice/@GroupNetPriceAmount)*100)
			   FROM @LT_InvoiceItemSummary WHERE RowNumber = @LV_Counter 

   		       SELECT @InvoiceItemCreditAmount   = (@InvoiceItemNetPricePercent * @CreditAmount)/100,
			  	      @InvoiceItemTaxAmount      = (@InvoiceItemNetPricePercent * @TaxAmount )/100,
					  @InvoiceItemNetPriceAmount = (@InvoiceItemNetPricePercent * @NetPrice)/100
              
              IF ( @LV_Counter < @LV_RowCount)      
                BEGIN
                  SET  @FinalCreditLineItem = @FinalCreditLineItem + @InvoiceItemCreditAmount
                  SET  @FinalCreditLineItemTax = @FinalCreditLineItemTax + @InvoiceItemTaxAmount
                END
    
              IF (@LV_Counter = @LV_RowCount)
		       BEGIN
			      SET @InvoiceItemCreditAmount   = (@CreditAmount - @FinalCreditLineItem)
                  SET @InvoiceItemTaxAmount      = (@TaxAmount - @FinalCreditLineItemTax)
               END	 

						If(@CreditType='FullCredit')
									Begin
												Declare @ChargeAmount	 money
												Declare @ExtChargeAmount money
												Declare @DiscountAmount	 money
												Declare @TaxPercent	     numeric(30,5)
												Declare @FCTaxAmount	 money
												Declare @NetChargeAmount money

												SELECT @ChargeAmount = ChargeAmount, @ExtChargeAmount = ExtChargeAmount, @DiscountAmount = DiscountAmount,
													   @TaxPercent = TaxPercent, @FCTaxAmount = TaxAmount, @NetChargeAmount = NetChargeAmount
												FROM Invoices..InvoiceItem II (nolock)
												WHERE II.InvoiceIDSeq=@InvoiceIDSeq 
												and II.IDSeq=@InvoiceItemIdSeq
												and II.ChargeTypeCode = @ChargeTypeCode 								

												UPDATE Invoices..CreditMemoItem 
												SET    UnitCreditAmount = @ChargeAmount,ExtCreditAmount = @ExtChargeAmount,DiscountCreditAmount = @DiscountAmount,
													   TaxPercent = @TaxPercent,TaxAmount = @FCTaxAmount, NetCreditAmount = @NetChargeAmount                        
												WHERE IDSeq = @CreditMemoItemIDSeq										
									END

						ELSE
									BEGIN
   								 				UPDATE Invoices..CreditMemoItem 
													SET 
															UnitCreditAmount = @InvoiceItemCreditAmount,ExtCreditAmount = @InvoiceItemCreditAmount,
															DiscountCreditAmount = 0,
															TaxAmount = @InvoiceItemTaxAmount, 
															NetCreditAmount = (@InvoiceItemCreditAmount + @InvoiceItemTaxAmount)
													 WHERE IDSeq = @CreditMemoItemIDSeq										 									
									 END            
				SET @LV_Counter = @LV_Counter + 1
             END------------END OF WHILE LOOP
       END---------------END OF ROW COUNT IS > 0
      ELSE
	    BEGIN---------BEGIN OF ROW COUNT IS = 0	
		   INSERT INTO @LT_InvoiceItemSummary (
                                                InvoiceItemIDSeq,
				                                CreditItemIDSeq,  
                                                CreditAmount,
                                                TaxAmount,
                                                NetPrice
                                               )
		   SELECT II.IDSeq,NULL,II.CreditAmount,II.TaxAmount,II.NetChargeAmount
		   FROM   Invoices..InvoiceItem II
		   WHERE II.InvoiceGroupIDSeq = @InvoiceGroupIDSeq	AND ChargeTypeCode = @ChargeTypeCode												
								
		   SELECT @GroupNetPriceAmount = SUM(NetPrice)
		   FROM   @LT_InvoiceItemSummary

	       IF @GroupNetPriceAmount = 0
	       SELECT @GroupNetPriceAmount = 1

		   SELECT @LV_RowCount = count(*) FROM @LT_InvoiceItemSummary
           SET @LV_Counter = 1
				
		   WHILE @LV_Counter < = @LV_RowCount
		      BEGIN  
			     SELECT @InvoiceItemIDSeq = InvoiceItemIDSeq, @CreditMemoItemIDSeq = CreditItemIDSeq FROM @LT_InvoiceItemSummary WHERE
			            RowNumber = @LV_Counter 

			     SELECT @InvoiceItemNetPricePercent = ((NetPrice/@GroupNetPriceAmount)*100)
			     FROM   @LT_InvoiceItemSummary 
                 WHERE  RowNumber = @LV_Counter 

			     SELECT @InvoiceItemCreditAmount   = (@InvoiceItemNetPricePercent * @CreditAmount)/100,
				        @InvoiceItemTaxAmount      = (@InvoiceItemNetPricePercent * @TaxAmount )/100,
				        @InvoiceItemNetPriceAmount = (@InvoiceItemNetPricePercent * @NetPrice)/100

				 INSERT INTO Invoices..CreditMemoItem
                        (CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,CustomBundleNameEnabledFlag,
                        InvoiceItemIdSeq,UnitCreditAmount,EffectiveQuantity,ExtCreditAmount,DiscountCreditAmount,TaxPercent,
                        TaxAmount, NetCreditAmount,RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,
                        RevenueRecognitionCode,TaxwareCode,TaxwarePrimaryStateTaxPercent,TaxwarePrimaryStateTaxAmount,
                        TaxwareSecondaryStateTaxPercent,TaxwareSecondaryStateTaxAmount,TaxwarePrimaryCityTaxPercent,TaxwarePrimaryCityTaxAmount,
                        TaxwareSecondaryCityTaxPercent,TaxwareSecondaryCityTaxAmount,TaxwarePrimaryCountyTaxPercent,
                        TaxwarePrimaryCountyTaxAmount,TaxwareSecondaryCountyTaxPercent,TaxwareSecondaryCountyTaxAmount,
                        TaxwarePrimaryStateTaxBasisAmount,TaxwareSecondaryStateTaxBasisAmount,TaxwarePrimaryCityTaxBasisAmount,
                        TaxwareSecondaryCityTaxBasisAmount,TaxwarePrimaryCountyTaxBasisAmount,TaxwareSecondaryCountyTaxBasisAmount,
                        TaxwarePrimaryStateJurisdictionZipCode,TaxwareSecondaryStateJurisdictionZipCode,TaxwarePrimaryCityJurisdiction,
                        TaxwareSecondaryCityJurisdiction,TaxwarePrimaryCountyJurisdiction,TaxwareSecondaryCountyJurisdiction,
                        TaxwareCallOverrideFlag,ShippingAndHandlingCreditAmount,DefaultTaxwareCode)
                 SELECT @CreditMemoIDSeq,@InvoiceIDSeq,@InvoiceGroupIDSeq,@CustomBundleNameEnabledFlag,
                        @InvoiceItemIdSeq,@InvoiceItemCreditAmount,1,@InvoiceItemCreditAmount,0,TaxPercent,
                        @InvoiceItemTaxAmount,(@InvoiceItemCreditAmount + @InvoiceItemTaxAmount),RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,
                        RevenueRecognitionCode,TaxwareCode,TaxwarePrimaryStateTaxPercent,TaxwarePrimaryStateTaxAmount,
                        TaxwareSecondaryStateTaxPercent,TaxwareSecondaryStateTaxAmount,TaxwarePrimaryCityTaxPercent,
                        TaxwarePrimaryCityTaxAmount,TaxwareSecondaryCityTaxPercent,TaxwareSecondaryCityTaxAmount,
                        TaxwarePrimaryCountyTaxPercent,TaxwarePrimaryCountyTaxAmount,TaxwareSecondaryCountyTaxPercent,
                        TaxwareSecondaryCountyTaxAmount,TaxwarePrimaryStateTaxBasisAmount,TaxwareSecondaryStateTaxBasisAmount,
                        TaxwarePrimaryCityTaxBasisAmount,TaxwareSecondaryCityTaxBasisAmount,TaxwarePrimaryCountyTaxBasisAmount,
                        TaxwareSecondaryCountyTaxBasisAmount,TaxwarePrimaryStateJurisdictionZipCode,TaxwareSecondaryStateJurisdictionZipCode,
                        TaxwarePrimaryCityJurisdiction,TaxwareSecondaryCityJurisdiction,TaxwarePrimaryCountyJurisdiction,
                        TaxwareSecondaryCountyJurisdiction,TaxwareCallOverrideFlag,ShippingAndHandlingAmount,DefaultTaxwareCode
                 FROM Invoices..InvoiceItem (nolock)
                 WHERE InvoiceIDSeq=@InvoiceIDSeq and IDSeq=@InvoiceItemIdSeq and ChargeTypeCode = @ChargeTypeCode	

				SET @LV_Counter = @LV_Counter + 1
		   END----------END OF WHILE		
	    END--------------------END OF ROW COUNT IS = 0			
  END--------------END OF CUSTOMBUNDLEENABLEDFLAG IS 1
END  
------------------------------------------------------------------------------------------------------
GO
