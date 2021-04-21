SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_ImportTransactions
-- Description     : This procedure gets recordset based on the XML data sent
-- Input Parameters: @IPT_ImportPropertiesXML
--                   
-- OUTPUT          : The recordset is created based on the XML data sent and inserted into the table
--                   "OrderItemTransaction"
--
-- Code Example    : Exec ORDERS.DBO.uspORDERS_ImportTransactions @IPT_ImportTransactionsXML=
/*
	'<root>
	<Transaction><row CustomerName="AIMCO-Pilot" ExtChargeAmount="10.00" HoursBilled="1" 
	NetChargeAmount="21.00" ServiceDate="2007-10-01 05:55:03.737"/>
	</Transaction>

	<Transaction><row CustomerName="Alpha Phi Alpha Homes Inc" ExtChargeAmount="11.00" HoursBilled="1" 
	NetChargeAmount="22.00" ServiceDate="2007-10-01 05:55:03.737"/>
	</Transaction>

	<Transaction><row CustomerName="Amurcon Corporation" ExtChargeAmount="12.00" HoursBilled="1" 
	NetChargeAmount="23.00" ServiceDate="2007-10-01 05:55:03.737"/>
	</Transaction>
	</root>'
*/
-- 
-- 
-- Revision History:
-- Author          : Shashi Bhushan
-- 10/03/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_ImportTransactions](@IPT_ImportTransactionsXML  TEXT = NULL)

AS
BEGIN
------------------------------------------------------------------------------------------------------
---Declare Local Variables
------------------------------------------------------------------------------------------------------
Declare @ExtChargeAmount Numeric(10,2) 
Declare @HoursBilled     Numeric(10,2) 
Declare @NetChargeAmount Numeric(10,2) 
Declare @ServiceDate     Datetime
Declare @CustomerName    varchar(100)
Declare @ProdCode        Char(30)
Declare @LI_Min          int
Declare @LI_Max          int
declare @LI_CountInsert  int
set @LI_CountInsert=0
declare @LI_CountUpdate  int
set @LI_CountUpdate=0

Declare @LT_OrderItemTrans Table (
									SEQ int not null identity(1,1),
									CustomerName    varchar(100),
									ExtChargeAmount Numeric(10,2),
									HoursBilled     Numeric(10,2),
									NetChargeAmount Numeric(10,2),
									ServiceDate     Datetime
							      )

Declare @LT_FinalDetails table (
								IDSeq              int,
								OrderIDSeq         varchar(22),
								OrderGroupIDSeq    int,
								ProductCode        Char(30),
								PriceVersion		Numeric(18,0),
								ChargeTypeCode     Char(3),
								FrequencyCode      Char(6),
								MeasureCode        Char(6),
								ServiceCode        varchar(30),
								TransactionItemName varchar(70),
								ExtChargeAmount     Numeric(10,2),
								DiscountAmount      Numeric(10,2),
								NetChargeAmount     Numeric(10,2),
								InvoicedFlag        bit,
								SourceTransactionID varchar(8),
								ServiceDate         Datetime
						       )

 -----------------------------------------------------------------------------------
  Declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPT_ImportTransactionsXML
  -----------------------------------------------------------------------------------
  --OPENXML to read XML and Insert Data into @LT_PropertySummary
  -----------------------------------------------------------------------------------
Begin TRY 
   Insert into @LT_OrderItemTrans ( CustomerName,ExtChargeAmount,HoursBilled,NetChargeAmount,ServiceDate)
    Select A.CustomerName,A.ExtChargeAmount,A.HoursBilled,A.NetChargeAmount,A.ServiceDate
    from (
		   Select  CustomerName,
				   ExtChargeAmount,
				   HoursBilled,
				   NetChargeAmount,
				   ServiceDate
		   from OPENXML (@idoc,'//Transaction/row',1) 
           with (
					CustomerName varchar(100),
					ExtChargeAmount Numeric(10,2),
					HoursBilled Numeric(10,2),
					NetChargeAmount Numeric(10,2),
					ServiceDate Datetime
				)
		)A
