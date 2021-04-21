SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec uspQUOTES_DeleteBundle @IPVC_QuoteID=1,@IPBI_BundleID=1

CREATE PROCEDURE [quotes].[uspQUOTES_DeleteBundle]  (@IPVC_QuoteID      varchar(50),
                                              @IPBI_BundleID     bigint
                                             )
AS
BEGIN
  set nocount on;  
  begin TRY
    BEGIN TRANSACTION; 
      ----------------------------------------------------------------------------
      if not exists(select Top 1 QI.IDSeq
                    from   Quotes.dbo.QuoteItem QI with (nolock)
                    where  QI.QuoteIDSeq  = @IPVC_QuoteID
                    and    QI.ProductCode = 'DMD-OSD-PAY-PAY-PPAY'
                    and    QI.GroupIDSeq <> @IPBI_BundleID
                   )
      begin
        Delete D
        from   Quotes.dbo.Quoteitemnote D with (nolock)
        where  D.QuoteIDSeq =@IPVC_QuoteID
        and    Exists (select top 1 1
                       from   Products.dbo.FootNote X with (nolock)
                       where  X.MandatoryFlag = 1
                       and    X.Title = D.Title
                       and    X.ApplyToProductCategory = 'Payments'
                      )
     end
     ----------------------------------------------------------------------------
     if not exists(select Top 1 QI.IDSeq
                   from   Quotes.dbo.QuoteItem QI with (nolock)
                   where  QI.QuoteIDSeq  = @IPVC_QuoteID                
                   and    QI.GroupIDSeq <> @IPBI_BundleID
                  )
     begin
       Delete D
       from   Quotes.dbo.Quoteitemnote D with (nolock)
       where  D.QuoteIDSeq =@IPVC_QuoteID
     end
    ----------------------------------------------------------------------------

      delete from QUOTES.dbo.GroupProperties 
      where  QuoteIDSeq    = @IPVC_QuoteID 
      and    GroupIDSeq    = @IPBI_BundleID                

      delete from QUOTES.dbo.QuoteItem
      where  QuoteIDSeq = @IPVC_QuoteID and GroupIDSeq = @IPBI_BundleID  
       
      delete from QUOTES.dbo.[Group]
      where  QuoteIDSeq = @IPVC_QuoteID and IDSeq = @IPBI_BundleID 
    COMMIT TRANSACTION;
    exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@IPVC_QuoteID,@IPI_GroupID=@IPBI_BundleID
  end TRY
  begin CATCH 
    --SELECT 'Bundle Delete Section' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
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
	exec CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Bundle Delete Section'
  end CATCH
  -------------------------------------------------------------------------------------------------
  ---Final Update to realign GroupNames for the current Quote
  -------------------------------------------------------------
  if exists (select Top 1 1 
             from   QUOTES.DBO.[Group] (nolock) 
             where  QuoteIDSeq = @IPVC_QuoteID  
             and    charindex('Custom Bundle',name)=1
            ) 
  begin
    begin TRY 
      Update G
      set    G.Name        = S.NewName
--             G.Description = S.NewName
      from   QUOTES.DBO.[Group] G (nolock)
      Inner Join
              (select T2.QuoteIDSeq,
                      T2.IDSeq as GroupID,
                      T2.Name  as OldName,
        	      'Custom Bundle ' + 
                       convert(varchar(50),(select count(*) 
                                            from QUOTES.DBO.[Group] (nolock) T1 
                                            where T1.QuoteIDSeq = T2.QuoteIDSeq
                                            and   T1.QuoteIDSeq = @IPVC_QuoteID
                                            and   T2.QuoteIDSeq = @IPVC_QuoteID
                                            and   T1.IDSeq     <= T2.IDSeq
                                            and   charindex('Custom Bundle',T1.name)=1 
                                           )
                               )        as NewName
               from  QUOTES.DBO.[Group] (nolock) T2
               where QuoteIDSeq = @IPVC_QuoteID
               and   charindex('Custom Bundle',T2.name)=1
              ) S
      on    G.QuoteIDSeq = S.QuoteIDSeq
      and   G.IDSeq      = S.GroupID
      and   G.Name       = S.OldName
      and   G.QuoteIDSeq = @IPVC_QuoteID
      where G.QuoteIDSeq = @IPVC_QuoteID
    end TRY
    begin CATCH
      --SELECT 'Group Update To realign GroupNames Section' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage;
	   EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Group Update To realign GroupNames Section'              
    end CATCH
  end
  -------------------------------------------------------------------------------------------------
END




 
GO
