SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec Invoices.dbo.uspINVOICES_InsertPullList @IPBI_PullListID = 9,@IPVC_Title = 'ELF TEST',
                                             @IPVC_Description='ELF Man Description',@IPBI_CreatedByIDSeq=42,
@IPT_AccountIDXML ='<pulllistaccounts>
                             <row accountidseq="A0806000012"/>
                             <row accountidseq="A0806000443"/>
                             <row accountidseq="A0806000007"/>
                             <row accountidseq="A0806000004"/>
                             <row accountidseq="A0806000005"/>
                             <row accountidseq="A0806000006"/>
                             <row accountidseq="A0806026161"/>
                             <row accountidseq="A0806000009"/>
                             <row accountidseq="A0806000010"/>
                             <row accountidseq="A0805032414"/>
                    </pulllistaccounts>'
                                             
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspINVOICES_InsertPullList]
-- Description     : This procedure inserts Account for a Pull List pertaining to passed AccountID
-- Input Parameters: 1. @IPVC_InvoiceID   AS varchar(10)
--                   
-- OUTPUT          : RecordSet of IDSEq is generated
--
--                   
-- Code Example    : Exec Invoices.dbo.uspINVOICES_InvoicePropertySelect 'I0000000002', 'ACS', 1, 10
-- 
-- 
-- Revision History:
-- Author          : Naval Kishore SIngh
-- 23/09/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InsertPullList](@IPBI_PullListID     bigint  = '',
						    @IPVC_Title		 varchar(500),
						    @IPVC_Description    varchar(500),
						    @IPBI_CreatedByIDSeq bigint,
                                                    @IPT_AccountIDXML    TEXT = NULL
                                                   )
AS
BEGIN  
  set nocount on;
  --------------------------------------------------
  DECLARE @LBI_PullListID       bigint;
  declare @LVC_ErrorCodeSection varchar(4000);
  declare @idoc                 int;

  create table #LT_PullListAccount (seq                      int not null identity(1,1),
                                    accountidseq             varchar(50)
                                   )
  --------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPT_AccountIDXML;
  -----------------------------------------------------------------------------------  
  --OPENXML to read XML and Insert Data into #LT_PullListAccount
  ----------------------------------------------------------------------------------- 
  begin TRY
    insert into #LT_PullListAccount(accountidseq)
    select A.accountidseq
    from   
          (select coalesce(ltrim(rtrim(accountidseq)),'0')      as accountidseq
           from OPENXML (@idoc,'//pulllistaccounts/row',1) 
           with (accountidseq    varchar(50)
                )
          ) A
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = '//pulllistaccounts/row XML ReadSection'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end
    return
  end CATCH;   
  -----------------------------------------------------------------------------------
  --Validation
  if (select count(seq) from #LT_PullListAccount with (nolock)) = 0
  begin
    select @LVC_ErrorCodeSection = 'No Accounts is selected for current pull list. Hence PullList cannot be created/Updated'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end
    drop table #LT_PullListAccount
    return
  end
  -----------------------------------------------------------------------------------
  ---Step 1 : INVOICES.dbo.PullList Insert / Update
  if exists(select top 1 1 
            from   INVOICES.dbo.PullList with (nolock)
            where  IDSeq = @IPBI_PullListID
           )
  begin
    select @LBI_PullListID = @IPBI_PullListID
    update INVOICES.dbo.PullList 
    set    Title          =  @IPVC_Title, 
           [Description]  =  @IPVC_Description,
           ModifiedByIDSeq=  @IPBI_CreatedByIDSeq,
           ModifiedDate   =  getdate()
    where  IDSeq = @LBI_PullListID    
    Delete from INVOICES.dbo.PullListAccounts where PullListIDSeq=@LBI_PullListID
  end
  else
  begin
    Insert into INVOICES.dbo.PullList (Title,[Description],CreatedByIDSEQ,ModifiedByIDSeq,CreatedDate,ModifiedDate)
    select @IPVC_Title,@IPVC_Description,@IPBI_CreatedByIDSeq,@IPBI_CreatedByIDSeq,getdate(),getdate()
    select @LBI_PullListID = SCOPE_IDENTITY()
  end
  ---------------------------------------------------------------------------------------
  --Step 2 : Insert into INVOICES.dbo.PullListAccounts
  Delete from INVOICES.dbo.PullListAccounts where PullListIDSeq=@LBI_PullListID
  Insert into INVOICES.dbo.PullListAccounts (PullListIDSeq,AccountIDSeq)
  select distinct @LBI_PullListID as PullListIDSeq ,accountidseq as AccountIDSeq
  from   #LT_PullListAccount with (nolock)
  ---------------------------------------------------------------------------------------
  ---Final Cleanup
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end
  drop table #LT_PullListAccount
  ---------------------------------------------------------------------------------------




end    
--Invoices.dbo.uspINVOICES_InsertPullList '','aaa','dddd',69,'A0000019655|A0000019656|','Add'


GO
