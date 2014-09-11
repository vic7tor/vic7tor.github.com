这篇文章讲解selinux的reference policy language。还有一个叫CLI的，这个目前没有普及。

这篇文章是对SELinux By Example的总结。

domain type特指是process type

#1.Object Classes
这些Object Classes是内核提供的。详细的见SELinux的官网上的ObjectClassesPerms。

#2.Type Enforcement
##1.Types, Attributes, Aliases
type 就是SELinux Context第三个成员。

attributes代表一组type。

aliases就是别名了。

type、typeattribute语句。

##2.Access Vector Rules
一共有4条：

rule_name:allow、dontallow、auditallow、neverallow

AV规则的语法：

rule_name type_set type_set : class_set perm_set

多个相同的用{}括起来。

第一个type_set，是进程SELinux Context中的type，SELinux的所有规则中，都是描述进程对有第二个type_set的class_set有何种权限。

规则中第一个type_set是指有这种type_set的进程，第二个type_set，是指有这种类型的对象。

##3.Type Rules
这个用指定对象创建或relabel时的默认type。

###1.Type Transition Rules
####1.Default Domain Transitions

type_transition init_t apache_exec_t : process apache_t

一个有init_t的进程运行一个apache_exec_t类型的文件时，新进程的type变为apache_t。

当然还需要别的规则，比init_t能访问apache_exec_t的execute和entrypoint。
init_t能转换到apache_t。

####2.Default Object Transitions

type_transition passwd_t tmp_t : file passwd_tmp_t

一个passwd_t类型的进程在tmp_t类型的目录创建文件时，新文件的类型是passwd_tmp_t。

###2.Type Change Rules

type_change sysadm_t tty_device_t : chr_file sysadm_tty_device_t

#3.Roles and Users
在type Enforcement中，allow，什么的都是根据类型来的。这个类型是SELinux Context的第三个成员，类型。

而这个SELinux Context能否创建，则受role和user来控制。

Roles和users

#4.Constrain
##1.
constrain class_set perm_set expression

expression的构成

t1,r1,u1 1代表source，t,r,u代表type,role,user

t2,r2,u2 2代表target

source、target可以是常量。如果是变量，是在那些像transition这种上面。

source与target的关系运算：
==、!=、

eq、dom。。。

constrain process transition (u1 == u2)

##2.
validatetrans class_set expression

#5.mls
mls是SELinux Context第4个成员。

根据这个来做一些constrain...


