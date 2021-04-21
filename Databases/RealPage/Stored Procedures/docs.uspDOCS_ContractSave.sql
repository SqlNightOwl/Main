SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_ContractSave

Purpose    :  Saves Data into Contract table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_ContractSave

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_ContractSave]
(
  @IP_IDSeq VARCHAR(22),
  @IP_CompanyIDSeq varchar (11),
  @IP_OwnerIDSeq varchar (11),
  @IP_PropertyIDSeq varchar (11),
  @IP_DocumentIDSeq varchar (22),
  @IP_TypeCode varchar (3),
  @IP_FamilyCode varchar (3),
  @IP_ProductCode varchar (30),
  @IP_Title varchar (255),
  @IP_TemplateIDSeq bigint,
  @IP_TemplateVersion bigint,
  @IP_Author varchar (255),
  @IP_PMCSignBy varchar (255),
  @IP_PMCSignByTitle varchar (255),
  @IP_OwnerSignBy varchar (255),
  @IP_OwnerSignByTitle varchar (255),
  @IP_RealPageSignBy varchar (255),
  @IP_RealPageSignByTitle varchar (255),
  @IP_CreatedDate datetime,
  @IP_SubmittedDate datetime,
  @IP_ReceivedDate datetime,
  @IP_ExecutedDate datetime,
  @IP_BeginDate datetime,
  @IP_ExpireDate datetime,
  @IP_CreatedBy varchar (70),
  @IP_ModifiedDate datetime,
  @IP_ModifiedBy varchar (70) 
)
AS
  
  Declare @LVC_ContractIDSeq VARCHAR(22)
  IF ( @IP_IDSeq is not null )
  BEGIN
   BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE Contract SET
      CompanyIDSeq=@IP_CompanyIDSeq
      , OwnerIDSeq=@IP_OwnerIDSeq, PropertyIDSeq=@IP_PropertyIDSeq, DocumentIDSeq=@IP_DocumentIDSeq
      , TypeCode=@IP_TypeCode, FamilyCode=@IP_FamilyCode, ProductCode=@IP_ProductCode
      , Title=@IP_Title, TemplateIDSeq=@IP_TemplateIDSeq, TemplateVersion=@IP_TemplateVersion
      , Author=@IP_Author, PMCSignBy=@IP_PMCSignBy, PMCSignByTitle=@IP_PMCSignByTitle
      , OwnerSignBy=@IP_OwnerSignBy, OwnerSignByTitle=@IP_OwnerSignByTitle, RealPageSignBy=@IP_RealPageSignBy
      , RealPageSignByTitle=@IP_RealPageSignByTitle, CreatedDate=@IP_CreatedDate, SubmittedDate=@IP_SubmittedDate
      , ReceivedDate=@IP_ReceivedDate, ExecutedDate=@IP_ExecutedDate, BeginDate=@IP_BeginDate
      , ExpireDate=@IP_ExpireDate, CreatedBy=@IP_CreatedBy, ModifiedDate=@IP_ModifiedDate
      , ModifiedBy=@IP_ModifiedBy
    OUTPUT 
      INSERTED.IDSeq as IDSeq
    Where 
      IDSeq = @IP_IDSeq
    COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
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
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Docs Update Section'
    END CATCH
  END
  ELSE
  BEGIN
      BEGIN TRY
      BEGIN TRANSACTION; 
        update IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = IDSeq+1,
               GeneratedDate =CURRENT_TIMESTAMP
        where  TypeIndicator = 'T'
        select @LVC_ContractIDSeq = IDGeneratorSeq
        from   IDGenerator with (NOLOCK)
        where  TypeIndicator = 'T'
    INSERT INTO Contract
      (IDSeq,CompanyIDSeq
       , OwnerIDSeq, PropertyIDSeq, DocumentIDSeq
       , TypeCode, FamilyCode, ProductCode
       , Title, TemplateIDSeq, TemplateVersion
       , Author, PMCSignBy, PMCSignByTitle
       , OwnerSignBy, OwnerSignByTitle, RealPageSignBy
       , RealPageSignByTitle, CreatedDate, SubmittedDate
       , ReceivedDate, ExecutedDate, BeginDate
       , ExpireDate, CreatedBy, ModifiedDate
       , ModifiedBy)
    OUTPUT 
       INSERTED.IDSeq as IDSeq
    VALUES
      (@LVC_ContractIDSeq,@IP_CompanyIDSeq
       , @IP_OwnerIDSeq, @IP_PropertyIDSeq, @IP_DocumentIDSeq
       , @IP_TypeCode, @IP_FamilyCode, @IP_ProductCode
       , @IP_Title, @IP_TemplateIDSeq, @IP_TemplateVersion
       , @IP_Author, @IP_PMCSignBy, @IP_PMCSignByTitle
       , @IP_OwnerSignBy, @IP_OwnerSignByTitle, @IP_RealPageSignBy
       , @IP_RealPageSignByTitle, @IP_CreatedDate, @IP_SubmittedDate
       , @IP_ReceivedDate, @IP_ExecutedDate, @IP_BeginDate
       , @IP_ExpireDate, @IP_CreatedBy, @IP_ModifiedDate
       , @IP_ModifiedBy)
   COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
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
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Docs Insert Section'
    END CATCH
  END




GO
