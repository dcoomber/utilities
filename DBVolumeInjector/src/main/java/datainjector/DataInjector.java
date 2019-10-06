package datainjector;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import java.text.SimpleDateFormat;
import java.util.*;

public class DataInjector {

    private static final String USERNAME = "the_user";
    private static final String PASSWORD = "the_password";
    private static final String URL = "jdbc:postgresql://the_url:5432/db_name?useSSL=false";
    private static final String DRIVER = "org.postgresql.Driver";
    private static final String SCHEMA = "public";
    private static final String TABLE = "table_name";
    private static final String FIELD_LIST = "field1, field2, field3, field4, field5";
    private static final String[] VALUE_LIST = {"ACCEPT", "REJECT", "REFERRAL"};
    private static final String INSERT_TEMPLATE = "insert into %s.%s (%s) values %s";
    private static final String INSERT_VALUES_TEMPLATE = "('%s','%s','%s','%s','%s')";

    public static void main (String[] args) {

        // Shared objects & variables
        int batchSize = 10000;
        Scanner scanner = new Scanner(System.in);
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

        // Setup database connection
        final JdbcTemplate jdbc;
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName(DRIVER);
        dataSource.setUrl(URL);
        dataSource.setUsername(USERNAME);
        dataSource.setPassword(PASSWORD);
        jdbc = new JdbcTemplate(dataSource);

        // Allow user to specify number of records to generate
        System.out.print("How many data records would you like to generate?: ");
        int numRecords = scanner.nextInt();
        int remainder = numRecords;

        // Setup SQL statement and execute to insert data
        long begin = System.currentTimeMillis();

        while (remainder > 0) {
            int thisBatch = Math.min(remainder, batchSize);
            remainder = remainder - thisBatch;

            long batchBegin = System.currentTimeMillis();

            StringBuilder sqlValues = new StringBuilder();
            for (int i = 0; i < thisBatch; i++) {
                UUID uniqueIdentifier = UUID.randomUUID();
                String timestamp = formatter.format(new Date());

                // Compile values list
                if (i != 0)
                    sqlValues.append(",");

                sqlValues.append(String.format(INSERT_VALUES_TEMPLATE, uniqueIdentifier.toString(), VALUE_LIST[i % VALUE_LIST.length], timestamp, timestamp, timestamp));
            }

            // DEBUG
            //System.out.println(sqlValues);

            // Execute the statement
            jdbc.execute(String.format(INSERT_TEMPLATE, SCHEMA, TABLE, FIELD_LIST, sqlValues));

            long batchEnd = System.currentTimeMillis();
            float batchElapsed = (batchEnd - batchBegin) / 1000F;
            System.out.println(String.format("Batch: Inserted %d records in %f seconds.", thisBatch, batchElapsed));
        }

        long end = System.currentTimeMillis();
        float elapsed = (end - begin) / 1000F;
        System.out.println(String.format("Overall: Inserted %d records in %f seconds.", numRecords, elapsed));
    }
}
