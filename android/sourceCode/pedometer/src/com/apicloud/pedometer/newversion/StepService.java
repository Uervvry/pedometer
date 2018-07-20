/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.apicloud.pedometer.newversion;

import com.apicloud.pedometer.StepsDetectService.OnStepDetectListener;

import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.os.Binder;
import android.os.IBinder;
import android.support.annotation.Nullable;
import android.util.Log;

/**
 * Created by finnfu on 16/9/27.
 * 
 *  ==================================================================
 *  | reference from | https://github.com/jiahongfei/TodayStepCounter
 *  ==================================================================
 */

public class StepService extends Service{
	
    private final IBinder mBinder = new StepBinder();
    private Sensor mSensor;
    private SensorManager mSensorManager;
    private StepCount mStepCount;
    private StepDetector mStepDetector;

    private final static int GRAY_SERVICE_ID = 1001;
    
    public static int mSteps = 0;

    private StepValuePassListener mValuePassListener = new StepValuePassListener() {
        @Override
        public void stepChanged(int steps) {
        	
        	mSteps = steps;
        	if(mOnStepDetectListener != null){
        		mOnStepDetectListener.onStepDetect(steps);
        	}
        }
    };
    
    
    public static OnStepDetectListener mOnStepDetectListener = null;
	
	public static void setOnStepDetectListener(OnStepDetectListener mListener){
		mOnStepDetectListener = mListener;
	}

    @Override
    public IBinder onBind(Intent intent) {
        return this.mBinder;
    }
    
    public void onCreate() {
        super.onCreate();
        
        Log.i("debug", "service create");
        
        this.mStepDetector = new StepDetector();
        this.mSensorManager = ((SensorManager)getSystemService(Context.SENSOR_SERVICE));
        this.mSensor = this.mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        this.mSensorManager.registerListener(this.mStepDetector, this.mSensor, SensorManager.SENSOR_DELAY_UI);
        this.mStepCount = new StepCount();
        this.mStepCount.initListener(this.mValuePassListener);
        this.mStepDetector.initListener(this.mStepCount);
    }



    public int onStartCommand(Intent paramIntent, int paramInt1, int paramInt2) {
        return START_STICKY;
    }


    public void onDestroy() {
        this.mSensorManager.unregisterListener(this.mStepDetector);
        super.onDestroy();
    }
    
    public void resetValues() {
        this.mStepCount.setSteps(0);
    }

    public boolean onUnbind(Intent paramIntent) {
        return super.onUnbind(paramIntent);
    }

    public class StepBinder extends Binder {
        StepService getService() {
            return StepService.this;
        }
    }

    public static class GrayInnerService extends Service{
        @Override
        public int onStartCommand(Intent intent, int flags, int startId) {
            startForeground(GRAY_SERVICE_ID, new Notification());
            stopForeground(true);
            stopSelf();
            return super.onStartCommand(intent, flags, startId);
        }
        @Nullable
        @Override
        public IBinder onBind(Intent intent) {
            return null;
        }
    }

}
