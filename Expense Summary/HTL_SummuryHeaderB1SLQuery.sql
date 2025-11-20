USE [SBOHTL_v4]
GO

/****** Object:  View [dbo].[HTL_SummuryHeaderB1SLQuery]    Script Date: 11/20/2025 9:31:55 AM ******/
DROP VIEW [dbo].[HTL_SummuryHeaderB1SLQuery]
GO

/****** Object:  View [dbo].[HTL_SummuryHeaderB1SLQuery]    Script Date: 11/20/2025 9:31:55 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO









-- Create the view
CREATE VIEW [dbo].[HTL_SummuryHeaderB1SLQuery] AS


SELECT
	A.DocNum,
    A.AbsEntry			As [AbsEntry],
    A.NAME			As [FIPROJECT],
    A.U_HT_Commo		As [U_HT_Commo],
    A.U_HT_eta_Date		As [U_HT_eta_Date],
    A.U_HT_Declare		As [U_HT_Declare],
    A.U_HT_Volume		As [U_HT_Volume],
    A.U_HT_Clearby		As [U_HT_Clearby],
    A.U_HT_Close_Draft_Date AS [U_HT_Close_Draft_Date],
    --A.U_HT_ETA_Border	AS [U_HT_ETA_Border],
	ISNULL(CONVERT(VARCHAR(10),A.U_HT_eta_Date,120),N'') + CASE WHEN A.U_HT_eta_Date IS NOT NULL AND A.U_HT_ETA_Border IS NOT NULL THEN '/ 'ELSE ''END + ISNULL(CONVERT(VARCHAR(10),A.U_HT_ETA_Border,120),N'')	AS [U_HT_ETA_Border],
    D.CardName			AS [CardName],
    A.CARDCODE			AS [CARDCODE],
    A.NAME AS [Project_Name],
	A.U_HT_SettleDate	AS [Settle Date],
    --CASE
    --    WHEN A.U_HT_ShipType = 1 THEN 'LCL'
    --    WHEN A.U_HT_ShipType = 2 THEN 'FCL'
    --END AS [U_HT_ShipType],
	F_2.Descr AS [U_HT_ShipType],
    (
        SELECT STRING_AGG(ConNo, ', ') AS Expr1
        FROM dbo.PRJ_COTNN AS J
        WHERE (A.AbsEntry = ConEntry)
    ) AS [CONTAINER NO],
    ISNULL(
        CONVERT(
            VARCHAR(10),
            A.U_HT_ETA_Border,
            120
        ),
        N''
    ) + CASE
        WHEN A.U_HT_ETA_Border IS NOT NULL
        AND A.U_HT_eta_Date IS NOT NULL THEN ',  '
        ELSE ''
    END + ISNULL(
        CONVERT(
            VARCHAR(10),
            A.U_HT_eta_Date,
            120
        ),
        N''
    ) AS ETA,
    a.[NAME] as PrjName
FROM dbo.OPMG AS A
    LEFT OUTER JOIN dbo.OPRJ AS B ON A.FIPROJECT = B.PrjCode
    LEFT OUTER JOIN dbo.OCRD AS D ON A.U_HT_Shipper = D.CardCode
	LEFT JOIN OPRJ F ON A.FIPROJECT = F.PrjCode

	LEFT JOIN (


	  SELECT B.Descr, CAST(B.FldValue AS varchar(20)) AS FldValue
  FROM CUFD A
  JOIN UFD1 B
    ON B.TableID = A.TableID AND B.FieldID = A.FieldID
  WHERE A.TableID = 'OPCH' AND A.AliasID = 'HT_TRANTYPE'

        --SELECT B.[Descr],
        --    CAST(B.[FldValue] AS VARCHAR(20)) [FldValue]
        --FROM CUFD A
        --    INNER JOIN UFD1 B ON A.[TableID] = B.[TableID]
        --    AND A.[FieldID] = B.[FieldID]
        --WHERE A.[TableID] = 'OPMG'
        --    AND A.[AliasID] = 'HT_ShipType'
    ) F_2 ON A.U_HT_TRANTYPE = F_2.FldValue
GO


