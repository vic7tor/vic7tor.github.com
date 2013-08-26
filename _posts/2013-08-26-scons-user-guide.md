---
layout: post
title: "scons user guide"
description: ""
category: 
tags: []
---
{% include JB/setup %}
本文来自SCon User Guide，官方文档，不错的。

#简单的构建
在SConstruct文件中放入下面的就可以编译不的源文件：

    Program('hello.c') 编译出可执行程序
    Object('hello.c') 编译出目标文件
    Java('classes', 'src') 编译出java类

scon 编译
scon -Q quiet输出
scon -c 清除

Program、Object这玩意叫Builder

##SCons Function Are Order-Independent


       print "Calling Program('hello.c')"
       Program('hello.c')
       print "Calling Program('goodbye.c')"
       Program('goodbye.c')
       print "Finished calling Program()"

SConstruct是python脚本，这段程序的运行程序是这样的，Program并不是编译，在后面的编译过程中，goodbye.c可能先于hello.c编译。这是scons为了摆脱python这样的顺序执行吧。Program仅仅是记录了hello.c这样的文件，后面scons的编译过程才进行真正的编译。可以说Program是配置加载过程，scons运行到的后面还有一个编译过程。

##指定输出的名字

    Program('new_hello', 'hello.c')

##指向多个源文件

    Program('program', ['prog.c', 'file1.c', 'file2.c'])

使用Glob

    Program('program', Glob('*.c'))

##指定参数名


       src_files = Split('main.c file1.c file2.c')
       Program(target = 'program', source = src_files)


       src_files = Split('main.c file1.c file2.c')
       Program(source = src_files, target = 'program')

#创建、链接库
这个库是静态库。

    Library('foo', ['f1.c', 'f2.c', 'f3.c'])

    StaticLibrary('foo', ['f1.c', 'f2.c', 'f3.c'])
    SharedLibrary('foo', ['f1.c', 'f2.c', 'f3.c'])

Library与StaticLibrary一样的，只是在名字上用来指示是个静态库。

链接库：

      Library('foo', ['f1.c', 'f2.c', 'f3.c'])
      Program('prog.c', LIBS=['foo', 'bar'], LIBPATH='.')

LIBPATH用来指向库的搜索路径，当然可以指定一些别的路径。

#Node Objects

    Object('hello.c', CCFLAGS='-DHELLO')
    Object('goodbye.c', CCFLAGS='-DGOODBYE')
    Program(['hello.o', 'goodbye.o'])

#依赖
一个编译例子：

     % scons -Q hello
     cc -o hello.o -c hello.c
     cc -o hello hello.o
     % scons -Q hello
     scons: `hello is up to date.


##判断一个文件是否变化
MD5:

        Program('hello.c')
        Decider('MD5')

Time Stamps:

        Object('hello.c')
        Decider('timestamp-newer')

Decider的参数还有很多种，略了。

还可以自定义Decider

##隐式依赖：$CPPPATH构建变量

    Program('hello.c', CPPPATH = '.')

对于hello.c包含的头文件变化，scons会重新编译这个程序。

The $CPPPATH value tells SCons to look in the current directory ('.') for any files included by C source files (.c or .h files).

CAPPPATH会在调用gcc时加上-I CPPPATH指向的路径，来添加头文件的搜索路径。

##Caching Implicit Dependencies
在构建大的系统是这么做

##显示依赖：Depends函数
指示一个文件依赖另外的文件，这些文件变化时重新构建一个目标。

       hello = Program('hello.c')
       Depends(hello, 'other_file')
    

       % scons -Q hello
       cc -c hello.c -o hello.o
       cc -o hello hello.o
       % scons -Q hello
       scons: `hello is up to date.
       % edit other_file
           [CHANGE THE CONTENTS OF other_file]
       % scons -Q hello
       cc -c hello.c -o hello.o
       cc -o hello hello.o

##依赖外部文件：ParseDepends函数

      obj = Object('hello.c', CCFLAGS='-MD -MF hello.d', CPPPATH='.')
      SideEffect('hello.d', obj)
      ParseDepends('hello.d')
      Program('hello', obj)

##忽略依赖：Ignore函数

      hello_obj=Object('hello.c')
      hello = Program(hello_obj)
      Ignore(hello_obj, 'hello.h')

## Order-Only Dependencies: the Requires Function

 One solution is to use the Requires function to specify that the version.o must be rebuilt before it is used by the link step, but that changes to version.o should not actually cause the hello executable to be re-linked:

##AlwaysBuild

      hello = Program('hello.c')
      AlwaysBuild(hello)

#Environments
有三种环境变量：

    1.Externel：用户运行scons系统中的环境变量
    2.Construction: SConscript创建的环境变量
    3.Executeion:执行另外程序时用的环境变量，比方说执行GCC这些东东的时候。

