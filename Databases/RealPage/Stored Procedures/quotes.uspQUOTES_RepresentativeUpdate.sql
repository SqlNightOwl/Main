SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [quotes].[uspQUOTES_RepresentativeUpdate] @ID                 varchar(50),
                                                        @QuoteID            varchar(50), 
                                                        @Name               varchar(100), 
                                                        @CommissionPercent  varchar(50),
                                                        @CommissionAmount   varchar(50)
As
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION 
      Update Quotes.dbo.QuoteSaleAgent 
      Set QuoteIDSeq=@QuoteID, 
          SalesAgentName=@Name, 
          CommissionPercent=@CommissionPercent, 
          CommissionAmount=@CommissionAmount
      Where IDSeq=@ID
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    --SELECT 'Sales Rep Update Section' as ErrorSection, XACT_STATE() as TransactionState, ERROR_MESSAGE() AS ErrorMessage;
	EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Sales Rep Update Section' 
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
  END CATCH
  ---------------------------------------------------------------------------------------
  ---Final Clean up
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;  
  --------------------------------------------------------------------------------------- 
END

GO
