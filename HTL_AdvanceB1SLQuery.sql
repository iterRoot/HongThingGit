USE [SBOHTL_v4]
GO

/****** Object:  View [dbo].[HTL_AdvanceB1SLQuery]    Script Date: 11/19/2025 10:46:05 AM ******/
DROP VIEW [dbo].[HTL_AdvanceB1SLQuery]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[HTL_AdvanceB1SLQuery] AS

WITH Project_Header AS (
    SELECT
        1 AS [Header],
        A.DocNum,
        A.AbsEntry,
        A.NAME AS [REF],
        A.FIProject,
        A.U_HT_Close_Draft_Date,
        A.U_HT_Volume,
        A.U_HT_Commo,
        A.U_HT_Clearby,
        A.U_HT_Declare_No,
        A.U_HT_TRANTYPE,
        A.U_HT_Via,
        A.CardCode AS [CardCode],
        (
            SELECT STRING_AGG(J.ConNo, ', ')
            FROM PRJ_COTNN AS J
            WHERE J.ConEntry = A.AbsEntry
        ) AS [CONTAINER NO],
        D.CardName
    FROM OPMG AS A
    LEFT JOIN OCRD AS D ON D.CardCode = A.U_HT_Shipper
    LEFT JOIN OPRJ AS F ON A.FIPROJECT = F.PrjCode
),

CR_AGG AS (
    SELECT
        Y.U_HT_JobNo,
        Y1.BaseEntry,
        Y1.BaseLine,
        SUM(ISNULL(Y1.GTotal, 0)) AS CR_GTotal
    FROM RPC1 AS Y1
    LEFT JOIN ORPC AS Y ON Y1.DocEntry = Y.DocEntry
    GROUP BY Y1.BaseEntry, Y1.BaseLine, Y.U_HT_JobNo
),

UDF_TranType AS (
    SELECT
        B.Descr,
        CAST(B.FldValue AS varchar(20)) AS FldValue
    FROM CUFD A
    JOIN UFD1 B ON B.TableID = A.TableID AND B.FieldID = A.FieldID
    WHERE A.TableID = 'OPCH'
      AND A.AliasID = 'HT_TRANTYPE'
),

Base AS (
    SELECT *
    FROM (
        SELECT
            2 AS [Row],
            A.AbsEntry,
            B.DocEntry,
            B.DocNum AS [APDocNum],
            B1.LineNum,
            A.FIProject,
            B.DocDate AS [PostingDate],
            B1.U_HT_Remark AS [U_Other],
            B1.Dscription AS [U_tl_expdic],
            F1.Descr AS [TYPE],
            A.[Name] AS [Project_Name],
            (ISNULL(B1.LineTotal,0) + ISNULL(B1.VatSum,0) - ISNULL(CA.CR_GTotal,0)) AS LineTotal,
            ap.ap_qty,
            SUM((ISNULL(B1.LineTotal,0) + ISNULL(B1.VatSum,0)) - ISNULL(CA.CR_GTotal,0))
                OVER (PARTITION BY A.AbsEntry) AS TotalCost2S
        FROM OPMG AS A
        INNER JOIN OPCH AS B
            ON A.AbsEntry = B.U_HT_JobNo AND B.DocType = 'S' AND B.CANCELED = 'N'
        INNER JOIN PCH1 AS B1 ON B1.DocEntry = B.DocEntry
        LEFT JOIN RPC1 AS Y1
            ON B1.DocEntry = Y1.BaseEntry
            AND B1.ObjType = Y1.BaseType
            AND B1.LineNum = Y1.BaseLine
        LEFT JOIN CR_AGG AS CA
            ON CA.BaseEntry = B1.DocEntry
            AND CA.BaseLine = B1.LineNum
            AND CA.U_HT_JobNo = A.AbsEntry
        LEFT JOIN UDF_TranType AS F1 ON F1.FldValue = A.U_HT_TRANTYPE
        OUTER APPLY (
            SELECT ap_qty =
                ISNULL(
                    TRY_CONVERT(decimal(18,3),
                        NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(B1.U_HT_Qty)), ',', ''), ' ', ''), '')
                    ),
                    0
                )
        ) AS ap
        WHERE B1.U_tl_expdic <> 'OP-0041'
          AND B.DocType = 'S'
          AND B.CANCELED = 'N'
    ) Z
    WHERE Z.LineTotal <> 0
),