2，3都用Environment构建，他们区别是，使用的函数不同。2的变量名是一般标识符(应该是构造函数的参数)，3的变量名是一个字符串。

##使用Externel

    import os
    os.environ

这是python的机制。

##Construction
使用Environment来创建Construction环境变量。

         env = Environment(CC = 'gcc', CCFLAGS = '-O2')
         env.Program('foo.c')

从Construction获得变量值：

         env = Environment()
         print "CC is:", env['CC']

字典方式访问：

         env = Environment(FOO = 'foo', BAR = 'bar')
         dict = env.Dictionary()
         for key in ['OBJSUFFIX', 'LIBSUFFIX', 'PROGSUFFIX']:
             print "key = %s, value = %s" % (key, dict[key])

展开环境变量的值：

        env = Environment()
        print "CC is:", env.subst('$CC')

env['CC']这样的访问方式可能是没有展开的shell变量那样的。

复制Construction：

         env = Environment(CC = 'gcc')
         opt = env.Clone(CCFLAGS = '-O2')
         dbg = env.Clone(CCFLAGS = '-g')

         env.Program('foo', 'foo.c')

         o = opt.Object('foo-opt', 'foo.c')
         opt.Program(o)

         d = dbg.Object('foo-dbg', 'foo.c')
         dbg.Program(d)

替换值：

         env = Environment(CCFLAGS = '-DDEFINE1')
         env.Replace(CCFLAGS = '-DDEFINE2')
         env.Program('foo.c')

设置值仅当变量没有定义：

         env.SetDefault(SPECIAL_FLAG = '-extra-option')

在变量尾部附加值：

         env.Append(CCFLAGS = ['-DLAST'])

仅当变量不存在时附加值：

         env.AppendUnique(CCFLAGS=['-g'])

在变量头部附加值：

         env.Prepend(CCFLAGS = ['-DFIRST'])

还有个PrependUnique

##控制Execution
这个也是用Environment来创建，但是这些函数都是大写，变量名都用引号引起来了。

        env = Environment(ENV = os.environ)
        env.PrependENVPath('PATH', '/usr/local/bin')
        env.AppendENVPath('LIB', '/usr/local/lib')

#Construction相关的了些函数


 This chapter describes the MergeFlags, ParseFlags, and ParseConfig methods of a construction environment.

略了。

#控制build输出
##提供build帮助

    Help("""
       Type: 'scons program' to build the production program,
             'scons debug' to build the debug version.
       """)

scons -h就可以显示出来了

scons -H是scons的帮助

##控制SCons打印构建的命令

       env = Environment(CCCOMSTR = "Compiling $TARGET",
                         LINKCOMSTR = "Linking $TARGET")
       env.Program('foo.c')

##提供进度输出Progress
与上一个打印的位置不一样

        Progress('Evaluating $TARGET\n')
        Program('f1.c')
        Program('f2.c')

##GetBuildFailures

#从命令行控制编译
三种元素：Options、Variables、Targets

##命令行选项
SCONSFLAGS环境变量。

GetOption:

        if not GetOption('help'):
            SConscript('src/SConscript', export='env')

还可以用SetOption在SConscript里面设置。

有一个表的Strings for Getting or Setting Values of SCons Command-Line Options，比方说上面用的help，都需要在这个表里查。

##自定义命令行


        AddOption('--prefix',
                  dest='prefix',
                  type='string',
                  nargs=1,
                  action='store',
                  metavar='DIR',
                  help='installation prefix')

        env = Environment(PREFIX = GetOption('prefix'))

        installed_foo = env.Install('$PREFIX/usr/bin', 'foo.in')
        Default(installed_foo)

保存在dest然后，GetOption这个dest就行了。

##variable=value

    % scons -Q debug=1

    
       env = Environment()
       debug = ARGUMENTS.get('debug', 0)
       if int(debug):
           env.Append(CCFLAGS = '-g')
       env.Program('prog.c')


另一种方法：SCons provides an ARGLIST variable that gives you direct access to variable=value settings on the command line

这个还可以用Variables来实现：


           vars = Variables(None, ARGUMENTS)
           vars.Add('RELEASE', 'Set to 1 to build for release', 0)
           env = Environment(variables = vars,
                             CPPDEFINES={'RELEASE_BUILD' : '${RELEASE}'})
           env.Program(['foo.c', 'bar.c'])

还可以从一个python脚本获得变量。

vars.Add还可以添加BoolVariable构造的变量：


             vars = Variables('custom.py')
             vars.Add(BoolVariable('RELEASE', 'Set to build for release', 0))
             env = Environment(variables = vars,
                               CPPDEFINES={'RELEASE_BUILD' : '${RELEASE}'})
             env.Program('foo.c')

EnumVariable枚举型：

             vars = Variables('custom.py')
             vars.Add(EnumVariable('COLOR', 'Set background color', 'red',
                                 allowed_values=('red', 'green', 'blue')))
             env = Environment(variables = vars,
                               CPPDEFINES={'COLOR' : '"${COLOR}"'})
             env.Program('foo.c')

