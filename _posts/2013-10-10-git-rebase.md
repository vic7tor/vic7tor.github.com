---
layout: post
title: "git rebase"
description: ""
category: 
tags: []
---
{% include JB/setup %}
本文来自git rebase --help。

#1.概述

基本例子：

       git rebase [-i | --interactive] [options] [--onto <newbase>]
               [<upstream>] [<branch>]


upstream：指向当前分支(如果不在这个分支上可以用branch指定)创建时的父分支。

branch：如上面所述。

onto：默认是当前分支rebase之后的父分支还是upstream，如果要让其父亲为别的，用onto指出。

说到这里，再结合后面会讲的例子。rebase适用的情况是：

假设upstream relase了1.0版，我们针对upstream进行定制开发新建一个topic分支。当upstream relase 2.0的版本时。我们要把新代码合进来，怎么办呢？第一个选择可以merge，然后还有一个选择就是rebase。rebase可以把topic分支创建时指向的1.0改变为指2.0。这就是rebase的含义，变基，改变这个分支创建时的base。

这是rebase的一般用途。

这就是为什么基于master创建一个新的分支，然后在这个分支上进行开发，然后：git rebase new_branch master，这样就出现了fast forward这样的提示。

##1.upstream里rebase
上面描述的是在topic分支中rebase的情况

可不可以在upstream分支里rebase?似乎是行得通的，不要管谁是父亲，把两个分支看成是一个倒立的二叉树。创建一个新分支后，从那个点开支，两个分支都是那个点产生的儿子。

##2.冲突

    git rebase --continue | --skip | --abort

#2.几个用法
##1.基本用法
git rebase master
git rebase master topic

执行前：

                     A---B---C topic
                    /
               D---E---F---G master
执行后：

                         A'--B'--C' topic
                        /
           D---E---F---G master

有一个'的原因是重新提交，新的提交ID?

如果A已经在master分支里面，rebase时会忽略掉。

                     A---B---C topic
                    /
               D---E---A'---F master

                              B'---C' topic
                             /
               D---E---A'---F master


##2.使用onto的情况
git rebase --onto master next topic

执行前：

               o---o---o---o---o  master
                    \
                     o---o---o---o---o  next
                                      \
                                       o---o---o  topic
执行后：

               o---o---o---o---o  master
                   |            \
                   |             o'--o'--o'  topic
                    \
                     o---o---o---o---o  next

##3.删除提交
git rebase --onto topicA~5 topicA~3 topicA

执行前：

    E---F---G---H---I---J  topicA

执行后：

    E---H'---I'---J'  topicA

#3.多个提交如何放到upstream
在1.1中的考虑－在upstream中rebase。实践证明是可行的。

在特性分支开发后，想要release的话，可以这么做。

#4.实践

1. git clone git://192.168.9.222/projects/gitrebase.git

2. cd gitrebase

3. git branch topic origin/topic
这一步创建topic分支

4. 现在开始rebase了，先gitk --all看一下分支图。

            D topic
           /
    A--B--C
           \
            E master

可以说是现在这个形状。现在这个情况可以描述为，在C时，从master创建了topic分支，然后先在topic分支开发了D，然后，在master上又开发了E。

1)先把topic上所做的开发放到master上：

    git rebase topic master

有冲突，先解决下。编辑好后：

    git add .
    git rebase --continue

gitk -all看一下分支图，是这样的(remotes/origin/topic不用管)：


    A--B--C--D  topic
              \
               E  master

这样是不是把topic上开发的D放到了master分支上。

2)把master上的开发放到topic上
先还原master分支：

    git reflog
    git checkout master
    git reset --hard 1ad379e

gitk --all确认下

然后进行变基：

    git rebase master topic

其它的就不描述了。

5.总结
git rebase的作用：

    1)方便跟踪upstream分支
    2)release时，从开发分支把提交拿过来，不使用merge，干净好看

