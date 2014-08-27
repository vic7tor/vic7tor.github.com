#1.ZIP包
##1.update-binary
install.c - try_update_binary调用这个程序

###try_update_binary
运行的update-binary与recovery是用一个pipe通信的，在updater中是这样打开的：

    // Set up the pipe for sending commands back to the parent process.

    int fd = atoi(argv[2]);
    FILE* cmd_pipe = fdopen(fd, "wb");
    setlinebuf(cmd_pipe);

##2.updater-script

##3.证书

#2.edify
lexer.l 这个定义edify的词。

parser.y里有词的语法关系。

1.逻辑语法：

|  expr AND expr                     { $$ = Build(LogicalAndFn, @$, 2, $1, $3); }
|  expr OR expr                      { $$ = Build(LogicalOrFn, @$, 2, $1, $3); }
|  '!' expr                          { $$ = Build(LogicalNotFn, @$, 1, $2); 

2.命令处理

| STRING '(' arglist ')' {
    $$ = malloc(sizeof(Expr));
    $$->fn = FindFunction($1);
    if ($$->fn == NULL) {
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "unknown function \"%s\"", $1);
        yyerror(root, error_count, buffer);
        YYERROR;
    }
    $$->name = $1;
    $$->argc = $3.argc;
    $$->argv = $3.argv;
    $$->start = @$.start;
    $$->end = @$.end;
}

FindFunction：

一个链表，由RegisterFunction注册。

grep一下RegisterFunction基本都是updater/install.c注册的。

所有命令都由RegisterFunction注册。

#recovery应用程序
recovery.c

main函数开头初始化了LOG文件，路径是/tmp/recovery.log，不过最后这个文件会由copy_logs这个函数拷贝到/cache/recovery/log。

prompt_and_wait这个函数是主要的事件循环。

##prompt_and_wait

const char* const* headers = prepend_title(device->GetMenuHeaders());

这个是显示在菜单上的文字。



##参数
--adbd只运行adb啊。。

不过可以有两个recovery进程。


#minui
所有函数数据结构都是在这个文件中定义的啦：minui/minui.h

gr_surface

##1.gr_init
应该是图形系统的全局初始化函数。调用了libpixelflinger的gglInit。

这个函数由ScreenRecoveryUI::Init调用。

##2.res_create_surface
从png文件初始化一个gr_surface。

##3.res_create_localized_surface


#ScreenRecoveryUI
##Init
gr_init

LoadBitmap->res_create_surface初始化了几个gr_surface

##draw_screen_locked
recovery的界面由这个函数绘制完成。研究一下它对理解minui十分有帮助。

##draw_progress_locked
progress bar是这样画的，一张empty的图片，一张full的图片，有百分之多少就画，full多少的图，再画empty 1-百分之多少的图。两张图拼成一个progress bar。


#zip包的生成
make otapackage

脚本：build/tools/releasetools/

##recovery升级包
见ota_from_target_files

WriteFullOTAPackage这个函数很有意思，edify脚本怎么用这里面也有。


#recovery测试
adb shell stop停止android框架，然后运行recovery这个进程就行了。

res图片资源是放在根目录的。

#二进制差分
recovery目录下的applypatch这个文件。

#recovery编译
build/core/Makefile　INSTALLED_RECOVERYIMAGE_TARGET指向的

recovery.img是一个带内核的，类似boot.img的东西。

INTERNAL_RECOVERYIMAGE_ARGS：

 674 INTERNAL_RECOVERYIMAGE_ARGS := \
 675         $(addprefix --second ,$(INSTALLED_2NDBOOTLOADER_TARGET)) \
 676         --kernel $(recovery_kernel) \
 677         --ramdisk $(recovery_ramdisk)

recovery.img生成：

 743         $(hide) $(MKBOOTIMG) $(INTERNAL_RECOVERYIMAGE_ARGS) $(BOARD_MKBOOTI     MG_ARGS) --output $@

#init.rc
/system/core/init/keywords.h

这里有init的所有命令，exec可以用来运行程序。