ListVariable:

    scons -Q COLORS=red,blue foo.o

PathVariable:

##命令行目标

COMMAND_LINE_TARGETS指示了当前的target.

Default指定默认的目标：

         env = Environment()
         hello = env.Program('hello.c')
         env.Program('goodbye.c')
         Default(hello)

调用多次Default，就是有多个默认目标。

DEFAULT_TARGETS显示了默认的目标。

BUILD_TARGETS指示了

#Install Builder
在另一个目录安装文件的东东。


     env = Environment()
     hello = env.Program('hello.c')
     env.Install('/usr/bin', hello)

#Command Builder
Copy Delete Move Touch Mkdir Chmod Execute 等这些操作文件的操作

#层次化的构建
##Sconscript文件

使用SConscript函数来载入这些文件:


      SConscript(['drivers/display/SConscript',
                  'drivers/mouse/SConscript',
                  'parser/SConscript',
                  'utilities/SConscript'])

SConscript文件中指向的路径是相对于SConscript脚本的:


      env = Environment()
      env.Program('prog2', ['main.c', 'bar1.c', 'bar2.c'])

从顶层开始的路径可以在路径前加一个`#`:


       env = Environment()
       env.Program('prog', ['main.c', '#lib/foo1.c', 'foo2.c'])

也可以是从系统根目录开始的绝对路径

##共享环境变量
导出：

        env = Environment()
        Export('env')


        env = Environment()
        debug = ARGUMENTS['debug']
        Export('env', 'debug')

导入：

        Import('env')
        env.Program('prog', ['prog.c'])


        Import('env', 'debug')
        env = env.Clone(DEBUG = debug)
        env.Program('prog', ['prog.c'])

从SConscript返回值：


          Import('env')
          obj = env.Object('foo.c')
          Return('obj')


          env = Environment()
          Export('env')
          objs = []
          for subdir in ['foo', 'bar']:
              o = SConscript('%s/SConscript' % subdir)
              objs.append(o)
          env.Library('prog', objs)

#分开源代目录与构建目录

SConscript('src/SConscript', variant_dir='build')

不会把源码复制到build目录：


      SConscript('src/SConscript', variant_dir='build', duplicate=0)


#分开很多东西


    platform = ARGUMENTS.get('OS', Platform())

    include = "#export/$PLATFORM/include"
    lib = "#export/$PLATFORM/lib"
    bin = "#export/$PLATFORM/bin"

    env = Environment(PLATFORM = platform,
                      BINDIR = bin,
                      INCDIR = include,
                      LIBDIR = lib,
                      CPPPATH = [include],
                      LIBPATH = [lib],
                      LIBS = 'world')

    Export('env')

    env.SConscript('src/SConscript', variant_dir='build/$PLATFORM')
  
#自定义Builder


       bld = Builder(action = 'foobuild < $SOURCE > $TARGET')
       env = Environment(BUILDERS = {'Foo' : bld})

       env.Foo('file.foo', 'file.input')

处理特定后缀的文件：


       bld = Builder(action = 'foobuild < $SOURCE > $TARGET',
                     suffix = '.foo',
                     src_suffix = '.input')
       env = Environment(BUILDERS = {'Foo' : bld})
       env.Foo('file1')
       env.Foo('file2')
    

      % scons -Q
      foobuild < file1.input > file1.foo
      foobuild < file2.input > file2.foo

定义处理函数，上面的是执行shell命令：


       def build_function(target, source, env):
           # Code to build "target" from "source"
           return None
       bld = Builder(action = build_function,
                     suffix = '.foo',
                     src_suffix = '.input')
       env = Environment(BUILDERS = {'Foo' : bld})
       env.Foo('file')

修改target或者soruce烈表的：


       def modify_targets(target, source, env):
           target.append('new_target')
           source.append('new_source')
           return target, source
       bld = Builder(action = 'foobuild $TARGETS - $SOURCES',
                     suffix = '.foo',
                     src_suffix = '.input',
                     emitter = modify_targets)
       env = Environment(BUILDERS = {'Foo' : bld})
       env.Foo('file')

#伪Builders


     def install_in_bin_dirs(env, source):
         """Install source in both bin dirs"""
         i1 = env.Install("$BIN", source)
         i2 = env.Install("$LOCALBIN", source)
         return [i1[0], i2[0]] # Return a list, like a normal builder
     env = Environment(BIN='/usr/bin', LOCALBIN='#install/bin')
     env.AddMethod(install_in_bin_dirs, "InstallInBinDirs")
     env.InstallInBinDirs(Program('hello.c')) # installs hello in both bin dirs 

使用AddMethod就可以在env那建一个方法了

#自定义扫描器

Scanner影响env的$SOURCES变量

