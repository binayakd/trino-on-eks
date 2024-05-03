<configuration>
    <property>
        <name>hive.metastore.uris</name>
        <value>${HIVE_METASTORE_URIS}</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>${HIVE_DB_JDBC_URL}</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>${HIVE_DB_DRIVER}</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>${HIVE_DB_USER}</value>
    </property>
    <property>
        <name> javax.jdo.option.ConnectionPassword</name>
        <value>${HIVE_DB_PASS}</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>${HIVE_WAREHOUSE_DIR}</value>
    </property>
    <property>
        <name>metastore.expression.proxy</name>
        <value>org.apache.hadoop.hive.metastore.DefaultPartitionExpressionProxy</value>
    </property>
    <property>
        <name>metastore.task.threads.always</name>
        <value>org.apache.hadoop.hive.metastore.events.EventCleanerTask,org.apache.hadoop.hive.metastore.MaterializationsCacheCleanerTask</value>
    </property>
</configuration>