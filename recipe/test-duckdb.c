#include <stdint.h>

#include "duckdb.h"

int main(void) {
    duckdb_database database;
    duckdb_connection connection;
    duckdb_result result;

    if (duckdb_open(NULL, &database) != DuckDBSuccess) {
        return 1;
    }
    if (duckdb_connect(database, &connection) != DuckDBSuccess) {
        duckdb_close(&database);
        return 2;
    }
    if (duckdb_query(connection, "select 42", &result) != DuckDBSuccess) {
        duckdb_disconnect(&connection);
        duckdb_close(&database);
        return 3;
    }

    const int64_t value = duckdb_value_int64(&result, 0, 0);
    duckdb_destroy_result(&result);
    duckdb_disconnect(&connection);
    duckdb_close(&database);
    return value == 42 ? 0 : 4;
}
