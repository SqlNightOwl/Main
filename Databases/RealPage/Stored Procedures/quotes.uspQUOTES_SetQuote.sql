SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- TFS #295 -- Instant Invoice Transactions through OMS
-- Done by: Satya B on 07/15/2011

exec [QUOTES].[dbo].[uspQUOTES_SetQuote] @IPT_SetQuoteXML = 
'<quote xmlns=""><row companyid="A0000000001" quoteid="0" companyname="realpage company" quotestatuscode="QPA" createdby="" modifiedby="" createdbydisplayname="" modifiedbydisplayname="" expirationdate="" internalquoteid = "" prepaidflag = "1"/>
</quote>'
*/

CREATE PROCEDURE [quotes].[uspQUOTES_SetQuote] (@IPT_SetQuoteXML  TEXT = NULL)
AS
BEGIN --: Main BEGIN
  set nocount on; 
  set XACT_ABORT on; -- set XACT_ABORT on will render the transaction uncommittable
                     -- when the constraint violation occurs.
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  -----------------------------------------------------------------------------------
  declare @LI_Min                        int
  declare @LI_Max                        int  
  declare @LVC_companyid                 varchar(50)
  declare @LVC_quoteidgen                varchar(50)
  declare @LVC_quoteid                   varchar(50)  
  declare @LVC_expirationdate            varchar(50)  
  select  @LI_Min=0,@LI_Max=0
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable
  -----------------------------------------------------------------------------------
  declare @LT_quotemaster    TABLE(SEQ                   int not null identity(1,1),
                                   companyid             varchar(11),
                                   quoteid               varchar(50) default '0',
                                   companyname           varchar(255) not null default '',
                                   quotetypecode         varchar(4),                                 
                                   quotestatuscode       varchar(4)  not null default '',
                                   createdbyidseq        int,
                                   modifiedbyidseq       int,
                                   createdby             varchar(70) not null default '',
                                   modifiedby            varchar(70) not null default '',
                                   createdbydisplayname  varchar(70) not null default '',
                                   modifiedbydisplayname varchar(70) not null default '',
                                   expirationdate        varchar(50) not null default '',
                                   prepaidflag           int         default (0),
                                   externalquoteiiflag   int         default (0),
                                   requestedby           varchar(70) null
                                  )
  -----------------------------------------------------------------------------------
  declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPT_SetQuoteXML
  -----------------------------------------------------------------------------------
  --OPENXML to read XML and Insert Data into @LT_quotemaster 
  -----------------------------------------------------------------------------------
  begin TRY
    insert into @LT_quotemaster(companyid,quoteid,companyname,quotetypecode,quotestatuscode,
                                createdbyidseq,modifiedbyidseq,createdby,modifiedby,createdbydisplayname,modifiedbydisplayname,
                                expirationdate,prepaidflag,ExternalQuoteIIFlag,requestedby)
    select A.companyid,A.quoteid,A.companyname,A.quotetypecode,A.quotestatuscode,
           A.createdbyid,A.modifiedbyid,A.createdby,A.modifiedby,A.createdbydisplayname,A.modifiedbydisplayname,
           A.expirationdate,A.prepaidflag,A.ExternalQuoteIIFlag,A.requestedby
    from (select ltrim(rtrim(companyid))             as companyid,
                 ltrim(rtrim(quoteid))               as quoteid,
                 ltrim(rtrim(companyname))           as companyname,
                 ltrim(rtrim(quotetypecode))         as quotetypecode,
                 ltrim(rtrim(quotestatuscode))       as quotestatuscode,
                 ltrim(rtrim(createdbyid))           as createdbyid,
                 ltrim(rtrim(modifiedbyid))          as modifiedbyid,  
                 ltrim(rtrim(createdby))             as createdby,
                 ltrim(rtrim(modifiedby))            as modifiedby,  
                 ltrim(rtrim(createdbydisplayname))  as createdbydisplayname,
                 ltrim(rtrim(modifiedbydisplayname)) as modifiedbydisplayname,
                 ltrim(rtrim(expirationdate))        as expirationdate,
                 coalesce(nullif(ltrim(rtrim(prepaidflag)),''),'0')           as prepaidflag,
                 coalesce(nullif(ltrim(rtrim(ExternalQuoteIIFlag)),''),'0')   as ExternalQuoteIIFlag,
                 ltrim(rtrim(requestedby))                                    as requestedby
          from OPENXML (@idoc,'//quote/row',1) 
          with (companyid             varchar(11),
                quoteid               varchar(50),                                
                companyname           varchar(255),
                quotetypecode         varchar(4),
                quotestatuscode       varchar(4),
                createdbyid           varchar(50),
                modifiedbyid          varchar(50),
                createdby             varchar(70),
                modifiedby            varchar(70),
                createdbydisplayname  varchar(70),
                modifiedbydisplayname varchar(70),
                expirationdate        varchar(50),
                prepaidflag           varchar(10),
                externalquoteiiflag   varchar(10), 
                requestedby           varchar(70)
               )
          ) A
 
    update D
    set    D.companyname = S.Name 
    from   @LT_quotemaster D inner join Customers.dbo.Company S (nolock)
    on     D.companyid = S.IDSeq  
  end TRY
  begin CATCH
