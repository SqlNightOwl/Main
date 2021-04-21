SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_InvoiceItemSelect
-- Description     : This procedure gets the list of Credit Invoice Items for the list of ID's passed.
-- Input Parameters: 1. @IPVC_InvoiceItemID   as varchar(200)
--                   
-- OUTPUT          : RecordSet of IDSEq is generated
--
--                   
-- Code Example    :Exec Invoices..uspINVOICES_InvoiceItemSelect 'I0000000002'
-- 
-- Revision History:
-- Author          : STA
-- 12/1/2006       : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceItemSelect1] (@Invoice_ItemID varchar(200),
                                                        @Mode varchar(20)) 
AS
BEGIN 
  ------------------------------------------------------------------------------------------
  --                  Decalration of Temporary tables.
  ------------------------------------------------------------------------------------------

  DECLARE @LV_Counter INT
  DECLARE @LV_RowCount INT

  DECLARE @LT_InvoiceCreditSummary TABLE
  (
        IDSeq                     VARCHAR(22),
        ProductCode               VARCHAR(30),
        ProductName               VARCHAR(255),
        ChargeType                CHAR(3),
        CreditAmount              NUMERIC(18,2),
        TaxAmount                 NUMERIC(18,2),
        TaxPercent                NUMERIC(30,2),
        Total                     NUMERIC(18,2),
        NetPrice                  NUMERIC(18,2),
        TotalCreditAmount         NUMERIC(20,2),
        TotalTaxAmount            NUMERIC(20,2)
  )

  DECLARE @LT_InvoiceCreditTotals TABLE
  (
      TotalCredit Numeric(30,2),
      TotalTax    Numeric(30,2),
      NetTotal    Numeric(30,2)
  )
  DECLARE @LT_InvoiceGroupSummary TABLE
  (
      RowNumber         int identity(1,1),
      InvoiceGroupIDSeq bigint,
      GroupName         varchar(255),
      CustomBundleNameEnabledFlag bit
  )
  
  
  ---------------------------------------------------------------------------------------
  -----             Insert into InvoiceGroupSummary Temporary table
-----------------------------------------------------------------------------------------
  
  INSERT INTO @LT_InvoiceGroupSummary
  (
        InvoiceGroupIDSeq,
        GroupName,
        CustomBundleNameEnabledFlag 
  )

  SELECT IDSeq,[Name],CustomBundleNameEnabledFlag 
    FROM Invoices..InvoiceGroup
    WHERE InvoiceIDSeq = @Invoice_ItemID
-----------------------------------------------------------------------------------------
  SELECT @LV_RowCount = count(*) FROM @LT_InvoiceGroupSummary
  
  SET @LV_Counter = 1
  
  DECLARE @LVC_CustomBundleNameEnabledFlag bit
  DECLARE @LVC_InvoiceGroupIDSeq bigint
  DECLARE @LVC_GroupName varchar(255)

  WHILE @LV_Counter < = @LV_RowCount
  BEGIN
    SELECT @LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag,
           @LVC_InvoiceGroupIDSeq = InvoiceGroupIDSeq,@LVC_GroupName = GroupName
    FROM @LT_InvoiceGroupSummary WHERE RowNumber = @LV_Counter    
    
-----------------------------------------------------------------------------------------
    DECLARE @LN_NetCreditAmount            numeric(10,2)
    DECLARE @LN_TaxAmount                  numeric(10,2)
    DECLARE @LN_TaxPercent                 numeric(10,2)
    DECLARE @LN_SumNetPrice                numeric(10,2)
    DECLARE @LN_SumTotalCreditAmount       numeric(10,2)
    DECLARE @LN_SumTotalTaxAmount          numeric(10,2)
    DECLARE @LC_ChargeTypeCode             char(3)
----------------------------------------------------------------------------------------
    IF @LVC_CustomBundleNameEnabledFlag = 1
    BEGIN
      
-----------------------------------------------------------------------------------------      
      SELECT @LC_ChargeTypeCode = ChargeTypeCode
                from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   
-----------------------------------------------------------------------------------------------

      IF (@Mode = 'FullCredit')
      BEGIN
          