End TRY
  Begin CATCH
    SELECT '//Transactiondetail/row XML ReadSection' as ErrorSection,XACT_STATE() as TransactionState,
           ERROR_MESSAGE() AS ErrorMessage;
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end        
    return
  End CATCH

-----------------------------------------------------------------------------------
  --select * from @LT_OrderItemTrans  
  ----Validation
  if (select count(*) from @LT_OrderItemTrans)=0 
  begin
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end         
    return
  end  
----------------------------------------------------------------------------------------
--  Retrieving Produce Code based on the Display Name passed  
----------------------------------------------------------------------------------------
Select @ProdCode = Code 
From products..product
Where DisplayName = 'OneSite Implementation and Consulting'   -- Display Name is HardCoded temporarily
----------------------------------------------------------------------------------------  

select @LI_Min = Min(SEQ),@LI_Max = Max(SEQ) from @LT_OrderItemTrans
  while @LI_Min <= @LI_Max
  begin --: begin while
    select  @CustomerName = CustomerName, 
			@ExtChargeAmount=ExtChargeAmount,
			@HoursBilled=HoursBilled,
			@NetChargeAmount=NetChargeAmount,
			@ServiceDate=ServiceDate
    from @LT_OrderItemTrans where SEQ = @LI_Min
--select  @CustomerName,@ExtChargeAmount,@HoursBilled,@NetChargeAmount,@ServiceDate

	insert into @LT_FinalDetails (
								IDSeq,OrderIDSeq,OrderGroupIDSeq,ProductCode,PriceVersion,ChargeTypeCode,FrequencyCode,MeasureCode,ServiceCode,TransactionItemName,
								ExtChargeAmount,DiscountAmount,NetChargeAmount,InvoicedFlag,SourceTransactionID,ServiceDate 
	                         )
		select 
				OI.IDSeq,
				OI.OrderIDseq,
				OI.OrderGroupIDSeq,
				@ProdCode as ProductCode,
				100,
				OI.ChargeTypeCode,
				OI.FrequencyCode,
				OI.MeasureCode,
				'xyz' as ServiceCode,
				'OneSite Implementation and Consulting' as TransactionItemName,
				@ExtChargeAmount as ExtChargeAmount,
				OI.DiscountAmount,
				@NetChargeAmount as NetChargeAmount,
				I.PrintFlag,
				NULL as SourceTransactionID,
				@ServiceDate as ServiceDate
				from orders..[order] O
				Join orders..[orderItem] OI ON O.orderIDSeq=OI.orderIDSeq
				Join customers..company C On C.IDSeq=O.CompanyIDSeq
				Join Invoices..InvoiceItem II On II.OrderIDSeq=OI.orderIDSeq and II.OrderItemIDSeq=OI.IDSeq and II.ProductCode=OI.ProductCode
				Join Invoices..Invoice I On I.Invoiceidseq=II.Invoiceidseq
				and OI.ProductCode=@ProdCode  --'DMD-PSR-ICM-ICM-MOSC'
				and C.Name=@CustomerName  --'AIMCO-Pilot'

		  select @LI_Min = @LI_Min + 1

		set @LI_CountInsert = @LI_CountInsert + 1 
  End

-----------------------------------------------------------------------------------
--Inserting the Final Data into the table OrderItemTransaction
-----------------------------------------------------------------------------------
 Insert into Orders..OrderItemTransaction (
										OrderItemIDSeq,OrderIDSeq,OrderGroupIDSeq,ProductCode,PriceVersion,ChargeTypeCode,
										FrequencyCode,MeasureCode,ServiceCode,TransactionItemName,ExtChargeAmount,
										DiscountAmount,NetChargeAmount,InvoicedFlag,SourceTransactionID,ServiceDate
									       )
    Select * from @LT_FinalDetails

select @LI_CountInsert as CountInsert
------------------------------------------------------------------------------------------------------
END


GO
