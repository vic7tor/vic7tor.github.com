---
layout: post
title: "git server"
description: ""
category: git 
tags: [git]
---
{% include JB/setup %}
#ssh
##访问
使用git init --bare xxx.git来创建一个仓库。
user@server:path/to/repo
path/to/repo可以使用user的home相对路径或者根目录开始的绝对路径，只要你有权限。
git@localhost:test.git /home/git/test.git
git@localhost:/opt/git/test.git /opt/git/test.git
git帐户对这些地方要有相应的访问权限。
##安全
我建了一个名为git的帐户，如果把它的shell指向/usr/bin/git-shell。那么，这个帐户不能执行shell命令，只能用来一些git操作。
当前版本的git可以在帐号的主目录下创建一个git-shell-commands的目录，这个目录下可以放能让git-shell执行的命令，可以为shell script。
由于git帐户设置了git-shell为shell，要创建新的仓库，只能使用别的帐户来操作。在我机子上面，git帐户与我的常用帐户在一个组中。使用git init创建的仓库是属于我这个常用帐户的。chown git:git xxx.git或者chmod -R g+w xxx.git会给git帐号拥有对这个仓库的写权限。或者在创建仓库前umask 001。
#gitweb

#gitosis