--------------------------------------------------------------------------------------------------
          SELECT @LN_NetCreditAmount =
             (CASE 
              WHEN isnull(convert(numeric(10,2),
            (SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
              - (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                    from Invoices..CreditMemoItem CI
					          inner join Invoices..CreditMemo C
					          on C.CreditStatusCode in ('APPR','PAPR')
					          and C.IDSeq = CI.CreditMemoIDSeq 
                    where CI.InvoiceIDSeq = @Invoice_ItemID))),SUM(II.NetChargeAmount)
                    ) <0
                THEN 0
            ELSE     isnull(convert(numeric(10,2),
                            (SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
                            - (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                              from Invoices..CreditMemoItem CI
					                    inner join Invoices..CreditMemo C
					                    on C.CreditStatusCode in ('APPR','PAPR')
					                    and C.IDSeq = CI.CreditMemoIDSeq 
                              where CI.InvoiceIDSeq = @Invoice_ItemID))),SUM(II.NetChargeAmount))
            END) from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   
--------------------------------------------------------------------------------------------------                                                
          SELECT @LN_TaxAmount = SUM(II.TaxAmount) 
                  from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   
--------------------------------------------------------------------------------------------------
          SELECT @LN_TaxPercent = SUM(II.TaxPercent) 
                  from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq                 
--------------------------------------------------------------------------------------------------
          SELECT @LN_SumNetPrice = SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
              from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   
---------------------------------------------------------------------------------------------------
          SELECT @LN_SumTotalCreditAmount = 
              (CASE 
                WHEN isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID ), 0)<0 
                THEN 0 
                ELSE isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID), 0) 
                END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   
---------------------------------------------------------------------------------------------------
          SELECT @LN_SumTotalTaxAmount = 
              (CASE 
               WHEN isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0) <0  
               THEN 0 
               ELSE isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0)   
               END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   
---------------------------------------------------------------------------------------------------
         
---------------------------------------------------------------------------------------------------
     END
     ELSE IF (@Mode = 'PartialCredit')
      BEGIN
          SELECT @LN_NetCreditAmount = 0

          SELECT @LN_TaxAmount      = 0

          SELECT @LN_TaxPercent = SUM(II.TaxPercent) 
                  from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq                                 

          SELECT @LN_SumNetPrice = SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
              from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq           

          SELECT @LN_SumTotalCreditAmount = 
              (CASE 
                WHEN isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID ), 0)<0 
                THEN 0 
                ELSE isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID), 0) 
                END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq          

           SELECT @LN_SumTotalTaxAmount = 
              (CASE 
               WHEN isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0) <0  
               THEN 0 
               ELSE isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0)   
               END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq              
          
      END
--------------------------------------------------------------------------------------------------
      ELSE IF (@Mode = 'FullTax')
      BEGIN
           SELECT @LN_NetCreditAmount = 0
  
           SELECT @LN_TaxAmount = SUM(II.TaxAmount) 
                  from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   

           SELECT @LN_TaxPercent = SUM(II.TaxPercent) 
                  from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq                                 

           SELECT @LN_SumNetPrice = SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
              from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq           

           SELECT @LN_SumTotalCreditAmount = 
              (CASE 
                WHEN isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID ), 0)<0 
                THEN 0 
                ELSE isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID), 0) 
                END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq          

          SELECT @LN_SumTotalTaxAmount = 
              (CASE 
               WHEN isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0) <0  
               THEN 0 
               ELSE isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0)   
               END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq              
      END
--------------------------------------------------------------------------------------------------
      ELSE IF (@Mode = 'PartialTax')
      BEGIN
          SELECT @LN_NetCreditAmount = 0

          SELECT @LN_TaxAmount      = 0

          SELECT @LN_TaxPercent = SUM(II.TaxPercent) 
                  from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq                                 

          SELECT @LN_SumNetPrice = SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
              from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq           

          SELECT @LN_SumTotalCreditAmount = 
              (CASE 
                WHEN isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID ), 0)<0 
                THEN 0 
                ELSE isnull((select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                from Invoices..CreditMemoItem CI 
					      inner join Invoices..CreditMemo C
					      on C.CreditStatusCode in ('APPR','PAPR')
					      and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceIDSeq = @Invoice_ItemID), 0) 
                END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq          

           SELECT @LN_SumTotalTaxAmount = 
              (CASE 
               WHEN isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0) <0  
               THEN 0 
               ELSE isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
               from Invoices..CreditMemoItem CI
			         inner join Invoices..CreditMemo C
			         on C.CreditStatusCode in ('APPR','PAPR')
               where CI.InvoiceIDSeq = @Invoice_ItemID), 0)   
               END)from Invoices..InvoiceItem II where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq              
      END
