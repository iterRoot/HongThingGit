USE [SBOHTL_v4]
GO

/****** Object:  View [dbo].[HTL_DebitNoteCNB1SLQuery]    Script Date: 11/19/2025 9:55:03 AM ******/
DROP VIEW [dbo].[HTL_DebitNoteCNB1SLQuery]
GO

/****** Object:  View [dbo].[HTL_DebitNoteCNB1SLQuery]    Script Date: 11/19/2025 9:55:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Create the view HTL_DebitNoteCNB1SLQuery
CREATE VIEW [dbo].[HTL_DebitNoteCNB1SLQuery] AS
SELECT 
	A.DocEntry,
    A1.LineNum,
    /*Heder Form*/
    ISNULL(C.BeginStr, N'') + CONVERT(NVARCHAR(MAX), A.DocNum) AS [INVOICE NO] ,--[DN No],
    A.U_HT_Internal_Number AS [DN No],-- [INVOICE NO],
    /* address*/
    D1.Building AS ADDRESS,
	P.Name [CardName],
    A.CardName [COMPANY NAME],
    A.DocDueDate AS [DUE DATE],
    A.U_HT_ETD_Border AS [ETD BORDER],
    CASE
        WHEN D.Phone1 IS NULL
        OR D.Phone1 = '' THEN ISNULL(D.Phone2, '')
        WHEN D.Phone2 IS NULL
        OR D.Phone2 = '' THEN D.Phone1
        ELSE D.Phone1 + ' /' + D.Phone2
    END AS TEL,
    A.U_HT_Bill AS [BILL NO],
    A.U_HT_Como AS COMMODITY,
    CAST(I10.ItemName AS NVARCHAR(MAX)) AS ItemName,
    (
        SELECT STRING_AGG(ConNo, ', ')-- AS Expr1
        FROM dbo.PRJ_COTNN AS J
        WHERE (F.AbsEntry = J.ConEntry)
    ) AS [CONTAINER NO],
	--(SELECT J.TypeLod
	--	FROM PRJ_COTNN J
 --    WHERE F.AbsEntry = J.ConEntry) AS [TypeLod],
    --F_2.Descr AS [CTN.TYPE], OLD
	A.U_HT_Volume AS [CTN.TYPE],
    A.Comments AS [REMARK],
    A.U_HT_Note AS [NOTE],
    A.TaxDate AS [INV DATE],
    A.U_HT_Eta AS [ETA DATE],
    A.U_HT_Etad AS [ETD PORT],
    A.U_HT_ETA_Border AS [ETA BORDER],
	(
	  SELECT TOP 1 Ranked.TypeLod
	  FROM (
		  SELECT J.TypeLod, ROW_NUMBER() OVER (ORDER BY J.RowNum) AS RowNum
		  FROM PRJ_COTNN J
		  WHERE F.AbsEntry = J.ConEntry
	  ) AS Ranked
	  WHERE Ranked.RowNum = 1
	) AS [SHIPMENT TYPE],
    --F_1.Descr AS [SHIPMENT TYPE],
    A.U_HT_LP AS [POL AIRPORT],
    A.U_HT_DP AS [POD AIRPORT],
    A.U_HT_Border AS [BORDER],
    /*A.U_HT_Via AS [BY], OLD*/
    A.U_HT_Via AS [VIA],
    A.U_HT_Package AS [PACKAGE],
    A.U_HT_WEIGHT AS WEIGHT,
    F.FIPROJECT AS [JOB SHEET],
    ISNULL(E.BeginStr, N'') + CONVERT(NVARCHAR(MAX), F.DocNum) AS [PROJECT NO],
    /*DETAIL BY ROW*/
    I10.ordernum,
    CASE
        WHEN A1.LineNum IS NULL THEN 'Text'
    END AS TYPE,
    ISNULL(CAST(I10.ItemName AS NVARCHAR(MAX)), N'') + ISNULL(' / ' + I.FrgnName, N'') AS DESCRIPTION,
    A1.Quantity AS QTY,
    A1.PriceAfVAT AS [UNIT($)],
    A1.GTotal AS AMOUNT,
    /*REPORT FOORTER*/
    SUM(A1.GTotal) OVER (PARTITION BY A.DocEntry) [SubTotal],
    A9_1.TaxDate AS [Deposit Date],
    A.DpmAmnt AS DEPOSIT,
    CASE
        WHEN A.DpmAmnt IS NOT NULL THEN (
            (SUM(A1.GTotal) OVER (PARTITION BY A.DocEntry)) - isnull(A.DpmAmnt,0)
        )
        /*A.DpmAmnt*/
    END AS [BALANCE DUE],
    /*I10.ItemName,*/
    CASE
        WHEN H.ExtraDays = 0 THEN H.PymntGroup
        WHEN H.ExtraDays != 0 THEN CONVERT(VARCHAR, H.ExtraDays) + ' ' + 'DAYS'
    END AS PayMentTerms,
    G1.BankCode,
    G1.AcctName AS [Payment Cheque],
    G.BankName,
    G1.AcctName AS [BANK ACCOUNT],
    G1.Account AS [ACCOUNT NUMBER],
    /*A.U_HT_POL AS [SHIP FROM],*/
    A1.ItemCode,
    /*D.Phone2,*/
    D.CardFName,
    /*) AS [CONTAINER NO],*/
    I.FrgnName
