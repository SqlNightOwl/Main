SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspProducts_GetPostingCode
-- Description     : Get Posting Code for the Product
-- Input Parameters: 
-- Code Example    : --EXEC [PRODUCTS].dbo.[uspProducts_GetPostingCode]  
-- Revision History:
-- Author          : Mahaboob
-- 07/01/2011      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspProducts_GetPostingCode]
( 
  @ProductCode char(30)
)
AS
BEGIN
	 SELECT F.EpicorPostingCode as PostingCode
	 FROM  Products.dbo.Product P with (nolock)
     inner join Products.dbo.Family  F with (nolock)
     on P.FamilyCode = F.Code and P.Code = @ProductCode
END
GO
