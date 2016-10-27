package com.apicloud.pedometer;


import org.json.JSONException;
import org.json.JSONObject;

import android.content.Intent;

import com.apicloud.pedometer.StepsDetectService.OnStepDetectListener;
import com.uzmap.pkg.uzcore.UZWebView;
import com.uzmap.pkg.uzcore.uzmodule.UZModule;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;

public class StepCounter extends UZModule{
	
	public StepCounter(UZWebView webView) {
		super(webView);
	}
	
	public void jsmethod_startCount(final UZModuleContext uzContext){
		
		mContext.startService(new Intent(mContext, StepsDetectService.class));
		StepsDetectService.setOnStepDetectListener(new OnStepDetectListener() {
			@Override
			public void onStepDetect(int steps) {
				callback(uzContext, steps);
			}
		});
	}
	
	public void jsmethod_stopCount(final UZModuleContext uzContext){
		mContext.stopService(new Intent(mContext, StepsDetectService.class));
	}
	
	public void jsmethod_getSteps(final UZModuleContext uzContext){
		callback(uzContext, StepsDetectService.steps);
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