FROM dbo.OINV AS A
    LEFT OUTER JOIN (
        SELECT T1.DocNum,
            T0_1.DocEntry,
            T0_1.VisOrder,
            T0_1.ItemName,
            T0_1.ordernum
        FROM (
                SELECT T1.DocEntry,
                    T1.VisOrder,
                    T1.Dscription AS ItemName,
                    0 AS ordernum
                FROM dbo.INV1 AS T1
                    INNER JOIN dbo.OINV AS T0 ON T0.DocEntry = T1.DocEntry
                UNION ALL
                SELECT T10.DocEntry,
                    T10.AftLineNum AS visorder,
                    T10.LineText AS ItemName,
                    T10.OrderNum AS ordernum
                FROM dbo.INV10 AS T10
                    INNER JOIN dbo.OINV AS T0 ON T0.DocEntry = T10.DocEntry
            ) AS T0_1
            LEFT OUTER JOIN dbo.OINV AS T1 ON T0_1.DocEntry = T1.DocEntry
    ) AS I10 ON A.DocEntry = I10.DocEntry
    LEFT OUTER JOIN dbo.INV1 AS A1 ON A.DocEntry = A1.DocEntry
    AND I10.VisOrder = A1.VisOrder
    AND I10.ordernum = 0
    LEFT OUTER JOIN (
        SELECT A9.DocEntry,
            A9.ObjType,
            STRING_AGG(CAST(A9.BaseAbs AS NVARCHAR(MAX)), ' ') AS BaseAbs,
            MAX(B.TaxDate) AS TaxDate
        FROM dbo.INV9 AS A9
            LEFT OUTER JOIN dbo.ODPI AS B ON A9.BaseAbs = B.DocEntry
            AND A9.ObjType = 203
        GROUP BY A9.DocEntry,
            A9.ObjType
    ) AS A9_1 ON A.DocEntry = A9_1.DocEntry
    AND A9_1.ObjType = 203
    LEFT OUTER JOIN dbo.NNM1 AS C ON A.Series = C.Series
    LEFT OUTER JOIN dbo.OCRD AS D ON A.CardCode = D.CardCode
    LEFT OUTER JOIN dbo.CRD1 AS D1 ON D.CardCode = D1.CardCode
    AND D1.AdresType = 'B'
    AND D1.Address = D.BillToDef
	--LEFT OUTER JOIN OCRD DD ON A.CntctCode = DD.CardCode
	LEFT OUTER JOIN OCPR P ON A.CntctCode = P.CntctCode 
    LEFT OUTER JOIN dbo.OPMG AS F ON A.U_HT_JobNo = F.AbsEntry
    LEFT OUTER JOIN dbo.NNM1 AS E ON F.Series = E.Series
    LEFT OUTER JOIN dbo.DSC1 AS G1 ON A.U_HT_BANK = G1.AbsEntry
    LEFT OUTER JOIN dbo.ODSC AS G ON G1.BankCode = G.BankCode
    LEFT OUTER JOIN dbo.OCTG AS H ON A.GroupNum = H.GroupNum
    LEFT OUTER JOIN dbo.OITM AS I ON A1.ItemCode = I.ItemCode
    /*   GROUP BY FieldID, Descr, FldValue) AS F1_1 ON A.U_HT_TRANTYPE = F1_1.FldValue AND F1_1.FieldID = 16 */
    LEFT JOIN (
        SELECT B.[Descr],
            CAST(B.[FldValue] AS VARCHAR(20)) [FldValue]
        FROM CUFD A
            INNER JOIN UFD1 B ON A.[TableID] = B.[TableID]
            AND A.[FieldID] = B.[FieldID]
        WHERE A.[TableID] = 'OINV'
            AND A.[AliasID] = 'HT_TRANTYPE'
    ) F_1 ON A.U_HT_TRANTYPE = F_1.FldValue
    /*          GROUP BY FieldID, Descr, FldValue) AS F1_2 ON A.U_HT_ShipType = F1_2.FldValue AND F1_2.FieldID = 21*/
    LEFT JOIN (
        SELECT B.[Descr],
            CAST(B.[FldValue] AS VARCHAR(20)) [FldValue]
        FROM CUFD A
            INNER JOIN UFD1 B ON A.[TableID] = B.[TableID]
            AND A.[FieldID] = B.[FieldID]
        WHERE A.[TableID] = 'OINV'
            AND A.[AliasID] = 'HT_ShipType'
    ) F_2 ON A.U_HT_ShipType = F_2.FldValue
	--left join PRJ_COTNN y on f.AbsEntry = y.ConEntry

--	WHERE A.DocEntry = 301
GO


