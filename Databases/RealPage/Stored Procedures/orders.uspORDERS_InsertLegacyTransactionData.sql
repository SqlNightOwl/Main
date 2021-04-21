SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

Create Procedure [orders].[uspORDERS_InsertLegacyTransactionData]
--drop Procedure uspInsertScreeningData
@BillingCycleDate DATETIME
As
--
--/*	Created On : 1/8/07
--	Created By : Vidhya Venkatapathy
--	Purpose    : To insert Third party Transaction data in new system as Orders, Invocies
--*/
--
--[uspORDERS_InsertLegacyTransactionData] '11/30/2006'

BEGIN
 
DECLARE 
	
	@TotalAccounts BIGINT,
	@ProcessedAccounts INT ,
	@OrderIDSq VARCHAR(50),
	@AccountIDSeq VARCHAR(11),
	@OrderGoupIdSeq BIGINT,
	@OrderItemID BIGINT,
	@IsSite BIGINT,
	@error INT,
	@TransactionError INT,
	@OrderItemIDSeq bigint
--	--Initialize Variables
--SET @BillingCycleDate ='12/31/2006'
	Set @TotalAccounts = 0
	Set @ProcessedAccounts = 0
	Set	@TotalAccounts= 0
	Set	@ProcessedAccounts= 0
	Set	@OrderIDSq ='0'
	Set	@AccountIDSeq = ''
	Set	@OrderGoupIdSeq =0
	Set	@OrderItemID = 0

-----Error Checking: 
------See if CLRAccountID (Epicor) number Exists in CUSTOMERS.dbo.Account 
------this Query inserts Error Records INTO TRANSACTIONSSTAGING.dbo.TransactionErrors 

	INSERT INTO TRANSACTIONSSTAGING.dbo.TransactionErrors
	(	TransactionType,
		TransactionID,
		CLRAccountID,
		DateShipped,
		Error,
		Created
	)
	SELECT 'AS_Invoice' 'TransactionType', TransactionID, CLRAccountID, DateShipped,
	'No match found in CUSTOMERS.dbo.Account for EpicorCustomerCode = ' + CLRAccountID + ' And DateShipped >= StartDate and DateShipped <= EndDate' 'Error'
	,getDate() 'Created'
	FROM TRANSACTIONSSTAGING.dbo.AS_Invoice S(NOLOCK)
	WHERE (MONTH(BillingCycleDate) = MONTH(@BillingCycleDate) 
		AND YEAR(BillingCycleDate) = YEAR(@BillingCycleDate))
		AND SentToOrders = 0 
		AND  NOT EXISTS(SELECT 1 FROM CUSTOMERS.dbo.Account a (NOLOCK)
						WHERE S.CLRAccountID = a.EpicorCustomerCode 
						AND  (S.DateShipped >= a.StartDate
						AND (S.DateShipped <= a.EndDate or a.EndDate IS NULL))
						)

		IF (@@error<>0 ) 
		BEGIN  
			Return select '[uspORDERS_InsertLegacyTransactionData]' as 'DB Operation',
			XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
		END
 
-----Create a temp table to hold distinct accounts
	DECLARE @Accounts as Table(
		CLRAccountID VARCHAR(15),
		AccountIDSeq VARCHAR(11),
		CompanyIDSeq VARCHAR(11),
		PropertyIDSeq VARCHAR(11),
		SentToOrder BIT,IsSite BIT
		)

----Inserts Distinct Accounts in Temptable	
----This below Query inserts only property (Site and Standalone Sites)
	INSERT INTO @Accounts (CLRAccountID, AccountIDSeq, CompanyIDSeq,	PropertyIDSeq, SentToOrder,IsSite)
	SELECT Distinct S.CLRAccountID,
			a.IDSeq 'AccountIDSeq',
			a.CompanyIDSeq ,
			a.PropertyIDSeq,0,1	
	FROM TRANSACTIONSSTAGING.dbo.AS_Invoice S(NOLOCK)
	INNER JOIN CUSTOMERS.dbo.Account a (NOLOCK) ON S.CLRAccountID = a.EpicorCustomerCode 
			AND  (S.DateShipped >= a.StartDate
			AND (S.DateShipped <= a.EndDate or a.EndDate IS NULL))
			AND ISNULL(PropertyIDSeq,'') <> '' 
	WHERE (MONTH(BillingCycleDate) = MONTH(@BillingCycleDate) 
		AND YEAR(BillingCycleDate) = YEAR(@BillingCycleDate))
		AND SentToOrders = 0 
	
	IF (@@error<>0 ) 
		BEGIN  
			Return select '[uspORDERS_InsertLegacyTransactionData]' as 'DB Operation',
			XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
		END
