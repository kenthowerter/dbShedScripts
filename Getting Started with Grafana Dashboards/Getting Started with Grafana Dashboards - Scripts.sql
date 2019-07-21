--------------------------
-- 
-- dbShed.com
--
-- THE SAMPLE CODE ON dbShed.com IS PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, 
-- INCLUDING THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
-- ARE DISCLAIMED. IN NO EVENT SHALL PAGERDUTY OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
-- INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
-- LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
-- OR BUSINESS INTERRUPTION) SUSTAINED BY YOU OR A THIRD PARTY, HOWEVER CAUSED AND ON ANY 
-- THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING IN ANY WAY 
-- OUT OF THE USE OF THIS SAMPLE CODE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
--------------------------


CREATE TABLE dbo.Node
(
   NodeId INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
   NodeName VARCHAR(128) NOT NULL
)
GO

INSERT INTO dbo.Node (NodeName) VALUES ('DBSERVER')
GO

CREATE TABLE dbo.NodeCPU
(
   NodeCPUId NUMERIC IDENTITY(1,1) PRIMARY KEY NOT NULL,
   NodeId INT NOT NULL,
   Metric VARCHAR(64) NOT NULL,
   CPU INT NOT NULL,
   CreatedDate DATETIME NOT NULL
)
GO

DECLARE @NodeId INT = (SELECT NodeId FROM dbo.Node WHERE NodeName = 'DBSERVER');

    WITH RandomCPU
    AS(
       SELECT 1 id, 
              CAST(RAND(CHECKSUM(NEWID()))*30 as int) CPU
        UNION ALL
        SELECT id + 1, 
               CAST(RAND(CHECKSUM(NEWID()))*30 as int) CPU
        FROM RandomCPU
        WHERE id < 100000
      )
    INSERT INTO dbo.NodeCPU ([NodeId], [Metric], [CPU], [CreatedDate])
    SELECT @NodeId, 'CPU1', CPU, DATEADD(minute, -id, sysdatetime()) as CreatedDate
    FROM RandomCPU
    OPTION(MAXRECURSION 0)
GO




CREATE OR ALTER PROCEDURE dbo.NodeCPU_GetDetailByNode
   @NodeId INT,
   @from int,
   @to 	int
AS

   SELECT CreatedDate as time,
          CPU as value,
          Metric as metric
     FROM dbo.NodeCpu
    WHERE NodeId = @NodeId AND
          CreatedDate >= DATEADD(s, @from, '1970-01-01') AND CreatedDate <= DATEADD(s, @to, '1970-01-01')

UNION ALL

   SELECT DATEADD(hour, CAST(DATEPART(HOUR,CreatedDate) as int), CONVERT(varchar(16), CreatedDate,110)) as time, 
          AVG(CPU) as value,
          'BaseLine' as metric
     FROM dbo.NodeCpu
    WHERE NodeId = @NodeId AND
          CreatedDate >= DATEADD(s, @from, '1970-01-01') AND CreatedDate <= DATEADD(s, @to, '1970-01-01')
 GROUP BY CONVERT(varchar(16), CreatedDate,110), CAST(DATEPART(HOUR,CreatedDate) as int)
 ORDER BY CreatedDate ASC

 GO



 CREATE OR ALTER PROCEDURE dbo.NodeCPU_GetTrends
   @NodeId INT,
   @from int,
   @to 	int
AS
   SELECT DATEADD(hour, CAST(DATEPART(HOUR,CreatedDate) as int), CONVERT(varchar(16), CreatedDate,110)) as time, 
          AVG(CPU) as value,
          'Current View' as metric
     FROM dbo.NodeCpu
    WHERE NodeId = @NodeId AND
          CreatedDate >= DATEADD(s, @from, '1970-01-01') AND CreatedDate <= DATEADD(s, @to, '1970-01-01')
 GROUP BY CONVERT(varchar(16), CreatedDate,110), CAST(DATEPART(HOUR,CreatedDate) as int)

 UNION ALL

   SELECT DATEADD(DAY, 1,DATEADD(hour, CAST(DATEPART(HOUR,CreatedDate) as int), CONVERT(varchar(16), CreatedDate,110))) as time, 
          AVG(CPU) as value,
          'Minus 1 Day' as metric
     FROM dbo.NodeCpu
    WHERE NodeId = @NodeId AND
          CreatedDate >= DATEADD(s, @from, DATEADD(DAY,-1,'1970-01-01')) AND CreatedDate <= DATEADD(s, @to, DATEADD(DAY,-1,'1970-01-01'))
 GROUP BY CONVERT(varchar(16), CreatedDate,110), CAST(DATEPART(HOUR,CreatedDate) as int)

 UNION ALL

 SELECT DATEADD(DAY,2,DATEADD(hour, CAST(DATEPART(HOUR,CreatedDate) as int), CONVERT(varchar(16), CreatedDate,110))) as time, 
          AVG(CPU) as value,
          'Minus 2 Day' as metric
     FROM dbo.NodeCpu
    WHERE NodeId = @NodeId AND
          CreatedDate >= DATEADD(s, @from, DATEADD(DAY,-2,'1970-01-01')) AND CreatedDate <= DATEADD(s, @to, DATEADD(DAY,-2,'1970-01-01'))
 GROUP BY CONVERT(varchar(16), CreatedDate,110), CAST(DATEPART(HOUR,CreatedDate) as int)

 ORDER BY time ASC

 GO