Final AS (
    SELECT
        H.DocNum,
        B.PostingDate,
        B.DocEntry,
        B.APDocNum,
        B.LineNum,
        H.Header,
        B.[Row],
        H.AbsEntry,
        H.[REF],
        H.FIProject,
        H.U_HT_Close_Draft_Date,
        H.U_HT_Volume,
        H.U_HT_Commo,
        H.U_HT_Clearby,
        H.U_HT_Declare_No,
        H.U_HT_TRANTYPE,
        H.U_HT_Via,
        B.[U_Other],
        B.[U_tl_expdic],
        B.[TYPE],
        B.[Project_Name],
        B.LineTotal,
        H.CardCode,
        H.[CONTAINER NO],
        H.CardName
    FROM Project_Header AS H
    LEFT JOIN Base AS B ON B.AbsEntry = H.AbsEntry
    GROUP BY
        B.PostingDate, H.DocNum, H.AbsEntry, H.Header, H.[REF], B.[Row],
        H.FIProject, H.U_HT_Close_Draft_Date, H.U_HT_Volume, H.U_HT_Commo,
        H.U_HT_Clearby, H.U_HT_Declare_No, H.U_HT_TRANTYPE, H.U_HT_Via,
        B.[U_Other], B.[U_tl_expdic], B.[TYPE], B.[Project_Name], H.CardCode,
        B.LineTotal, H.[CONTAINER NO], B.DocEntry, B.APDocNum, B.LineNum, H.CardName
),

MergedCharges AS (
    SELECT
        MIN(B.PostingDate) AS DocDate,
        B.AbsEntry,
        B.DocEntry,
        B.LineNum,
        B.Header,
        B.[Row],
        B.DocNum,
        B.APDocNum,
        MAX(B.REF) AS REF,
        MAX(B.FIProject) AS FIProject,
        MAX(B.U_HT_Close_Draft_Date) AS U_HT_Close_Draft_Date,
        MAX(B.U_HT_Volume) AS U_HT_Volume,
        MAX(B.U_HT_Commo) AS U_HT_Commo,
        MAX(B.U_HT_Clearby) AS U_HT_Clearby,
        MAX(B.U_HT_Declare_No) AS U_HT_Declare_No,
        MAX(B.U_HT_TRANTYPE) AS U_HT_TRANTYPE,
        MAX(B.U_HT_Via) AS U_HT_Via,
        B.U_Other,
        B.U_tl_expdic,
        B.[TYPE],
        B.Project_Name,
        SUM(B.LineTotal) AS LineTotal,
        MAX(B.CardCode) AS CardCode,
        MAX(B.[CONTAINER NO]) AS [CONTAINER NO],
        MAX(B.CardName) AS CardName
    FROM Final AS B
    GROUP BY
        B.AbsEntry, B.Header, B.[Row], B.U_tl_expdic, B.[TYPE],
        B.Project_Name, B.U_Other, B.DocNum, B.DocEntry, B.APDocNum, B.LineNum
),

Ap_invoice AS (
    SELECT
        M.DocNum,
        M.DocDate,
        M.APDocNum,
        CAST(NULL AS varchar(50)) AS CnNum,
        M.DocEntry,
        M.AbsEntry,
        M.Header,
        M.[Row],
        M.REF,
        M.FIProject,
        M.U_HT_Close_Draft_Date,
        M.U_HT_Volume,
        M.U_HT_Commo,
        M.U_HT_Clearby,
        M.U_HT_Declare_No,
        M.U_HT_TRANTYPE,
        M.U_HT_Via,
        M.U_Other,
        M.U_tl_expdic,
        M.[TYPE],
        M.Project_Name,
        M.LineTotal,
        M.CardCode,
        M.[CONTAINER NO],
        M.CardName
        --SUM(M.LineTotal) OVER (PARTITION BY M.AbsEntry) AS TotalCost1,
        --CASE
        --    WHEN M.[Row] = 2 THEN ROW_NUMBER() OVER (
        --        PARTITION BY M.AbsEntry
        --        ORDER BY
        --            CASE WHEN M.DocDate IS NULL THEN 1 ELSE 0 END,
        --            CONVERT(date, M.DocDate),
        --            M.APDocNum,
        --            ISNULL(M.LineNum, 0),
        --            M.DocEntry
        --    )
        --    ELSE 0
        --END AS [PostingDate1]
    FROM MergedCharges AS M
),

