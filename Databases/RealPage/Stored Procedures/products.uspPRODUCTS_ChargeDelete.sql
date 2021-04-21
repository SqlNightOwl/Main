SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[uspPRODUCTS_ChargeDelete]    Script Date: 11/11/2008 ******/
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ChargeDelete]
												 @IPI_ChargeID INT
		
					 
AS
BEGIN--> Main Begin

  DELETE FROM Products.dbo.ChargeFootNote  WHERE ChargeIDSeq = @IPI_ChargeID
  DELETE FROM Products.dbo.Charge  WHERE ChargeIDSeq = @IPI_ChargeID

END-->Main End
GO
