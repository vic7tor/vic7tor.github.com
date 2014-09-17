tomcat也可以多实例，就由CATALINA_BASE这个环境变量来控制啦，启动服务是由startup.sh。

如果是用daemon.sh这个脚本，可以用--catalina-base来指定。

CATALINA_BASE需要下面的目录结构：

bin  conf  lib  logs  temp  webapps  work

#配置文件
##conf/server.xml