--This below Query inserts only Home Office (PMC)

	INSERT INTO @Accounts (CLRAccountID, AccountIDSeq, CompanyIDSeq,PropertyIDSeq, SentToOrder,IsSite)
	SELECT Distinct S.CLRAccountID,
			a.IDSeq 'AccountIDSeq',
			a.CompanyIDSeq ,
			a.PropertyIDSeq,0,0	
	FROM TRANSACTIONSSTAGING.dbo.AS_Invoice S(NOLOCK)
	INNER JOIN CUSTOMERS.dbo.Account a (NOLOCK) ON S.CLRAccountID = a.EpicorCustomerCode
			AND  (S.DateShipped >= a.StartDate
			AND (S.DateShipped <= a.EndDate or a.EndDate IS NULL))
			AND ISNULL(PropertyIDSeq,'') = '' 
	WHERE (MONTH(BillingCycleDate) = MONTH(@BillingCycleDate) 
		AND YEAR(BillingCycleDate) = YEAR(@BillingCycleDate))
		AND SentToOrders = 0 
		AND NOT EXISTS (SELECT 1 FROM @Accounts t 
						WHERE S.CLRAccountID = t.CLRAccountID )
	
	IF (@@error<>0 ) 
		BEGIN  
			Return select '[uspORDERS_InsertLegacyTransactionData]' as 'DB Operation',
			XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
		END
	
	
----Get total counts from @Accounts to start the loop	
	
	SELECT @TotalAccounts = COUNT(*) from @Accounts 


----Start the loop to insert data in Orders

	DECLARE @Productinfo AS TABLE( 
			IsInState	VARCHAR(1),	
			ProductCode VARCHAR(30),
			ChargeTypeCode VARCHAR(3),
			MeasureCode VARCHAR(6),
			PriceVersion FLOAT,
			FreqCode VARCHAR(6),
			OrderItemIdSeq BIGINT)
		
	INSERT INTO @Productinfo(IsInState, ProductCode, ChargeTypeCode, MeasureCode, PriceVersion, FreqCode)
	SELECT
			CASE p.[Name] WHEN 'Applicant Screening-In State' THEN 'Y' ELSE 'N'  END,
			p.Code, 
			c.ChargeTypeCode,
			c.MeasureCode,
			c.PriceVersion,
			c.FrequencyCode
	FROM products.dbo.Product p(NOLOCK)
	INNER JOIN products.dbo.charge c (NOLOCK) on  c.productcode = p.Code --'PRM-LEG-LEG-LEG-LASI'
                                                  and c.priceversion= p.priceversion
	WHERE p.[Name] in ('Applicant Screening-In State','Applicant Screening-Out of state')
		
	IF (@@error<>0 ) 
		BEGIN  
			Return select '[uspORDERS_InsertLegacyTransactionData]' as 'DB Operation',
			XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
		END

	
