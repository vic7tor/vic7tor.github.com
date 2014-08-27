这篇文章来自:http://www.mediawiki.org/wiki/Gerrit/git-review
https://pypi.python.org/pypi/git-review

1.安装
sudo apt-get install python-pip
sudo easy_install pip
sudo pip install git-review

2. .gitreview文件
.gitreview文件的格式：

[gerrit]
host=review.openstack.org
port=29418
project=openstack-infra/git-review.git
defaultbranch=master

关于username的配置:
man git-review中有说有几个位置有效，参看git-review的原代码，只有使用:

git config gitreview.username victor

设置的才有用。

在git-review的源代码中搜索add_remote可以看到是如何配置

3.常用操作
git review -s 在git remote中生成叫gerrit的remote,可能因为网络问题等比较久。

git review 把分支上的提交推到服务器

