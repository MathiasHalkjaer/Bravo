﻿using Dax.Metadata.Extractor;
using Dax.ViewModel;
using Dax.Vpax.Tools;
using Sqlbi.Bravo.Infrastructure.Security;
using Sqlbi.Bravo.Models;
using System;
using System.IO;
using System.Linq;

namespace Sqlbi.Bravo.Infrastructure.Helpers
{
    internal static class VpaxToolsHelper
    {
        public static Stream ExportVpax(string connectionString, string databaseName, bool includeTomModel, bool includeVpaModel, bool readStatisticsFromData, int sampleRows)
        {
            var serverName = connectionString;

            var daxModel = TomExtractor.GetDaxModel(serverName, databaseName, AppConstants.ApplicationName, AppConstants.ApplicationFileVersion, readStatisticsFromData, sampleRows);
            var tomModel = includeTomModel ? TomExtractor.GetDatabase(serverName, databaseName) : null;
            var vpaModel = includeVpaModel ? new Dax.ViewVpaExport.Model(daxModel) : null;
            var stream = new MemoryStream();

            VpaxTools.ExportVpax(stream, daxModel, vpaModel, tomModel);

            return stream;
        }

        public static TabularDatabase GetDatabaseFromVpax(Stream vpax)
        {
            var vpaxContent = VpaxTools.ImportVpax(stream: vpax);
            var vpaModel = new VpaModel(vpaxContent.DaxModel);

            var databaseETag = TabularModelHelper.GetDatabaseETag(vpaModel.Model.Version, vpaModel.Model.LastUpdate);
            var databaseSize = vpaModel.Columns.Sum((c) => c.TotalSize);

            var databaseModel = new TabularDatabase
            {
                Info = new TabularDatabaseInfo
                {
                    ETag = databaseETag,
                    TablesCount = vpaModel.Tables.Count(),
                    ColumnsCount = vpaModel.Columns.Count(),
                    TablesMaxRowsCount = vpaModel.Tables.Max((t) => t.RowsCount),
                    DatabaseSize = databaseSize,
                    ColumnsUnreferencedCount = vpaModel.Columns.Count((t) => t.IsReferenced == false),
                    Columns = vpaModel.Columns.Select((c) =>
                    {
                        var column = new TabularColumn
                        {
                            Name = c.ColumnName,
                            TableName = c.Table.TableName,
                            Cardinality = c.ColumnCardinality,
                            Size = c.TotalSize,
                            Weight = (double)c.TotalSize / databaseSize,
                            IsReferenced = c.IsReferenced,
                        };
                        return column;
                    })
                },
                Measures = vpaxContent.DaxModel.Tables.SelectMany((t) => t.Measures).Select((m) =>
                {
                    var measure = new TabularMeasure
                    {
                        ETag = databaseETag,
                        Name = m.MeasureName.Name,
                        TableName = m.Table.TableName.Name,
                        Expression = m.MeasureExpression.Expression
                    };
                    return measure;
                })
            };

            return databaseModel;
        }
    }
}