WHILE (@TotalAccounts > @ProcessedAccounts) --Start Loop
	BEGIN
		BEGIN TRY		
			Set @ProcessedAccounts= @ProcessedAccounts + 1
			Select @AccountIDSeq= MAX(AccountIDSeq) from @Accounts Where SentToOrder =0
		
			---Check for Existing Order 				
			SELECT @OrderIDSq = O.OrderIDSeq , @OrderGoupIdSeq = i.OrderGroupIDSeq, @IsSite = t.IsSite
			FROM ORDERS.dbo.[Order] O (NOLOCK)
			INNER JOIN @Accounts t  on t.CompanyIDSeq = O.CompanyIDSeq 
					AND t.PropertyIDSeq = O.PropertyIDSeq 
					AND t.AccountIDSeq = O.AccountIDSeq
					AND t.AccountIDSeq = @AccountIDSeq
			INNER JOIN ORDERS.dbo.OrderItem i(NOLOCK) ON O.OrderIDSeq = i.OrderIDSeq AND i.StatusCode='APPR'
			WHERE EXISTS(Select 1 from @Productinfo p Where p.ProductCode = i.ProductCode )
				
			BEGIN TRAN					
				IF (ISNULL(@OrderIDSq,'')='') --Insert Order hdr
					BEGIN
                                           begin TRY;
                                             BEGIN TRANSACTION;
                                               update ORDERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
                                               set    IDSeq = IDSeq+1,
                                                      GeneratedDate =CURRENT_TIMESTAMP
          
                                               select @OrderIDSq = OrderIDSeq
                                                from   ORDERS.DBO.IDGenerator with (NOLOCK)  
						Select @IsSite=IsSite from @Accounts t where AccountIDSeq = @AccountIDSeq 							
						INSERT INTO ORDERS.dbo.[Order]
						(	
                                                        OrderIDSeq,
                                                        AccountIDSeq
							,CompanyIDSeq
							,PropertyIDSeq
							,StatusCode
							,CreatedBy
							,ModifiedBy
							,ApprovedBy	
						)			
						SELECT  @OrderIDSq,
							t.AccountIDSeq,
							t.CompanyIDSeq,
							t.PropertyIDSeq,
							'APPR',
							'sa',
							'sa',
							'sa'						
						FROM  @Accounts t  
						WHERE t.AccountIDSeq = @AccountIDSeq						
						
					      COMMIT TRANSACTION;       
                                             end TRY
					     begin CATCH;					        
					        Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Insert Legacy Transaction: New OrderID Generation failed'       
					           -- XACT_STATE:
					              -- If 1, the transaction is committable.
					              -- If -1, the transaction is uncommittable and should be rolled back.
					              -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
					        if (XACT_STATE()) = -1
					        begin
					          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
					        end
					        else if (XACT_STATE()) = 1
					        begin
					          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
					        end                 
					      end CATCH;				
						
						INSERT INTO ORDERS.dbo.OrderGroup ----Insert Order Group
						(OrderIDSeq, [Name], Description, OrderGroupType)
						SELECT @OrderIDSq,'Applicant Screening', 'Applicant Screening','AS Import'
					
												
						SELECT @OrderGoupIdSeq = @@identity
						IF (@IsSite = 1)
							BEGIN								
								INSERT INTO ORDERS.dbo.OrderGroupProperties		----Insert Order Properties			
								(AccountIDSeq, OrderIDSeq, OrderGroupIDSeq, CompanyIDSeq, PropertyIDSeq)				
								SELECT AccountIDSeq, @OrderIDSq, @OrderGoupIdSeq, CompanyIDSeq, PropertyIDSeq  
								FROM @Accounts WHERE AccountIDSeq = @AccountIDSeq								
							END
					END --EndCreating New Order info.
				
		 --Insert OrderItem
				DECLARE @OrderItem AS TABLE (OrderItemIDSeq BIGINT,IsInState VARCHAR(1),ProductCode VARCHAR(30))			
				
				INSERT INTO @OrderItem (IsInState,ProductCode)
				SELECT DISTINCT S.InStateFlag , p.ProductCode
				FROM TRANSACTIONSSTAGING.dbo.AS_Invoice S(NOLOCK)
				INNER JOIN @Accounts t  ON t.CLRACCOUNTID = S.CLRACCOUNTID 
				INNER JOIN @Productinfo p ON p.IsInstate = S.InStateFlag 
				WHERE (MONTH(BillingCycleDate) = MONTH(@BillingCycleDate) 
						AND YEAR(BillingCycleDate) = YEAR(@BillingCycleDate))
						AND SentToOrders = 0 
						AND t.AccountIDSeq = @AccountIDSeq				
								
				INSERT INTO [ORDERS].dbo.[OrderItem]
					(OrderIDSeq
					,OrderGroupIDSeq					
					,ProductCode
					,ChargeTypeCode
					,FrequencyCode
					,MeasureCode
					,PriceVersion
					,StatusCode
					)
				SELECT DISTINCT @OrderIDSq,
					   @OrderGoupIdSeq,
						P.ProductCode ,
						P.ChargeTypeCode ,
						P.FreqCode ,
						P.MeasureCode ,
						P.PriceVersion ,
						'APPR' 		
				FROM TRANSACTIONSSTAGING.dbo.AS_Invoice S(NOLOCK)
				INNER JOIN @Accounts t  ON t.CLRACCOUNTID = S.CLRACCOUNTID 
				INNER JOIN @Productinfo p ON p.IsInstate = S.InStateFlag		
				WHERE (MONTH(BillingCycleDate) = MONTH(@BillingCycleDate) 
						AND YEAR(BillingCycleDate) = YEAR(@BillingCycleDate))
						AND SentToOrders = 0 
						AND AccountIDSeq = @AccountIDSeq
						AND NOT EXISTS(	Select 1 from [ORDERS].dbo.[OrderItem] oi (NOLOCK) 
										INNER JOIN @OrderItem f ON oi.ProductCode=f.ProductCode										
										WHERE oi.OrderIDSeq = @OrderIDSq 
											AND oi.OrderGroupIdSeq = @OrderGoupIdSeq
										)
				
				Update t
				Set t.OrderItemIdSeq = i.IDSeq
				From @OrderItem t 
				INNER JOIN [ORDERS].dbo.[OrderItem] i (Nolock) ON t.ProductCode = i.ProductCode										
				WHERE i.OrderIDSeq = @OrderIDSq 
				AND i.OrderGroupIdSeq = @OrderGoupIdSeq
				
				
				INSERT INTO Orders.dbo.OrderItemTransaction
				(	OrderIDSeq
					,OrderGroupIDSeq
					,OrderItemIDSeq						
					,ProductCode
					,ChargeTypeCode
					,FrequencyCode
					,MeasureCode
					,ServiceCode
					,TransactionItemName
					,ExtChargeAmount
					,DiscountAmount
					,NetChargeAmount
					,ServiceDate
					,SourceTransactionID
				)
				SELECT @OrderIDSq,
					@OrderGoupIdSeq,
					i.OrderItemIDSeq,
					p.ProductCode,
					p.ChargeTypeCode,
					p.FreqCode,
					p.MeasureCode ,
					ISNULL(S.LegendCode,'')
					,S.Description, 
					S.GrossAmount, --Ext			
					S.DiscountAmount * -1, --Discount
					S.GrossAmount + S.DiscountAmount, --Net
					cast(convert(varchar, S.DateShipped , 101) as datetime),
					S.TransactionID	
				FROM TRANSACTIONSSTAGING.dbo.AS_Invoice S(NOLOCK)
				INNER JOIN @Accounts t  ON t.CLRACCOUNTID = S.CLRACCOUNTID 
				INNER JOIN @Productinfo p ON p.IsInstate = S.InStateFlag 
				INNER JOIN @OrderItem i ON i.ProductCode = p.ProductCode		
				WHERE (MONTH(BillingCycleDate) = MONTH(@BillingCycleDate) 
					AND YEAR(BillingCycleDate) = YEAR(@BillingCycleDate))
					AND SentToOrders = 0 
					AND AccountIDSeq = @AccountIDSeq
				
		
				Declare @summary as table (Quantity decimal(18,2), ExtChargeAmount money, DiscountAmount money, 
								NetChargeAmount money,ProductCode varchar(30))
				INSERT INTO @summary
				SELECT 	Count(*),SUM(ExtChargeAmount),SUM(DiscountAmount),SUM(NetChargeAmount),I.ProductCode
				FROM Orders.dbo.OrderItemTransaction I (NOLOCK)
				INNER JOIN @OrderItem f ON I.ProductCode  =f.ProductCode										
				WHERE I.OrderIDSeq = @OrderIDSq 
					AND I.OrderGroupIDSeq = @OrderGoupIdSeq 
				GROUP BY I.ProductCode

				
				UPDATE oi
				SET  Quantity		 = t.Quantity
					,ExtChargeAmount = t.ExtChargeAmount
					,DiscountAmount  = t.DiscountAmount
					,NetChargeAmount = t.NetChargeAmount
				FROM Orders.dbo.OrderItem oi (NOLOCK)
				INNER JOIN @summary t ON t.ProductCode =oi.ProductCode
				WHERE oi.OrderIDSeq = @OrderIDSq 
					AND oi.OrderGroupIdSeq = @OrderGoupIdSeq 				
				
				UPDATE a
				SET a.SentToOrder = 1 
				FROM @Accounts a WHERE AccountIDSeq = @AccountIDSeq			
				
				
				UPDATE i
				SET i.SentToOrders = a.SentToOrder 
				FROM TRANSACTIONSSTAGING.dbo.As_Invoice i 
				INNER JOIN @Accounts a ON a.CLRAccountID = i.CLRAccountID
							and a.AccountIDSeq = @AccountIDSeq
				WHERE (MONTH(BillingCycleDate) = MONTH(@BillingCycleDate) 
				AND YEAR(BillingCycleDate) = YEAR(@BillingCycleDate))
				AND i.SentToOrders = 0 	
				
				IF @@TRANCOUNT > 0 COMMIT;
				
				CONTINUE
							
	END TRY
	BEGIN CATCH			 
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		INSERT INTO TRANSACTIONSSTAGING.dbo.TransactionErrors
			(	TransactionType,
				Error,
				Created
			)
		Select 'uspORDERS_InsertLegacyTransactionData', 'AccountIDSeq = ' + @AccountIDSeq + 'ErrorMessage ' +  ERROR_MESSAGE(),Getdate()
				
		CONTINUE
	END CATCH

END --End Loop
----[uspORDERS_InsertLegacyTransactionData] '02/28/2006'

---Select * from OrderItemTransaction

--select * from TRANSACTIONSSTAGING.dbo.TransactionErrors
END




GO
