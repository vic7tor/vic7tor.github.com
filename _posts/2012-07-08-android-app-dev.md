---
layout: post
title: "Android App Dev"
description: ""
category: 
tags: []
---
{% include JB/setup %}
#Activity
在android中一个activity是程序中的一个界面。android中一个界面都是全屏的，Activity就像是应用程序中的一个窗体。
##
可以在androidMainifest.xml中指定某个特定的Activity为为主Activity从而被默认运行。Android程序中没有main函数一个Activity为执行入口。
##启动另一个Activity
`startActivity(new Intent(getApplicationContext(), MyDrawActivity.class);`
Intent还有别的方式来启动另一个Activity，包括另一个程序中的。

#AndroidManifest.xml
这个文件定义程序的名字，图标，有哪些Activity，及哪个Activity是程序主入口，以及这个程序需要哪个权限。
##注册Activity
应用程序每一个Activity都需要注册，否则就不能被运行。使用下面代码注册一个activity
`<activity android:name="AudioActivity" />`
这一Activity必须在你的应用包在以类的方式定义。
#Widget与View
View类是Android基本的用户界面构建模块，它代表屏幕的一个矩形区域。View类是几乎所有Widget与布局的基类。
#按钮与事件
`Button basic_button = (Button) findViewById(R.id.basic_button);
basic_button.setOnClickListener(new View.OnClickListener() {
	public void onClick(View v) {
	 Toast.makeText(Buttons.this, 
	 }
}`
要想在某个按钮按下时处理单击事件，首先需要通过资源标识符获得它的引用。下一步，调用setOnClickListener方法，这需要一个有效的View.OnClickListener类的实例，提供该实例的一种简单的方法是在方法调用中定义一个。这需要实现onClick()方法。
#listview
listview自定义Adapter
`public class myadapter extends BaseAdapter {
	LayoutInflater mInflater;
	public view getView(int position, View convertView, ViewGroup parent) {
	mInflater = LayoutInflater.form(context);
	convertView = mInflater.inflate(R.layout.myitem, null);
	TextView tv = (TextView) convertView.findViewById(R.id.xx);
	tv.setText("test);
	return convertView;
}

public int getCount()
{

}
}

listview.seAdapter(new myadapter());`