--------------------------------------------------------------------------------------------------
         INSERT INTO @LT_InvoiceCreditSummary
               (
                IDSeq,
                ProductCode,
                ProductName,
                ChargeType,
                CreditAmount,
                TaxAmount,
                TaxPercent,
                Total,
                NetPrice,
                TotalCreditAmount,
                TotalTaxAmount
              )
         SELECT
              @Invoice_ItemID             as IDSeq,
              null                        as ProductCode,
              @LVC_GroupName              as ProductName,
              @LC_ChargeTypeCode          as ChargeType,
              @LN_NetCreditAmount         as CreditAmount,
              @LN_TaxAmount               as TaxAmount,
              @LN_TaxPercent              as TaxPercent,
              (@LN_NetCreditAmount +
              @LN_TaxAmount)              as Total,
              @LN_SumNetPrice             as NetPrice,
              @LN_SumTotalCreditAmount    as TotalCreditAmount,
              @LN_SumTotalTaxAmount       as TotalTaxAmount
------------------------------------------------------------------------------------------------

        
------------------------------------------------------------------------------------------------              
    END
    ELSE IF @LVC_CustomBundleNameEnabledFlag = 0
    BEGIN
      IF(@Mode = 'FullCredit')
      BEGIN
-------------------------------------------------------------------------------------------------

