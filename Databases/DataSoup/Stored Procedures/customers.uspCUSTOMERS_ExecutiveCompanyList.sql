SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Customers
-- Procedure Name  : uspCustomers_ExecutiveCompanyList
-- Description     : This procedure gets ExecutiveCompanies list.
-- Input Parameters:   @IPI_PageNumber       as  int, 
--                     @IPI_RowsPerPage      as  int, 
--					   @IPVC_CustomerID      as  varchar
--                     @IPVC_CustomerName     as  varchar, 
-- Revision History:
-- Author          : Mahaboob
-- 07/26/2011      : Stored Procedure Created.
-- 2011-09-06      : Mahaboob ( TFS 1026)     --  Changes  are made as per the Revised "ExecutiveCompany" table script 
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_ExecutiveCompanyList] (@IPI_PageNumber    int, 
															@IPI_RowsPerPage   int,
															@IPVC_CustomerID   varchar(50), 
															@IPVC_CustomerName varchar(200)
															)  
AS
BEGIN-->Main Begin
  set nocount on;  
  --------------------------------------
  declare @LN_CHECKSUM  numeric(30,0)
  ---------------------------------------
  select @LN_CHECKSUM = checksum(coalesce(@IPVC_CustomerID,''),
								 coalesce(@IPVC_CustomerName,'')
                                );
  ---------------------------------------
  DECLARE
	@LVI_PageNumber    int, 
	@LVI_RowsPerPage   int

  SELECT
	@LVI_PageNumber   = @IPI_PageNumber,
	@LVI_RowsPerPage  = @IPI_RowsPerPage,
	@IPVC_CustomerID  = nullif(@IPVC_CustomerID,'')
  
  declare @LI_Min        bigint;
  declare @LI_Max        bigint;
  ---------------------------------------------------------------------------
  select  @LI_Min = (@LVI_PageNumber-1) * @LVI_RowsPerPage,
          @LI_Max = (@LVI_PageNumber)   * @LVI_RowsPerPage;
  SET ROWCOUNT @LI_Max;
  --Final Select 
  if @LN_CHECKSUM = 0
  begin
    ----------------------------------------------------------------------------
    WITH tablefinal AS 
    ----------------------------------------------------------------------------  
       (SELECT tableinner.*
        FROM
       ----------------------------------------------------------------------------
       (select  row_number() over(order by source.[CompanyName]   asc)
                                     as RowNumber,
                source.*
        from
        (
         select distinct
          e.ExecutiveCompanyIDSeq                       as ExecutiveCompanyID, 
          e.CompanyIDSeq                                as CustomerID, 
          e.CompanyName									as CompanyName,
          (case 
				when e.ActiveFlag = 1 then 'Active'
                when e.ActiveFlag = 0 then 'Inactive'
           end
          )												as Status    
          from CUSTOMERS.dbo.ExecutiveCompany e with (nolock) 
          inner join CUSTOMERS.dbo.Company c with (nolock)
          on c.IDSeq = e.CompanyIDSeq and c.StatusTypeCode = 'ACTIV'
		  --where e.ActiveFlag = 1          
    ) source
   -----------------------------------------------------------------------------------
    )tableinner 
 
    WHERE tableinner.RowNumber >  @LI_Min
    AND   tableinner.RowNumber <= @LI_Max
    )
    SELECT  tablefinal.RowNumber,
            tablefinal.[ExecutiveCompanyID]           as [ExecutiveCompanyID],
            tablefinal.[CustomerID]                   as [CustomerID],
			tablefinal.[CompanyName]                  as [CompanyName],
			tablefinal.[Status]                       as [Status]
    FROM    tablefinal 
	ORDER BY [ExecutiveCompanyID] desc
  end
  else
    begin
    ----------------------------------------------------------------------------
    WITH tablefinal AS 
    ----------------------------------------------------------------------------  
       (SELECT tableinner.*
        FROM
       ----------------------------------------------------------------------------
       (select  row_number() over(order by source.[CompanyName]   asc)
                                     as RowNumber,
                source.*
        from
        (
          select distinct
          e.ExecutiveCompanyIDSeq                       as ExecutiveCompanyID, 
          e.CompanyIDSeq                                as CustomerID, 
          e.CompanyName									as CompanyName,
          (case 
				when e.ActiveFlag = 1 then 'Active'
                when e.ActiveFlag = 0 then 'Inactive'
           end
          )												as Status    
          from CUSTOMERS.dbo.ExecutiveCompany e with (nolock) 
		  inner join CUSTOMERS.dbo.Company c with (nolock)
          on c.IDSeq = e.CompanyIDSeq and c.StatusTypeCode = 'ACTIV'          
		  where e.CompanyIDSeq = coalesce(@IPVC_CustomerID, e.CompanyIDSeq)
          and   e.CompanyName like '%' + @IPVC_CustomerName + '%'   
		  --and   e.ActiveFlag = 1     
    ) source
   -----------------------------------------------------------------------------------
    )tableinner 
 
    WHERE tableinner.RowNumber >  @LI_Min
    AND   tableinner.RowNumber <= @LI_Max
    )
    SELECT  tablefinal.RowNumber,
            tablefinal.[ExecutiveCompanyID]           as [ExecutiveCompanyID],
            tablefinal.[CustomerID]                   as [CustomerID],
			tablefinal.[CompanyName]                  as [CompanyName],
			tablefinal.[Status]                       as [Status]
    FROM    tablefinal
	ORDER BY [ExecutiveCompanyID] desc 
  end
  --------------------------------------------------------------------------------------
  ---Final Cleanup 
  --------------------------------------------------------------------------------------
END--->Main End




GO
