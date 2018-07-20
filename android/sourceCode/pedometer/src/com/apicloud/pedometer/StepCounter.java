/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.apicloud.pedometer;


import org.json.JSONException;
import org.json.JSONObject;

import android.content.Intent;
import com.apicloud.pedometer.StepsDetectService.OnStepDetectListener;
import com.apicloud.pedometer.newversion.StepService;
import com.uzmap.pkg.uzcore.UZWebView;
import com.uzmap.pkg.uzcore.uzmodule.UZModule;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;

public class StepCounter extends UZModule{
	
	public StepCounter(UZWebView webView) {
		super(webView);
	}
	
	public void jsmethod_startCount(final UZModuleContext uzContext){
		
		StepService.setOnStepDetectListener(new OnStepDetectListener() {
			@Override
			public void onStepDetect(int steps) {
				callback(uzContext, steps);
			}
		});
		context().startService(new Intent(context(), StepService.class));
	}
	
	public void jsmethod_stopCount(final UZModuleContext uzContext){
		 context().stopService(new Intent(context(), StepService.class));
	}
	
	public void jsmethod_getSteps(final UZModuleContext uzContext){
		callback(uzContext, StepService.mSteps);
	}
	
	public void callback(UZModuleContext uzContext, int steps){
		JSONObject ret = new JSONObject();
		try {
			ret.put("steps", steps);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		uzContext.success(ret, false);
	}
}
