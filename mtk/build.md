
mk脚本使用：

显示project
./mk listp

banyan_addon_x86
flyaud82_we_kk

编译:
./mk flyaud82_we_kk new

#gcc无法识别的原因
mediatek/build/tools/checkEnv.py

pattern = re.compile(".*gcc\s*version\s*([\d\.]+)",re.S)
中文输出就无法识别了。。。

把LANG设为..
改LANG没有用，要改LANGUAGE:

export LANGUAGE=en_US:en