Credit_Diret AS (
    SELECT
        CAST(t.Projecct_No AS varchar(50)) AS DocNum,
        CAST(t.DocDate AS date) AS DocDate,
        CAST(NULL AS varchar(50)) AS APDocNum,
        CAST(t.DocNum AS varchar(50)) AS CnNum,
        CAST(t.DocEntry AS int) AS DocEntry,
        CAST(t.AbsEntry AS int) AS AbsEntry,
        CAST(1 AS int) AS Header,
        CAST(2 AS int) AS [Row],
        CAST(t.NAME AS varchar(200)) AS REF,
        CAST(t.FIPROJECT AS varchar(50)) AS FIProject,
        CAST(t.U_HT_Close_Draft_Date AS varchar(50)) AS U_HT_Close_Draft_Date,
        CAST(t.U_HT_Volume AS varchar(50)) AS U_HT_Volume,
        CAST(t.U_HT_Commo AS varchar(50)) AS U_HT_Commo,
        CAST(t.U_HT_Clearby AS varchar(50)) AS U_HT_Clearby,
        CAST(t.U_HT_Declare_No AS varchar(50)) AS U_HT_Declare_No,
        CAST(t.U_HT_TRANTYPE AS varchar(50)) AS U_HT_TRANTYPE,
        CAST(t.U_HT_Via AS varchar(50)) AS U_HT_Via,
        CAST(t.U_HT_Remark AS varchar(200)) AS U_Other,
        CAST(t.Dscription AS varchar(200)) AS U_tl_expdic,
        CAST(t.[TYPE] AS varchar(100)) AS [TYPE],
        CAST(t.name AS varchar(200)) AS Project_Name,
        CAST(-t.DocTotal AS decimal(18,2)) AS LineTotal,
        CAST(t.CardCode AS varchar(50)) AS CardCode,
        CAST(t.[CONTAINER NO] AS varchar(200)) AS [CONTAINER NO],
        CAST(t.CardName AS varchar(200)) AS CardName
        --t.TotalCost1 AS TotalCost1,
        --CAST(0 AS int) AS PostingDate1
    FROM (
        SELECT
            a.DocNum AS Projecct_No,
            a.NAME,
            a.AbsEntry,
            a.U_HT_Close_Draft_Date,
            a.U_HT_Volume,
            a.U_HT_Commo,
            a.U_HT_Clearby,
            a.U_HT_Declare_No,
            a.U_HT_TRANTYPE,
            a.CardCode,
            a.U_HT_Via,
            a.FIPROJECT,
            F1.Descr AS [TYPE],
            d.CardName,
            crap.DocNum,
            crap.DocDate,
            crap.DocEntry,
            crap.DocTotal,
            crap1.U_tl_expdic,
            crap1.Dscription,
            crap1.U_HT_Remark,
            crap1.U_other,
            SUM(crap1.LineTotal) OVER (PARTITION BY crap.DocEntry) * -1 AS TotalCost1,
            (
                SELECT STRING_AGG(J.ConNo, ', ')
                FROM PRJ_COTNN AS J
                WHERE J.ConEntry = A.AbsEntry
            ) AS [CONTAINER NO],
            ROW_NUMBER() OVER (PARTITION BY crap.DocEntry ORDER BY crap.DocEntry) AS rn
        FROM OPMG A
        LEFT JOIN ORPC crap ON A.AbsEntry = crap.U_HT_JobNo
        LEFT JOIN RPC1 crap1 ON crap.DocEntry = crap1.DocEntry
        LEFT JOIN OCRD AS D ON D.CardCode = A.U_HT_Shipper
        LEFT JOIN UDF_TranType AS F1 ON F1.FldValue = A.U_HT_TRANTYPE
        WHERE crap1.BaseEntry IS NULL
    ) t
    WHERE t.rn = 1
),

Selects AS (
    SELECT * FROM Ap_invoice
    UNION ALL
    SELECT * FROM Credit_Diret
)
SELECT
    *,
    SUM(LineTotal) OVER (PARTITION BY AbsEntry) AS TotalCost,
    CASE
        WHEN [Row] = 2 THEN ROW_NUMBER() OVER (
            PARTITION BY AbsEntry
            ORDER BY
                CASE WHEN DocDate IS NULL THEN 1 ELSE 0 END,
                CONVERT(date, DocDate)
        )
        ELSE 0
    END AS [PostingDate]
FROM Selects
--WHERE AbsEntry = 2
;
GO