----------                 Retrives InvocieItem data for Full Credit Mode
-------------------------------------------------------------------------------------------------
    INSERT INTO @LT_InvoiceCreditSummary
               (
                IDSeq,
                ProductCode,
                ProductName,
                ChargeType,
                CreditAmount,
                TaxAmount,
                TaxPercent,
                Total,
                NetPrice,
                TotalCreditAmount,
                TotalTaxAmount
              )
    SELECT  

      II.IDSeq                                                                       as IDSeq,
      II.ProductCode                                                                 as ProductCode,
      P.DisplayName                                                                  as ProductName,
      II.chargeTypeCode                                                              as ChargeType,
      ---------------------------------------------------------------------------
        CASE 
          WHEN isnull(convert(numeric(10,2),
                    (II.NetChargeAmount + II.TaxAmount - 
                     (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                      from Invoices..CreditMemoItem CI
					  inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq 
                      where CI.InvoiceItemIDSeq = II.IDSeq)
                      ) / (1+ II.TaxPercent/100)),
              (II.NetChargeAmount - (II.NetChargeAmount * II.TaxPercent/100 ))) < 0 
          THEN 0 
          ELSE isnull(convert(numeric(10,2),
                    (II.NetChargeAmount + II.TaxAmount - 
                     (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                        from Invoices..CreditMemoItem CI
					    inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq 
                        where CI.InvoiceItemIDSeq = II.IDSeq)
                     ) / (1+ II.TaxPercent/100)),
          (II.NetChargeAmount)) 
         END                                                                  as CreditAmount,
       -----------------------------------------------------------------


        CASE 
          WHEN isnull( convert(numeric(10,2),(II.NetChargeAmount + II.TaxAmount - 
                (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                from Invoices..CreditMemoItem CI 
			    inner join Invoices..CreditMemo C
			    on C.CreditStatusCode in ('APPR','PAPR')
			    and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceItemIDSeq = II.IDSeq))) -

                convert(numeric(10,2),(II.NetChargeAmount + II.TaxAmount - 
                (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                from Invoices..CreditMemoItem CI
			    inner join Invoices..CreditMemo C
			    on C.CreditStatusCode in ('APPR','PAPR')
			    and C.IDSeq = CI.CreditMemoIDSeq 
                where CI.InvoiceItemIDSeq = II.IDSeq)
                )/(1+ II.TaxPercent/100)),
          (II.NetChargeAmount * II.TaxPercent/100 )) < 0 
          THEN 0 
          ELSE isnull( convert(numeric(10,2),(II.NetChargeAmount + II.TaxAmount - 
                (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                from Invoices..CreditMemoItem CI
			    inner join Invoices..CreditMemo C
			    on C.CreditStatusCode in ('APPR','PAPR')
			    and C.IDSeq = CI.CreditMemoIDSeq 
                where CI.InvoiceItemIDSeq = II.IDSeq))) -

                convert(numeric(10,2),(II.NetChargeAmount + II.TaxAmount - 
                (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                from Invoices..CreditMemoItem CI 
			    inner join Invoices..CreditMemo C
			    on C.CreditStatusCode in ('APPR','PAPR')
			    and C.IDSeq = CI.CreditMemoIDSeq
                where CI.InvoiceItemIDSeq = II.IDSeq)
                )/(1+ II.TaxPercent/100)),
        (II.NetChargeAmount * II.TaxPercent/100 )) 
          END                                                                     as TaxAmount,
         ---------------------------------------------------------------

        II.TaxPercent                                                         as TaxPercent,
         ---------------------------------------------------------------

        CASE 
          WHEN isnull(convert(numeric(10,2),(II.NetChargeAmount + II.TaxAmount - 
            (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
             from Invoices..CreditMemoItem CI
			  inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq 
             where CI.InvoiceItemIDSeq = II.IDSeq))),
             II.NetChargeAmount) < 0 
          THEN 0 
          ELSE isnull(convert(numeric(10,2),(II.NetChargeAmount + II.TaxAmount - 
            (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
            from Invoices..CreditMemoItem CI
		    inner join Invoices..CreditMemo C
		    on C.CreditStatusCode in ('APPR','PAPR')
		    and C.IDSeq = CI.CreditMemoIDSeq  
		    where CI.InvoiceItemIDSeq = II.IDSeq))),
            II.NetChargeAmount + II.TaxAmount) 
          END                                                                 as Total,
         ---------------------------------------------------------------

       
        convert(numeric(10,3),convert(numeric(10,2),II.NetChargeAmount + II.TaxAmount),101)  as NetPrice,
         ----------------------------------------------------------------

        CASE 
          WHEN isnull(
            (   select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                      from Invoices..CreditMemoItem CI 
					  inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq
                      where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
          THEN 0 
          ELSE isnull(
            (   select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                      from Invoices..CreditMemoItem CI 
					  inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq
                      where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
          END                                                                 as TotalCreditAmount,
         ----------------------------------------------------------------

        CASE 
          WHEN isnull(
              ( select  convert(numeric(10,2),sum(CI.TaxAmount))  
                from Invoices..CreditMemoItem CI
			    inner join Invoices..CreditMemo C
			    on C.CreditStatusCode in ('APPR','PAPR')
                where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0  
          THEN 0 
          ELSE isnull(
             (  select  convert(numeric(10,2),sum(CI.TaxAmount))  
                from Invoices..CreditMemoItem CI
			    inner join Invoices..CreditMemo C
			    on C.CreditStatusCode in ('APPR','PAPR')
                where CI.InvoiceItemIDSeq = II.IDSeq ), 0)   
          END                                                                 as TotalTaxAmount
         ----------------------------------------------------------------
        FROM            Invoices.dbo.[InvoiceItem] II (nolock)
        
        INNER JOIN      Invoices.dbo.[InvoiceGroup] IG (nolock)
          ON            II.InvoiceGroupIDSeq = IG.IDSeq
        
        LEFT OUTER JOIN Invoices.dbo.[Invoice] I (nolock)
          ON            I.InvoiceIDSeq = IG.InvoiceIDSeq

        LEFT OUTER JOIN Products..Product P (nolock)
          ON            II.ProductCode = P.Code
          and           II.PriceVersion= P.PriceVersion

        WHERE           IG.InvoiceIDSeq = @Invoice_ItemID 
        AND             II.ExtChargeAmount  > II.CreditAmount
       

        ORDER BY P.Name
      END    
-------------------------------------------------------------------------------------------------

    ELSE if(@Mode = 'PartialCredit')
    BEGIN
    INSERT INTO @LT_InvoiceCreditSummary
               (
                IDSeq,
                ProductCode,
                ProductName,
                ChargeType,
                CreditAmount,
                TaxAmount,
                TaxPercent,
                Total,
                NetPrice,
                TotalCreditAmount,
                TotalTaxAmount
              )
-------------------------------------------------------------------------------------------------

----------                  Retrives InvocieItem data for Partial Credit Mode
-------------------------------------------------------------------------------------------------
    SELECT  II.IDSeq                                                        as IDSeq,
            II.ProductCode                                                  as ProductCode,
            P.DisplayName                                                   as ProductName,
            II.chargeTypeCode                                               as ChargeType,
            0                                                               as CreditAmount,
            0                                                               as TaxAmount,
            II.TaxPercent                                                   as TaxPercent,
            0                                                               as Total,
            convert(numeric(10,2),II.NetChargeAmount + II.TaxAmount)                       as NetPrice,
            ---------------------------------------------------------------         
            CASE 
            WHEN isnull((
            select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                    from Invoices..CreditMemoItem CI 
					  inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq
                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
            THEN 0 
            ELSE isnull((
            select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                    from Invoices..CreditMemoItem CI 
					  inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq
                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END                                                             as TotalCreditAmount,
            ---------------------------------------------------------------   
            CASE 
            WHEN isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
                         from Invoices..CreditMemoItem CI
						inner join Invoices..CreditMemo C
						on C.CreditStatusCode in ('APPR','PAPR')
						and C.IDSeq = CI.CreditMemoIDSeq 
                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0 
            THEN 0 
            ELSE
              isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
                      from Invoices..CreditMemoItem CI
					  inner join Invoices..CreditMemo C
					  on C.CreditStatusCode in ('APPR','PAPR')
					  and C.IDSeq = CI.CreditMemoIDSeq 
                      where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END                                                             as TotalTaxAmount
            --------------------------------------------------------------

          FROM            Invoices.dbo.[InvoiceItem] II (nolock)
        
          INNER JOIN      Invoices.dbo.[InvoiceGroup] IG (nolock)
            ON            II.InvoiceGroupIDSeq = IG.IDSeq
          
          LEFT OUTER JOIN Invoices.dbo.[Invoice] I (nolock)
            ON            I.InvoiceIDSeq = IG.InvoiceIDSeq

          LEFT OUTER JOIN Products..Product P (nolock)
            ON            II.ProductCode = P.Code
            and           II.PriceVersion= P.PriceVersion

          WHERE           IG.InvoiceIDSeq = @Invoice_ItemID  
                 AND             II.ExtChargeAmount  > II.CreditAmount

          ORDER BY P.Name
    END
-------------------------------------------------------------------------------------------------
    ELSE IF(@Mode = 'FullTax')
    BEGIN
      INSERT INTO @LT_InvoiceCreditSummary
               (
                IDSeq,
                ProductCode,
                ProductName,
                ChargeType,
                CreditAmount,
                TaxAmount,
                TaxPercent,
                Total,
                NetPrice,
                TotalCreditAmount,
                TotalTaxAmount
              )
-------------------------------------------------------------------------------------------------
----------                  Retrives InvocieItem data for Full Tax Mode
-------------------------------------------------------------------------------------------------
      SELECT  

              II.IDSeq                                                        as IDSeq,
              II.ProductCode                                                  as ProductCode,
              P.DisplayName                                                   as ProductName,
              II.chargeTypeCode                                               as ChargeType,
              0                                                               as CreditAmount,
              ---------------------------------------------------------------
              CASE 
                WHEN  isnull( convert(numeric(10,2),(II.NetChargeAmount - 
                                (   select  convert(numeric(10,2),
                                            sum(CI.NetCreditAmount))  
                                    from Invoices..CreditMemoItem CI 
								    inner join Invoices..CreditMemo C
								    on C.CreditStatusCode in ('APPR','PAPR')
								    and C.IDSeq = CI.CreditMemoIDSeq 
                                    where CI.InvoiceItemIDSeq = II.IDSeq))) -

                                convert(numeric(10,2),(II.NetChargeAmount - 
                                (   select  convert(numeric(10,2),
                                            sum(CI.NetCreditAmount))  
                                    from Invoices..CreditMemoItem CI 
									  inner join Invoices..CreditMemo C
									  on C.CreditStatusCode in ('APPR','PAPR')
									  and C.IDSeq = CI.CreditMemoIDSeq 
                                    where CI.InvoiceItemIDSeq = II.IDSeq)
                                 )/(1+ II.TaxPercent/100)),
                              (II.NetChargeAmount * II.TaxPercent/100 )) < 0 
              THEN 0 
              ELSE  isnull( convert(numeric(10,2),(II.NetChargeAmount - 
                              (     select  convert(numeric(10,2),
                                            sum(CI.NetCreditAmount))  
                                    from Invoices..CreditMemoItem CI
								    inner join Invoices..CreditMemo C
								    on C.CreditStatusCode in ('APPR','PAPR')
					                and C.IDSeq = CI.CreditMemoIDSeq  
                                    where CI.InvoiceItemIDSeq = II.IDSeq))) -

                            convert(numeric(10,2),(II.NetChargeAmount - 
                              (     select  convert(numeric(10,2),
                                            sum(CI.NetCreditAmount))  
                                    from Invoices..CreditMemoItem CI
								   inner join Invoices..CreditMemo C
								   on C.CreditStatusCode in ('APPR','PAPR')
								   and C.IDSeq = CI.CreditMemoIDSeq  
                                    where CI.InvoiceItemIDSeq = II.IDSeq)
                              )/(1+ II.TaxPercent/100)),
                             (II.NetChargeAmount * II.TaxPercent/100 )) 
             END                                                              as TaxAmount,
             ----------------------------------------------------------------

             II.TaxPercent                                                   as TaxPercent,
             ----------------------------------------------------------------                
             
             CASE 
              WHEN isnull( convert(numeric(10,2),(II.NetChargeAmount + II.TaxAmount - 
                      (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                       from Invoices..CreditMemoItem CI
						  inner join Invoices..CreditMemo C
					    on C.CreditStatusCode in ('APPR','PAPR')
					    and C.IDSeq = CI.CreditMemoIDSeq  
                       where CI.InvoiceItemIDSeq = II.IDSeq))) -

                      convert(numeric(10,2),(II.NetChargeAmount - 
                      (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                      from Invoices..CreditMemoItem CI 
					    inner join Invoices..CreditMemo C
					    on C.CreditStatusCode in ('APPR','PAPR')
					    and C.IDSeq = CI.CreditMemoIDSeq 
                      where CI.InvoiceItemIDSeq = II.IDSeq)
                      )/(1+ II.TaxPercent/100)),
                      (II.NetChargeAmount * II.TaxPercent/100 ))<0 
              THEN 0 
              ELSE  isnull( convert(numeric(10,2),(II.NetChargeAmount - 
                      (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                      from Invoices..CreditMemoItem CI
					    inner join Invoices..CreditMemo C
					    on C.CreditStatusCode in ('APPR','PAPR')
					    and C.IDSeq = CI.CreditMemoIDSeq  
                        where CI.InvoiceItemIDSeq = II.IDSeq))) -

                      convert(numeric(10,2),(II.NetChargeAmount - 
                      (select  convert(numeric(10,2),sum(CI.NetCreditAmount))  
                      from Invoices..CreditMemoItem CI 
					    inner join Invoices..CreditMemo C
					    on C.CreditStatusCode in ('APPR','PAPR')
					    and C.IDSeq = CI.CreditMemoIDSeq 
                        where CI.InvoiceItemIDSeq = II.IDSeq)
                      )/(1+ II.TaxPercent/100)),
                      (II.NetChargeAmount * II.TaxPercent/100 )) 
              END                                                               as Total,
              ---------------------------------------------------------------

              convert(numeric(10,2),II.NetChargeAmount)                       as NetPrice,
              ---------------------------------------------------------------

              isnull((
              select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                                  from Invoices..CreditMemoItem CI 
					              inner join Invoices..CreditMemo C
					              on C.CreditStatusCode in ('APPR','PAPR')
					              and C.IDSeq = CI.CreditMemoIDSeq
                        where CI.InvoiceItemIDSeq = II.IDSeq  ), 0)              as TotalCreditAmount,
              ----------------------------------------------------------------

              isnull((select  convert(numeric(10,2),sum(CI.TaxAmount))  
                      from Invoices..CreditMemoItem CI
					            inner join Invoices..CreditMemo C
					            on C.CreditStatusCode in ('APPR','PAPR')
					            and C.IDSeq = CI.CreditMemoIDSeq  
                                where CI.InvoiceItemIDSeq = II.IDSeq ), 0)              as TotalTaxAmount
              ----------------------------------------------------------------


          FROM            Invoices.dbo.[InvoiceItem] II (nolock)
          
          INNER JOIN      Invoices.dbo.[InvoiceGroup] IG (nolock)
            ON            II.InvoiceGroupIDSeq = IG.IDSeq
          
          LEFT OUTER JOIN Invoices.dbo.[Invoice] I (nolock)
            ON            I.InvoiceIDSeq = IG.InvoiceIDSeq

          LEFT OUTER JOIN Products..Product P (nolock)
            ON            II.ProductCode = P.Code
            and           II.PriceVersion= P.PriceVersion

          WHERE           IG.InvoiceIDSeq = @Invoice_ItemID  
          AND             II.ExtChargeAmount  > II.CreditAmount

          ORDER BY P.Name
    END
-------------------------------------------------------------------------------------------------
    ELSE IF(@Mode = 'PartialTax')
    BEGIN
        INSERT INTO @LT_InvoiceCreditSummary
               (
                IDSeq,
                ProductCode,
                ProductName,
                ChargeType,
                CreditAmount,
                TaxAmount,
                TaxPercent,
                Total,
                NetPrice,
                TotalCreditAmount,
                TotalTaxAmount
              )
-------------------------------------------------------------------------------------------------
----------                  Retrives InvocieItem data for Partial Tax Mode
-------------------------------------------------------------------------------------------------
        SELECT  
                    II.IDSeq                                                    as IDSeq,
                    II.ProductCode                                              as ProductCode,
                    P.DisplayName                                               as ProductName,
                    II.chargeTypeCode                                           as ChargeType,
                    0                                                           as CreditAmount,
                    0                                                           as TaxAmount,
                    II.TaxPercent                                               as TaxPercent,
                    0                                                           as Total,
                    convert(numeric(10,2),II.NetChargeAmount)                   as NetPrice,
                    -----------------------------------------------------------
                    case 
                    when isnull(
                        (select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                         from Invoices..CreditMemoItem CI
						             inner join Invoices..CreditMemo C
						             on C.CreditStatusCode in ('APPR','PAPR')
						             and C.IDSeq = CI.CreditMemoIDSeq 
                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0 
                    then 0 
                    else isnull(
                        (select  convert(numeric(10,2),sum(CI.ExtCreditAmount))  
                         from Invoices..CreditMemoItem CI 
						            inner join Invoices..CreditMemo C
						            on C.CreditStatusCode in ('APPR','PAPR')
						            and C.IDSeq = CI.CreditMemoIDSeq
                        where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
                    end                                                         as TotalCreditAmount,
                    -----------------------------------------------------------

                    case 
                    when isnull(
                        (select  convert(numeric(10,2),sum(CI.TaxAmount))  
                         from Invoices..CreditMemoItem CI
						             inner join Invoices..CreditMemo C
						             on C.CreditStatusCode in ('APPR','PAPR')
						             and C.IDSeq = CI.CreditMemoIDSeq 
                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0)  <0 
                    then 0 
                    else isnull(
                        (select  convert(numeric(10,2),sum(CI.TaxAmount))  
                         from Invoices..CreditMemoItem CI
						             inner join Invoices..CreditMemo C
						             on C.CreditStatusCode in ('APPR','PAPR')
						             and C.IDSeq = CI.CreditMemoIDSeq 
                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
                    end                                                         as TotalTaxAmount
                    -----------------------------------------------------------

          FROM            Invoices.dbo.[InvoiceItem] II (nolock)
          
          INNER JOIN      Invoices.dbo.[InvoiceGroup] IG (nolock)
            ON            II.InvoiceGroupIDSeq = IG.IDSeq
          
          LEFT OUTER JOIN Invoices.dbo.[Invoice] I (nolock)
            ON            I.InvoiceIDSeq = IG.InvoiceIDSeq

          LEFT OUTER JOIN Products..Product P (nolock)
            ON            II.ProductCode = P.Code
            and           II.PriceVersion= P.PriceVersion

          WHERE           IG.InvoiceIDSeq = @Invoice_ItemID  
          AND             II.ExtChargeAmount  > II.CreditAmount

          ORDER BY P.Name
    END
-------------------------------------------------------------------------------------------------
    END
    SET @LV_Counter = @LV_Counter + 1
  END
        INSERT INTO @LT_InvoiceCreditTotals
        (
            TotalCredit,
            TotalTax,
            NetTotal
        )
        SELECT 
            SUM(CreditAmount),
            SUM(TaxAmount),
            SUM(Total)
        FROM @LT_InvoiceCreditSummary
        

  SELECT IDSeq,
         ProductCode,
         ProductName,
         ChargeType,
         CreditAmount,
         TaxAmount,
         TaxPercent,
         Total,
         NetPrice,
         TotalCreditAmount,
         TotalTaxAmount 
  FROM @LT_InvoiceCreditSummary
  
  SELECT TotalCredit,
         TotalTax,
         NetTotal 
  FROM @LT_InvoiceCreditTotals

END
--Exec Invoices..uspINVOICES_InvoiceItemSelect1 'I0000001189','FullTax'   
--Exec Invoices..uspINVOICES_InvoiceItemSelect1 'I0000001169','FullTax'   
GO
