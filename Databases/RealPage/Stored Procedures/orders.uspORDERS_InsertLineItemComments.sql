SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_InsertLineItemComments]
-- Description     : This procedure Updates BillTo in OrderItem Table
-- Input Parameter : @OrderItemIDSEQ           bigint, 
--                   @BillTo                   char(1)
--
-- Code Example    : ORDERS..[uspORDERS_InsertLineItemComments] 
--                   @OrderItemIDSEQ = '210335',
--                   @BillTo  = 'P'
--
-- Revision History:
-- Author          : Naval Kishore
-- 07/24/2007      : Stored Procedure Created.
-- Revised         : Anand Chakravarthy
-- 03/18/2008      : Stored Procedure Revised.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_InsertLineItemComments] (
                                                            @IPVC_OrderIDSeq                 VARCHAR(22), 
                                                            @IPI_OrderItemIDSeq              BIGINT,
                                                            @IPBI_TransactionIDSeq           VARCHAR(10),
                                                            @IPVC_Title                      VARCHAR(255),
                                                            @IPVC_Description                VARCHAR(8000),
                                                            @IPB_MandatoryFlag               BIT,
                                                            @IPB_PrintOnInvoiceFlag          BIT,
                                                            @IPB_SortSeq                     BIGINT,
                                                            @IPVC_StartDate                  VARCHAR(22)
                                                          )     
AS
BEGIN 
  set nocount on;  
  -------------------------------------------------------- 
  IF (@IPB_MandatoryFlag = 0)
  begin 
    insert into Orders.dbo.OrderItemNote   
					(  
						OrderIDSeq,  
						OrderItemIDSeq,
						OrderItemTransactionIDSeq,
						Title,  
						MandatoryFlag,  
						PrintOnInvoiceFlag,  
						SortSeq,  
						CreatedDate,  
						[Description]  
					)   
  select      @IPVC_OrderIDSeq,  
						@IPI_OrderItemIDSeq, 
						@IPBI_TransactionIDSeq, 
						Replace(@IPVC_Title,'Mandatory Pricing','Custom'),  
						@IPB_MandatoryFlag,  
						@IPB_PrintOnInvoiceFlag,  
						@IPB_SortSeq,  
						@IPVC_StartDate,
						Items            
  from        Orders.dbo.fn_SplitDelimitedStringIntoRows(@IPVC_Description,'|')
 end
END

GO
