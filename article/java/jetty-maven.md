#1.maven创建web项目
在maven的文档上有一篇文章： Guide to Webapps

里面提到的命令：mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-webapp -DarchetypeArtifactId=maven-archetype-webapp

#2.jetty
要在<build>的<plugins>加入：

<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.2.2.v20140723</version>
</plugin>

用第一步生成的是没有plugins的，自己在build下加一个。

还有version，9.2.2-SNAPSHOT是没有的，搜jetty-maven-plugin，在http://repo.maven.apache.org/maven2/org/eclipse/jetty/jetty-maven-plugin/就是可能的版本了。

不过还有一个方法：

mvn -Dplugin=<groupId>:<artifactId> help:describe

会有最新的版本。

对于配置文件，看这个地方的也行：

http://www.eclipse.org/jetty/documentation/current/maven-and-jetty.html#developing-standard-webapp-with-jetty-and-maven

这篇文章讲了plugin放的位置。

#plugin goal
在运行mvn -Dplugin=org.eclipse.jetty:jetty-maven-plugin help:describe时会出现一句：

Version: 9.2.2.v20140723
Goal Prefix: jetty

Goal Prefix

查查Goal Prefix这个玩意哪来的吧。

#jetty-maven-plugin的配置

属性下面有例子的，可能要等久点才能显示出来。

http://www.eclipse.org/jetty/documentation/9.2.2.v20140723/jetty-maven-plugin.html
