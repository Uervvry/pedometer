# **概述**

手机计步器模块（内含iOS和android）

APICloud 的 pedometer 模块是一个计步器模块。由于 android 平台和 iOS 平台系统差异，本模块分别实现两套计步方案：在 android 平台上开发者自行调用相关接口记录用户不行数据；在 iOS 平台上则直接读取手机系统记录的用户步行数据；由于本模块实现原理的特殊性，应广大开发者要求，特将此模块源码开源，以供 APICloud 平台上的开发者学习使用。开发者可仿照此模块开发自己需要的模块。希望此模块能起到抛砖引玉的作用。

# **模块接口文档**

<p style="color: #ccc; margin-bottom: 30px;">来自于：APICloud 官方</p>

<ul id="tab" class="clearfix">
	<li class="active"><a href="#method-content">Method</a></li>
</ul>

<div class="outline">

[startCount](#startCount)
[stopCount](#stopCount)
[getSteps](#getSteps)
[getStepCount](#getStepCount)

</div>

# **模块概述**

由于系统平台差异，iOS 和 android 采用不同的计步策略。本模块特封装了两种适合各自平台的相关接口。

一 、适合 android 平台的接口：

	startCount
	
	stopCount
	
	getSteps

二 、适合 iOS 平台的接口：

	getStepCount

**android 平台计步接口说明**

在 android 平台上，模块底层实现了一个计步器的功能，当 app 启动，并调用 startCount 接口，模块计步器开始记录步行数据。当此 app 切入后台不影响该计步器的记录。当用户从后台关闭该 app，则停止记录。因此，要想完整记录步行数据，则必须保证 app 至少能在后台运行。

Android 调用方式及流程：

Android 计步器的统计周期为调用 startCount 到调用 stopCount 之间，如果再此调用startCount 计步器将从零开始统计

	//调用 startCount 方法开启统计监听服务，此时模块开始统计，可在回调函数获取步行事件及其数据记录
	startCount(callback(ret)):
	//返回当前统计的总步数
	getSteps(callback(ret)):
   //停止统计
	stopCount()：
		
**iOS 平台计步接口说明**

在 iOS 平台上，手机系统会自动记录步行数据，开发者只需获取系统记录的步行数据即可。

**注意：**

在 iOS 平台上使用本功能，需要在 [生成包名（bundle id）](http://docs.apicloud.com/Dev-Guide/iOS-License-Application-Guidance) 的时候，勾选 HealthKit 功能。如下图：

![alert](/img/docImage/pedometer/pedometer.png)

iOS 调用方式及流程：

    //通过传入统计时间段就可以返回相应时段的步数
	getStepCount():
		
	

# #模块接口

<div id="startCount"></div>

# **startCount**

 开始计步

startCount(callback(ret))


## callback(ret)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
	  steps: 20            //数字类型；当前统计的步数
}
```

## 示例代码

```js
	var pedometer = api.require('pedometer');
	pedometer.startCount(function(ret) {
	    alert(ret.steps);
	});
```

## 可用性

Android系统

可提供的1.0.0及更高版本

<div id="stopCount"></div>

# **stopCount**

停止计步

stopCount()

## 示例代码

```js
var pedometer = api.require('pedometer');
pedometer.stopCount();
```
## 可用性

Android系统

可提供的1.0.0及更高版本

<div id="getSteps"></div>

# **getSteps**

获取当前统计的步数****

getSteps(callback(ret))

## callback(ret)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
	  steps: 20            //数字类型；行走的步数
}
```


## 示例代码

```js
var pedometer = api.require('pedometer');
pedometer.getSteps(function(ret) {
    alert(ret.steps);
});
```
## 可用性

Android系统

可提供的1.0.0及更高版本

<div id="getStepCount"></div>

# **getStepCount**

获取步数

getStepCount({params}, callback(ret))

## params

startTime:

- 类型：字符串
- 描述：开始日期
- 格式：2016-09-01 13:20:30

endTime:

- 类型：字符串
- 描述：结束日期（结束日期和开始日期之间的差值不得超过三天，如果超过三天，按三天来算。）
- 格式：2016-10-01 10:20:30

count:

- 类型：数字类型
- 描述：（可选项）获取最近数据的数量，默认为0,0代表最多数量.

remove:

- 类型：布尔类型
- 描述：（可选项）是否移除人为添加的步行数据
- 默认：false

## callback(ret)

- 类型：JSON 对象
- 内部字段：

```js
{
	  total     : 0             //数字类型，行走的总步数
	  beginTime : '',           //字符串类型，开始时间       
	  finishTime   : '',        //字符串类型，完成时间
	  details:[{                //详情数据
			  stepCount : 20,    
			  startTime : '',
			  endTime   : '',  
	  },{ 
			  stepCount : 30,
			  startTime : '',
			  endTime   : '',
	  }]
}
```

## 示例代码

```js
var pedometer = api.require('pedometer');
pedometer.getStepCount({
    count: 0,
    startTime: '2016-07-13 07:20:30',
    endTime: '2016-07-13 12:00:00'
}, function(ret) {
    alert(JSON.stringify(ret));
});
```

## 可用性

iOS系统

可提供的1.0.0及更高版本