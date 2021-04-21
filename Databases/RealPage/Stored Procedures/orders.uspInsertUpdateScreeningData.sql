SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create Procedure [orders].[uspInsertUpdateScreeningData]
--drop Procedure uspInsertScreeningData
  @AccountID VARCHAR(50)
 ,@PMCID VARCHAR(50)
 ,@SourceTransactionID VARCHAR(50)
 ,@TransactionItemName VARCHAR(70)
 ,@ServiceCode VARCHAR(50)
 ,@ServiceDate DATETIME
 ,@ProductCode VARCHAR(30)
 ,@LoginID VARCHAR(50)
 ,@OrderGroupType VARCHAR(50)
 ,@OrderGroupDescription VARCHAR(255)
 ,@OrderGroupName VARCHAR(70)
 ,@ReturnMessage VARCHAR(255) OUTPUT
As
--
--/*	Created On : 2/21/07
--	Created By : Vidhya Venkatapathy
--	Purpose    : To insert and Update Billable Transaction data in Orders database
--*/

BEGIN
 Select @ReturnMessage ='Success'

 Select @ReturnMessage
END
GO
