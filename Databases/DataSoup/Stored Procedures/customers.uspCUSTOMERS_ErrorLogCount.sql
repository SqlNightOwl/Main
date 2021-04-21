SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [customers].[uspCUSTOMERS_ErrorLogCount](@IPI_PageNumber    int, 
                                                    @IPI_RowsPerPage   int,
                                                    @IPVC_Filter1Type  varchar(100)=NULL, 
                                                    @IPVC_Filter1Value varchar(100)=NULL,
                                                    @IPVC_Filter2Type  varchar(100)=NULL, 
                                                    @IPVC_Filter2Value varchar(100)=NULL
                                                   )  --WITH RECOMPILE -- THIS IS TO HANDLE CACHING AND LOCKING
AS
BEGIN-->Main Begin
  SET NOCOUNT ON;  

  Set @IPVC_Filter1Type = Coalesce(@IPVC_Filter1Type,'')
  Set @IPVC_Filter1Value = Coalesce(@IPVC_Filter1Value,'')
  Set @IPVC_Filter2Type = Coalesce(@IPVC_Filter2Type,'')
  Set @IPVC_Filter2Value = Coalesce(@IPVC_Filter2Value,'')

  ---------------------------------------------------------------------------
  Declare @sSQLWhere NVarChar(1000)
  If @IPVC_Filter1Type<>'' And @IPVC_Filter1Value<>''
  Begin
    If @IPVC_Filter1Type='logdate'
    Begin
      Set @sSQLWhere = N' WHERE DateDiff(Day,LogDate,''' + @IPVC_Filter1Value + ''')=0';
    End
    Else
    Begin
      Set @sSQLWhere = N' WHERE '+@IPVC_Filter1Type+' = '''+@IPVC_Filter1Value+'''';
    End
  End
  Else
  Begin
    Set @sSQLWhere = N'';
  End

  If @IPVC_Filter2Type<>'' And @IPVC_Filter2Value<>''
  Begin
    If @sSQLWhere=''
    Begin
      If @IPVC_Filter2Type='logdate'
      Begin
        Set @sSQLWhere = N' WHERE DateDiff(Day,LogDate,''' + @IPVC_Filter2Value + ''')=0';
      End
      Else
      Begin
        Set @sSQLWhere = N' WHERE '+@IPVC_Filter2Type+' = '''+@IPVC_Filter2Value+'''';
      End
    End
    Else
    Begin
      If @IPVC_Filter2Type='logdate'
      Begin
        Set @sSQLWhere = @sSQLWhere + N' AND DateDiff(Day,LogDate,''' + @IPVC_Filter2Value + ''')=0';
      End
      Else
      Begin
        Set @sSQLWhere = @sSQLWhere + N' AND '+@IPVC_Filter2Type+' = '''+@IPVC_Filter2Value+'''';
      End
    End
  End
  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  Declare @LI_Min bigint, @LI_Max bigint;
  SELECT  @LI_Min = (@IPI_PageNumber-1) * @IPI_RowsPerPage,
          @LI_Max = (@IPI_PageNumber)   * @IPI_RowsPerPage;
  SET ROWCOUNT @LI_Max;
  ---------------------------------------------------------------------------

  IF @sSQLWhere='' 
  BEGIN 
    WITH TotalResultSet AS   
       ----------------------------------------------------------  
       (SELECT tableinner.[Count] as [Count]  
           FROM  
           ----------------------------------------------------------     
           (select count(source.[LogDate]) as [Count] from
             ----------------------------------------------------------  
             (
               SELECT [LogDate] FROM [CUSTOMERS].dbo.[ErrorLog]
             )source  
             ------------------------------------------------------------------------  
        ) tableinner  
      -----------------------------------------------------------------------------  
      )  
      SELECT  TotalResultSet.[Count]      
      from    TotalResultSet
  END
  ELSE
  BEGIN
    Declare @sSQL NVarChar(2000)
    Set @sSQL = N'
      WITH TotalResultSet AS
      (
        SELECT tableinner.[Count] as [Count]  
        FROM  
          (select count(source.[LogDate]) as [Count] from
            (
              SELECT [LogDate] FROM [CUSTOMERS].dbo.[ErrorLog]' + @sSQLWhere + N'
            )source  
        ) tableinner  
      )  
      SELECT  TotalResultSet.[Count]      
      from    TotalResultSet'
    EXEC sp_executesql @sSQL
  END

END--->Main End

GO