--    SELECT '//quote/row XML ReadSection' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage;
	EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] '//quote/row XML ReadSection'    
  end CATCH;
  ------------------------------------------------------------------
  ---select * from @LT_quotemaster --:Validation
  if (select count(*) from @LT_quotemaster) > 0
  begin
    select @LI_Min = Min(SEQ),@LI_Max = Max(SEQ) from @LT_quotemaster
    while @LI_Min <= @LI_Max
    begin --: begin while
      select @LVC_companyid = companyid,@LVC_quoteid = quoteid,@LVC_expirationdate = expirationdate
      from   @LT_quotemaster where SEQ = @LI_Min

      if (@LVC_quoteid = '0')         
         and not exists (select Top 1 1 from QUOTES.DBO.[quote] with (nolock) 
                         where  QuoteIDSeq = @LVC_quoteid and CustomerIDSeq = @LVC_companyid)        
      begin
        begin TRY
          BEGIN TRANSACTION; 
          
          update QUOTES.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
          set    IDSeq = IDSeq+1,
                 GeneratedDate =CURRENT_TIMESTAMP

          select @LVC_quoteid = QuoteIDSeq
          from   QUOTES.DBO.IDGenerator with (NOLOCK)  
          ------------------------------
          --- New Group : Insert
          ------------------------------ 
          insert into QUOTES.DBO.[Quote](Quoteidseq,CustomerIDSeq,companyname,quotetypecode,quotestatuscode,
                                         createdbyidseq,modifiedbyidseq,createdby,modifiedby,createdbydisplayname,modifiedbydisplayname,
                                         expirationdate,prepaidflag,requestedby,ExternalQuoteIIFlag)
          select @LVC_quoteid,@LVC_companyid,companyname,quotetypecode,quotestatuscode,
                 createdbyidseq,modifiedbyidseq,
                 createdby,modifiedby,createdbydisplayname,modifiedbydisplayname,
                 (case when (expirationdate = '' or expirationdate is null) then getdate()+30
                       else convert(datetime,expirationdate) end ) as expirationdate,prepaidflag,nullif(requestedby,'') as requestedby,
                 externalquoteiiflag
          from @LT_quotemaster where SEQ = @LI_Min         
           
          Update QUOTES.DBO.[Quote] set expirationdate = CreateDate+30
          where QuoteIDSeq = @LVC_quoteid
          -------------------------------------------------------------------------------------------------  
          --Recording the Quote Insert activity to Quotes.dbo.QuoteLog Table
          --------------------------------------------------------------------
          insert into Quotes.dbo.QuoteLog(QuoteIDSeq,CustomerIDSeq,CompanyName,Sites,Units,Beds,
                                    OverrideFlag,OverrideSites,OverrideUnits,
                                    ILFExtYearChargeAmount,ILFDiscountPercent,ILFDiscountAmount,ILFNetExtYearChargeAmount,
                                    AccessExtYear1ChargeAmount,AccessExtYear2ChargeAmount,AccessExtYear3ChargeAmount,
                                    AccessYear1DiscountPercent,AccessYear1DiscountAmount,
                                    AccessYear2DiscountPercent,AccessYear2DiscountAmount,
                                    AccessYear3DiscountPercent,AccessYear3DiscountAmount,
                                    AccessNetExtYear1ChargeAmount,AccessNetExtYear2ChargeAmount,AccessNetExtYear3ChargeAmount,                                    
                                    QuoteStatusCode,QuoteTypeCode,CreatedBy,ModifiedBy,CreatedByDisplayName,ModifiedByDisplayName,
                                    ExpirationDate,CreateDate,ModifiedDate,SQLActivityType,
                                    DealDeskReferenceLevel,DealDeskCurrentLevel,DealDeskStatusCode,DealDeskQueuedDate,DealDeskQueuedByIDSeq,
                                    DealDeskDecisionMadeBy,DealDeskNote,DealDeskResolvedByIDSeq,DealDeskResolvedDate,
                                    RollbackReasonCode,RollBackByIDseq,RollBackDate,
                                    PrePaidFlag,RequestedBy,ExternalQuoteIIFlag 
                                    )
          select Q.QuoteIDSeq as QuoteIDSeq,Q.CustomerIDSeq,Q.CompanyName,Q.Sites,Q.Units,Q.beds,
                 Q.OverrideFlag,Q.OverrideSites,Q.OverrideUnits,
                 Q.ILFExtYearChargeAmount,Q.ILFDiscountPercent,Q.ILFDiscountAmount,Q.ILFNetExtYearChargeAmount,
                 Q.AccessExtYear1ChargeAmount,Q.AccessExtYear2ChargeAmount,Q.AccessExtYear3ChargeAmount,
                 Q.AccessYear1DiscountPercent,Q.AccessYear1DiscountAmount,
                 Q.AccessYear2DiscountPercent,Q.AccessYear2DiscountAmount,
                 Q.AccessYear3DiscountPercent,Q.AccessYear3DiscountAmount,
                 Q.AccessNetExtYear1ChargeAmount,Q.AccessNetExtYear2ChargeAmount,Q.AccessNetExtYear3ChargeAmount,                 
                 Q.QuoteStatusCode,Q.QuoteTypeCode,Q.CreatedBy,Q.ModifiedBy,Q.CreatedByDisplayName,Q.ModifiedByDisplayName,
                 Q.ExpirationDate,Q.CreateDate,getdate() as ModifiedDate,'I' as SQLActivityType,
                 Q.DealDeskReferenceLevel,Q.DealDeskCurrentLevel,Q.DealDeskStatusCode,Q.DealDeskQueuedDate,Q.DealDeskQueuedByIDSeq,
                 Q.DealDeskDecisionMadeBy,Q.DealDeskNote,Q.DealDeskResolvedByIDSeq,Q.DealDeskResolvedDate,Q.RollbackReasonCode,Q.RollBackByIDseq,Q.RollBackDate,
                 Q.PrePaidFlag,Q.RequestedBy,Q.ExternalQuoteIIFlag 
          from Quotes.dbo.Quote Q with (nolock) 
          where Q.QuoteIDSeq = @LVC_quoteid
          -------------------------------------------------------------------------------------------------     
          COMMIT TRANSACTION;
        end TRY
        begin CATCH 
          -- SELECT 'Quote Insert Section' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
		EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'uspQUOTES_SetQuote: Quote Insert Section'
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
          select @LVC_quoteid = 0       
        end CATCH
      end --:Quote Insert end
      else
      begin --:Quote Update begin
        begin TRY
          BEGIN TRANSACTION;       
          -------------------------------------------------------------------------------------------------              
          --- Existing Group : Update
          ------------------------------
          Update  Q
          set     Q.CustomerIDSeq          =@LVC_companyid,
                  Q.companyname            =(select top 1 companyname            from @LT_quotemaster where SEQ = @LI_Min),
                  Q.quotestatuscode        =(select top 1 quotestatuscode        from @LT_quotemaster where SEQ = @LI_Min),                  
                  Q.modifiedby             =(select top 1 modifiedby             from @LT_quotemaster where SEQ = @LI_Min), 
                  Q.modifiedbydisplayname  =(select top 1 modifiedbydisplayname  from @LT_quotemaster where SEQ = @LI_Min),                   
                  Q.modifieddate           =getdate(),
                  Q.expirationdate         =(case when (@LVC_expirationdate = '' or @LVC_expirationdate is null) 
                                                        then Q.CreateDate+30
                                                  else convert(datetime,@LVC_expirationdate) end)
          from    QUOTES.DBO.[Quote] Q (nolock)
          where   Q.QuoteIDSeq = @LVC_quoteid                    
          COMMIT TRANSACTION;          
        end TRY
        begin CATCH
           --    SELECT 'Group Update Section' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage;
           EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'uspQUOTES_SetQuote : Quote Update Section' 
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
        end CATCH
      end --:Quote Update end
      exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@LVC_quoteid
      select @LI_Min = @LI_Min + 1
    end --: end while
  end
  -----------------------------------------------------------------------------------
  --Reinitializing Variable for further Use 
  select @LI_Min=0,@LI_Max=0
  -----------------------------------------------------------------------------------
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end 
  --------------------------------------------------------------------------------------- 
  select @LVC_quoteid as quoteid 
  FOR XML raw ,ROOT('root'), TYPE  
END
GO
