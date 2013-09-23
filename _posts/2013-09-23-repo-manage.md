repo init -u git://codeaurora.org/platform/manifest.git --mirror --repo-url=git://codeaurora.org/tools/repo.git

初始化：
repo init -u git://192.168.9.222/android/platform/manifest.git --repo-url=git://192.168.9.222/android/tools/repo.git -b []

切换分支：（切换这么做还是不行，看manifests的.git/config 如果default分支的merge与远端的不一样，就不能repo sync
victor@victor-OptiPlex-3010:~/flyaudio/8x26$ repo init -b test
From git://192.168.9.222/android/platform/manifest
 * [new branch]      test       -> origin/test

Your Name  [Victor Wen]: 
Your Email [victor@flyaudio.cn]: 

Your identity is: Victor Wen <victor@flyaudio.cn>
is this correct [y/n]? y

repo initialized in /home/victor/flyaudio/8x26

manifest管理
 <remote fetch="git://192.168.9.222/android/" push="git@192.168.9.222:android/" name="flyaudio" review="codeaurora.org"/>
  <default remote="flyaudio" revision="ics_strawberry_rb5.3"/>

<project groups="default" name="platform/vendor/qcom/proprietary_8x26-1.5" path="vendor/qcom/proprietary" revision="master"/>


8x26:

amss1.0:repo init -u git://192.168.9.222/android/platform/manifest.git -b release -m LNX.LA.3.2-00520-8x26.xml --repo-url=git://192.168.9.222/android/tools/repo.git
amss1.5:repo init -u git://192.168.9.222/android/platform/manifest.git -b release -m M8626AAAAANLYA0070029.xml --repo-url=git://192.168.9.222/android/tools/repo.git


flyaudio-test:
repo init -u git://192.168.9.222/android/platform/manifest.git -b flyaudio-test --repo-url=git://192.168.9.222/android/tools/repo.git

8x26-test:
repo init -u git://192.168.9.222/android/platform/manifest.git -b 8x26-test -m 8x26.xml --repo-url=git://192.168.9.222/android/tools/repo.git


高通说的如何选择：
Dear customer 

Go to https://www.codeaurora.org/xwiki/bin/QAEP/release to get the manifest file based on the Build ID which could be got from the about.xml under the root directory after download the release from Chipcode. 

eg: 
# repo init -u git://codeaurora.org/platform/manifest.git -b release -m LNX.LA.3.2-00520-8x26.xml --repo-url=git://codeaurora.org/tools/repo.git 
# repo sync 

Thanks!

报不跟上游：
是因为，要有<default remote="flyaudio" revision="jb_3.2_rb2.6"/>指向的分支，要处于jb_3.2_rb2.6上。


