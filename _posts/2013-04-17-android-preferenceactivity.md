---
layout: post
title: "android preferenceActivity"
description: ""
category: 
tags: []
---
{% include JB/setup %}
一个例子：

    public class SettingsActivity extends PreferenceActivity
    				implements OnPreferenceChangeListener {
	private static final String perf_host_ip = "perf_host_ip";

	@Override
	protected void onPostCreate(Bundle savedInstanceState) {
		super.onPostCreate(savedInstanceState);
		addPreferencesFromResource(R.xml.pref_iot);
		
		Preference host_ip = findPreference(perf_host_ip);
		host_ip.setOnPreferenceChangeListener((OnPreferenceChangeListener) this);
	//	initPreference(host_ip);

	}

	private void initPreference(Preference preference)
	{
		this.onPreferenceChange(preference,
				PreferenceManager.getDefaultSharedPreferences(
						preference.getContext()).getString(preference.getKey(),
						""));
	}

	@Override
	public boolean onPreferenceChange(Preference preference, Object value) {
		String stringValue = value.toString();
		
		preference.setSummary(stringValue);		
		return true; 返回false不会被保存
	}
    }


onPreferenceChange返回值为ture时，这个preferenceChange才会保存。前面搞错了，那个initPreference没有作用的。

在别的类中给那个SharedPreferences弄个listener就可听到改变，从而做出相应动作。

