SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
-- =============================================
-- Author:		<Raghavender,,Realpage>
-- Create date: <24 oct 2008>
-- Description:	<proc to add new FootNote>
-- =============================================
CREATE PROCEDURE [products].[uspProducts_AddFootNote]
	 @IPVC_ProductCode VARCHAR(30),
	 @IPN_PriceVersion NUMERIC(18,0),
	 @IPVC_FootNote VARCHAR(1000)
	 

AS
BEGIN

	 INSERT INTO Products.dbo.ProductFootNote(
											  ProductCode,
       									      PriceVersion,
											  FootNote,
											  DisabledFlag
											 )
									  VALUES(
											@IPVC_ProductCode,
											@IPN_PriceVersion,
											@IPVC_FootNote,
											1
											)
END
GO
