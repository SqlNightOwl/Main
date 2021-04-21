SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [QueueManager].[uspQUEUEMANAGER_RaiseError] @IPVC_CodeSection  varchar(500) = '' 
AS
BEGIN
  set nocount on;
  -------------------
  DECLARE @LVC_ErrorMessage NVARCHAR(4000),
          @LN_ErrorSeverity INT,
          @LN_ErrorState    INT;

  select @LVC_ErrorMessage  = Coalesce(@IPVC_CodeSection,'') + '' +  Coalesce(ERROR_MESSAGE(),''),
         @LN_ErrorSeverity  = Coalesce(ERROR_SEVERITY(),16),
         @LN_ErrorState     = Coalesce(ERROR_STATE(),1);

  RAISERROR (@LVC_ErrorMessage, @LN_ErrorSeverity, @LN_ErrorState);
END
GO
