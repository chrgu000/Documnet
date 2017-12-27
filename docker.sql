
-- docker sit 数据库中需要修改的.nginx 监听的端口是81 tomcat 端口是8180 --> 8080

UPDATE st_param SET PARAM_VALUE=REPLACE(PARAM_VALUE,'https://sit.ibdp2p.com','http://192.168.1.206:81');
UPDATE st_param SET PARAM_VALUE=REPLACE(PARAM_VALUE,'http://10.46.120.2:8080','http://192.168.1.206:8180');
update st_param set PARAM_VALUE = '81' where PKID = 'http_port';



/* 还需要改portal的配置文件
sed -i 's/http.port=80/http.port=81/' \
/opt/sdp/ibdp2p/apache-tomcat-7.0.65/webapps/portal/WEB-INF/classes/system.properties
*/
-- docker sit1 数据库中需要修改的 nginx监听的端口是82 tomcat 端口 8181 --> 8081

UPDATE st_param SET PARAM_VALUE=REPLACE(PARAM_VALUE,'https://sit.ibdp2p.com','http://192.168.1.206:82');
UPDATE st_param SET PARAM_VALUE=REPLACE(PARAM_VALUE,'http://10.46.120.2:8080','http://192.168.1.206:8181');
update st_param set PARAM_VALUE = '82' where PKID = 'http_port';

/* 还需要改portal的配置文件
sed -i 's/http.port=80/http.port=82/' \
/opt/sdp/ibdp2p/apache-tomcat-7.0.65/webapps/portal/WEB-INF/classes/system.properties
*/

-- docker sit2 数据库中需要修改的 nginx监听的端口是83  tomcat 端口 8182 --> 8082

UPDATE st_param SET PARAM_VALUE=REPLACE(PARAM_VALUE,'https://sit.ibdp2p.com','http://192.168.1.206:83');
UPDATE st_param SET PARAM_VALUE=REPLACE(PARAM_VALUE,'http://10.46.120.2:8080','http://192.168.1.206:8182');
update st_param set PARAM_VALUE = '83' where PKID = 'http_port';

/* 还需要改portal的配置文件
sed -i 's/http.port=80/http.port=83/' \
/opt/sdp/ibdp2p/apache-tomcat-7.0.65/webapps/portal/WEB-INF/classes/system.properties
*/