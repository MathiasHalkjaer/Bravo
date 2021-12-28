/*!
 * Bravo for Power BI
 * Copyright (c) SQLBI corp. - All rights reserved.
 * https://www.sqlbi.com
*/

export interface TabularDatabase {
    model: TabularDatabaseInfo
    measures: TabularMeasure[]
}

export interface TabularDatabaseInfo {
    etag?:	string
    tablesCount: number
    columnsCount: number
    maxRows: number
    size: number
    unreferencedCount: number
    columns: TabularColumn[]
}
export interface TabularColumn {
    columnName?: string
    tableName?: string
    columnCardinality: number
    size: number
    weight: number
    isReferenced?: boolean
}

export interface TabularMeasure {
    etag?:	string
    name?:	string
    tableName?:	string
    measure?:	string
}