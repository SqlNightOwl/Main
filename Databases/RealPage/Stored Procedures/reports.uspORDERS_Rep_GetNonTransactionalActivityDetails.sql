SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : [uspORDERS_Rep_GetNonTransactionalActivityDetails]  
-- Description     : This procedure gets Custom Bundle Invoice Details   
-- Input Parameters: @IPVC_AccountID			    varchar(22),
--					 @IPVC_AccountName		    	varchar(100),
--                   @IPVC_OrderID			    	varchar(22),
--					 @IPVC_ProductName    		  	varchar(22),
--					 @IPDT_ActivationStartDate 	    varchar(22),
--					 @IPDT_ActivationEndDate	    varchar(22),
--                     
-- OUTPUT          :   
-- Code Example    : Exec ORDERS.DBO.[uspORDERS_Rep_GetNonTransactionalActivityDetails] '','',1,'','','',''
-- 
-- Revision History:  
-- Author          : Anand Chakravarthy  
-- 04/07/2009      : Stored Procedure Created.  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [reports].[uspORDERS_Rep_GetNonTransactionalActivityDetails] 
                                                       (  
                                                        @IPVC_CustomerID		    	varchar(22) ,
														@IPVC_CustomerName		    	varchar(100),
														@IPB_PropertyIncluded			bit ,
														@IPVC_OrderID			    	varchar(22) ,
														@IPVC_ProductName     	    	varchar(500) ,
														@IPDT_ActivationStartDate	    varchar(22)	,
														@IPDT_ActivationEndDate   	    varchar(22) 
													   )  
AS  
BEGIN   
  set nocount on ; 
   --------------------------------------------------------------------------   
   set @IPVC_CustomerID				= nullif(@IPVC_CustomerID,'')    
   set @IPVC_OrderID				= nullif(@IPVC_OrderID,'')  
   set @IPDT_ActivationStartDate	= isnull(@IPDT_ActivationStartDate,'')  
   set @IPDT_ActivationEndDate		= isnull(@IPDT_ActivationEndDate,'')  
-------------------------------------------------------------------------- 
	SELECT  
                        C.Name                                                    AS CompanyName,
						O.CompanyIDSeq                                            AS CompanyIDSeq,
                        PRP.Name												  AS PropertyName,
                        O.PropertyIDSeq                                           AS PropertyIDSeq,
						PRP.Units												  AS Units,
						P.DisplayName       									  AS ProductName,
						OI.OrderIDSeq                                             AS OrderIDSeq,
                        OI.MeasureCode											  AS MeasureCode,
						OI.FrequencyCode										  AS Frequency, 
						OI.ActivationStartDate						              AS ActivationStartDate,
						OI.ActivationEndDate							          AS ActivationEndDate
                        
    FROM    Orders.dbo.Orderitem OI WITH (NOLOCK)
	INNER Join 
		   Orders.dbo.[Order] O with (nolock)
	on      O.OrderIDSeq      = OI.OrderIDSeq
    AND OI.ReportingTypeCode = 'ACSF'
    AND OI.FamilyCode        = 'LSD'
    AND OI.MeasureCode <> 'UNIT'
    AND OI.FrequencyCode <> 'MN'
    INNER JOIN 
           Customers.dbo.Company C with (nolock)
    on     O.CompanyIDSeq    = C.IDSeq
    INNER Join
		    Products.dbo.[Product] P with (nolock)
	on      OI.ProductCode = P.Code
	AND     OI.PriceVersion = P.PriceVersion
    LEFT OUTER JOIN 
           Customers.dbo.Property PRP with (nolock)
    on     O.PropertyIDSeq    = PRP.IDSeq
	WHERE  
    O.CompanyIDSeq  = coalesce(@IPVC_CustomerID,O.CompanyIDSeq)
	AND   P.DisplayName  LIKE '%' + @IPVC_ProductName + '%'   
	AND   OI.OrderIDSeq  = coalesce(@IPVC_OrderID,OI.OrderIDSeq)
	AND (((C.Name  LIKE '%' + @IPVC_CustomerName + '%') and @IPB_PropertyIncluded = 0 AND (PRP.IDSeq is null))    
    OR  (((C.Name  LIKE '%' + @IPVC_CustomerName + '%') or (C.Name LIKE '%' + @IPVC_CustomerName + '%')) and (@IPB_PropertyIncluded = 1)))    
    AND  ((@IPDT_ActivationStartDate = '') OR (convert(varchar(12),OI.ActivationStartDate,101)) >= convert(datetime,@IPDT_ActivationStartDate,101))
	AND  ((@IPDT_ActivationEndDate = '') OR (convert(varchar(12),OI.ActivationEndDate,101)) <= convert(datetime,@IPDT_ActivationEndDate,101))  
    AND  NOT EXISTS (select '*' from Orders.dbo.OrderItemTransaction OT  WITH (NOLOCK) where OI.OrderIDseq = OT.OrderIDseq) 
  Group By C.Name,O.CompanyIDSeq,PRP.Name,O.PropertyIDSeq,PRP.Units,OI.OrderIDSeq,OI.MeasureCode,OI.FrequencyCode,P.DisplayName,OI.ActivationStartDate,OI.ActivationEndDate
END
GO
