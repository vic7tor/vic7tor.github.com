git://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git

这个没有什么文档，最好的文档就是那几个程序，不过也要先从insmod->modprob->depmod这样的顺序来看。

函数上方有文档。

#1.insmod
##1.kmod_new
KMOD_EXPORT struct kmod_ctx *kmod_new(const char *dirname,
                                        const char * const *config_paths)

第一个参数是指向模块根目录，下面有modules.dep这样的文件。

第二个参数是配置文件，放etc那些。

##2.kmod_module_new_from_path
这个函数从一个指向模块的相对或绝对路径。

##3.kmod_module_insert_module
加载模块啦。

#2.modprobe
modprobe会显示依赖，依赖是这样的，一个模块加载的模块依赖了别的模块的话，这个模块也会加进去，在modules.dep里列出的所有模块已经满足这个条件。

以前出现过的函数就不列了。

##1.kmod_load_resources
打开这些文件：

} index_files[] = {
        [KMOD_INDEX_MODULES_DEP] = { .fn = "modules.dep", .prefix = "" },
        [KMOD_INDEX_MODULES_ALIAS] = { .fn = "modules.alias", .prefix = "alias " },
        [KMOD_INDEX_MODULES_SYMBOL] = { .fn = "modules.symbols", .prefix = "alias "},
        [KMOD_INDEX_MODULES_BUILTIN] = { .fn = "modules.builtin", .prefix = ""},
};

##2.insmod
###1.kmod_module_new_from_lookup
KMOD_EXPORT int kmod_module_new_from_lookup(struct kmod_ctx *ctx,
                                                const char *given_alias,
                                                struct kmod_list **list)

given_alias模块名字。不知道是不是要kmod_new时指定路径。

kmod_list_foreach

kmod_module_get_module

###2.kmod_module_probe_insert_module
这玩意会调用__kmod_module_get_probe_list会计算出这个模块的依赖，最后是一个列表，有模块插入的顺序。

modprobe -D显示的那个列表。

#depmod
struct depmod重要的结构体，上面挂着symbol这些。

##1.depfile_up_to_date
检测数据库有没有过时。

##depmod_load_symvers depmod_load_system_map

##2.depmod_modules_search_dir
查找目录下所有的模块，把它们加到depmod上面。


static int depmod_modules_search_dir(struct depmod *depmod, DIR *d, size_t baselen, char *path)

##3.depmod_modules_build_array depmod_modules_sort
一些预处理

##4.depmod_load
计算依赖。


##5.depmod_output

#所有模块的列表
depmod_module_add:

err = hash_add_unique(depmod->modules_by_name, mod->modname, mod);

