Import "ShanHai.lua"
Import "GK.lua"
Import "Thread.lua"

/**
 * ↓↓↓ 初始化所有变量
 */
'是否不同分辨率
Dim diffXY = False
'按钮坐标系
Dim buttons = { "edit": Array(1001, 1152), "et_switch": Array(548,1756), "et_upgrade": Array(856, 1756) }
'火车货物
Dim goodsList = { 1: Array(646, 1646, 750, 1716), 2: Array(804, 1568, 899, 1631), 3: Array(955, 1477, 1054, 1549) }
Dim goodsPoints = { 1: Array(683, 1683), 2: Array(839, 1604), 3: Array(991, 1517) }
Dim goodsOcrNum = { "x1": 1, "x2": 2, "x3": 3, "x4": 4 }
Dim goodsTryTimes = 0 '尝试拉货次数
Dim goodsExist = False '是否有货物

'建筑坐标系 0:x 1:y 2:goods 3:update
Dim buildings(8, 4)

'自动收割金币
Dim mowing = ReadUIConfig("mowing", True)

'自动升级建筑次数
Dim autoLevelUpTimes = 0

'自定义升级间隔 (单位: 秒)
Dim autoUpdateInterval = Int(ReadUIConfig("update_time"))

'跳过货物后是否重启游戏
Dim ignoreAfter = ReadUIConfig("ignore", 0), ignoreOP = "等待"

'升级政策
Dim policyTimes = 0
Dim policyInterval = 120

'防假死设定
Dim stuckTimes = 0, preventStuck = ReadUIConfig("prevent_stuck", True)

'应用包名
Dim package = "com.tencent.jgm"

'是否收火车
Dim recieveTrain = ReadUIConfig("recieveTrain", True)

'是否升级政策
Dim upgradePolicy = ReadUIConfig("upgradePolicy", True)

'
Dim startDay = DateTime.YearDay()

/**
 * ↑↑↑ 变量初始化完毕
 */


// 初始化
Call Init()
Call Testing()

// 启动防卡住进程 - 每隔10秒检测一次
Thread.Start HandleOKButton
TracePrint "开始循环"

//主要工作开始
Call Main()

//TODO:
//0. 添加房子切换功能，收火车时增加切换房子驱赶火车的选项
//1. 添加火车收集完成后，自动切换回收钱板子
//2. 当12点火车刷新后，自动切换到火车板子
//3. 政策通过ocr识别种类，优先升级某一类政策（或者支持种类排序）


Function Main
	While True
    	Delay 200
    	Tap 17, 1907
    	Delay 200
    	Tap 17, 1907
    	Delay 200
    	Dim same = CmpColor(155, 1888, "FFFFFF", 1)
    	If same = 0 Then 
        	stuckTimes = 0
        	// 防弹窗
        	Tap 17, 1907
        	Delay 200
        	
        	// 收集货物 
        	If recieveTrain Then 
            	HandleTrain 
            	RestartOnMidNight
        	End If
        	
        	// 收集金币
        	HandleGold 
        	
        	// 自动升级
        	HandleAutoLevelUp 
        	
        	// 自动升级政策
        	If upgradePolicy Then 
        		HandlePolicyLevelUp
        	End If
        	
        	Delay 1000
    	Else 
        	If preventStuck Then 
            	stuckTimes = stuckTimes + 1
            	HandleStuck 
            	Delay 1000
        	End If
    	End If
	Wend
End Function


//半夜重启
Function RestartOnMidNight
	Dim nowDay = DateTime.YearDay()
	If nowDay > startDay Then 
		Call RestartGame()
		startDay = nowDay
	End If
End Function

//自动升级政策（现在只能随机升级）
Function HandlePolicyLevelUp
    TracePrint "检查并自动升级政策"
	
    '退出政策窗口按钮与升级按钮
    Dim exitX = 1010
    Dim exitY = 215
    Dim upX = 550
    Dim upY = 1180
	
    Dim intX, intY
	
	
    FindPic 100, 100, 400, 400, "Attachment:dashboard_upgrade_policy_sign.png", "000000", 4, 0.9, intX, intY
    If intX = -1 And intY = -1 Then 
    //    Exit Function
    End If
	
    '打开升级窗口
    Tap intX, intY
	
    '跳过上一个政策升级完成的屏幕
    For 5
    	Delay 400
    	Tap 380, 1640
    	TracePrint "点击了"
    Next
	
	
    '现时政策窗口长度最多滑动6次
    For 10
        FindPic 0, 0, 0, 0, "Attachment:policy_upgradable_sign.png", "000000", 3, 0.6, intX, intY
		
        If intX > -1 And intY > -1 Then 
            Delay 1000
            TracePrint "找到了第一个政策坐标"& intX & ":" & intY
            Tap intX+50, intY+50
            Delay 1000
            Tap upX, upY
            Delay 3000
            Tap exitX, exitY

            Exit For
        Else 
            '滑动一屏
            QuickSwipe 112,1560,112,568
        End If
		
    Next
	
End Function

Function QuickSwipe(x1,y1,x2,y2)
    TouchDown x1, y1, 1
    Delay 20
    TouchMove x2, y2, 1, 380
    Delay 600
    TouchUp 1	
End Function

//没有字库做不到识别中文，暂时搁置
Function ChangeBuildingByName(i, name)
	Dim edit = buttons["edit"], switch = buttons["et_switch"]
	Dim target(2), isFound, nowBuildingName
	Tap edit(0), edit(1)
	Delay 200
	//进入编辑状态
	Tap buildings(i, 0), buildings(i, 1)
	Delay 200
	Tap switch(0), switch(1)
	Delay 200
	nowBuildingName = Ocr(430,225,700,300,"9f2e3f-000000",0.9)
//	isFound = FindStr(430, 225, 0, 0, name, "9f2e3f-000000", 0.9, target(0), target(1))
	
	TracePrint nowBuildingName
	

	//退出编辑状态
	Delay 100
//	Tap edit(0), edit(1)
End Function

Sub Testing

    '修改这个变量判断是否进入测试模式
    Dim ifTest = 0

    If ifTest = 1 Then 
        TracePrint "进入测试模式"
		
		
		
        While True
            TracePrint "测试完成ok"
            Delay 10000		
        Wend
	
    End If

End Sub


Sub Init
    // 获取屏幕分辨率
    If GetScreenX() <> 1080 Or GetScreenY() <> 1920 Then 
        ShowMessage "建议将模拟器分辨率设为 1080 × 1920 DPI: 480"
        diffXY = True
        // EndScript
        SetScreenScale 1080, 1920
        Delay 1000
    End If

    RunApp package

    If ignoreAfter = 2 Then 
        ignoreOP = "重启游戏"
    ElseIf ignoreAfter = 1
        ignoreOP = "飞行模式"
    End If

    TracePrint "升级间隔: " & autoUpdateInterval & "秒"
    TracePrint "货物跳过后操作: " & ignoreOP
	
    // 开启快速取色
    If EnableFastCapture(true) Then 
        TracePrint "开启快速取色"
    End If
    

    // 载入字库
    SetDictEx 0, "Attachment:number.txt"
    SetRowsNumber (0)
    UseDict 0
	
    Dim arr = Split("294,1182 552,1057 803,931 294,931 552,803 803,680 294,680 552,549 803,429", " ")
    For i = 0 To 8
        Dim pos = GetPosition(arr(i))
        buildings(i, 0) = pos(0)
        buildings(i, 1) = pos(1)
        // 读取配置
        buildings(i, 2) = ReadUIConfig("goods_" & (i + 1))
        buildings(i, 3) = ReadUIConfig("update_" & (i + 1))
        Dim g = "否", u = "否"
        If buildings(i, 2) Then 
            g = "是"
        End If
        If buildings(i, 3) Then 
            u = "是"
        End If
        TracePrint "建筑" & (i + 1) & " 收货 ->" & g & " 升级 ->" & u
    Next
End Sub

// 获取坐标
Function GetPosition(str)
    GetPosition = Split(Replace(str, " ", ""), ",")
End Function

// 检测 "好的" 按钮并自动点击
Function HandleOKButton
    While True
        Dim x, y
        FindPic 0, 0, 0, 0, "Attachment:OKBTN.png", "000000", 0, 1, x, y
        If x > -1 And y > -1 Then
            Tap x, y
        End If
        Delay 10000
    Wend
End Function

// 获取金币
Sub HandleGold
    If mowing Then 
        For i = 0 To UBOUND(buildings)
            Tap buildings(i, 0), buildings(i, 1)
            Delay 100
        Next
        '等待1.5s防止画面抖动
        Delay 1500
    End If
End Sub

// 查找货物是否存在
Function DecideGoods
    Dim found = False
    For i = 1 To 3
        Dim zb = goodsPoints[i]
        Dim cp = CmpColor(zb(0), zb(1), "FFFFFF", 1)
        If cp > -1 Then 
            found = True
            goodsExist = True
            Exit For
        End If
    Next
    DecideGoods = found
End Function

// 处理火车
Sub HandleTrain
    goodsTryTimes = 0

    // 有火车先送火车
    Do While DecideGoods()
        TracePrint "找到货物"
        goodsTryTimes = goodsTryTimes + 1
    	
        // 超过三次重试	
        If goodsTryTimes > 3 Then 
    	
            If ignoreAfter = 1 Then 
                BackgroundGame 
            ElseIf ignoreAfter = 2
                RestartGame 
            End If
            
            goodsExist = False
        	
            Exit Do
        Else

            For i = 1 To 3
                HandleGoods(i)
            Next
        
        End If
        Delay 1000
    Loop
        
    If goodsExist = False Then
        TracePrint "无货物"
        goodsTryTimes = 0
    End If
    
    Delay 500
End Sub

// 适应分辨率调整
Function HandleGoodsOcr(i)
    If diffXY Then 
        Dim zb = goodsPoints[i]
        Dim cp = CmpColor(zb(0), zb(1), "FFFFFF", 1)
        If cp > -1 Then 
            HandleGoodsOcr = "x3"
        Else 
            HandleGoodsOcr = ""
        End If
    Else 
        Dim pos = goodsList[i]
        HandleGoodsOcr = Ocr(pos(0), pos(1), pos(2), pos(3), "FFFFFF", 0.9)
    End If
End Function

// 拖拽货物
Function HandleGoods(i)

    Dim pos = goodsList[i]
    Dim body = HandleGoodsOcr(i)

    If StrComp(body, "") <> 0 Then 
        Dim num = goodsOcrNum[body]
        TracePrint i & "号位置货物数量: " & num
    	
        '定义数组
        Dim bColor()
        
        KeepCapture 
        For m = 0 To 8
            Dim color = GetPixelColor(buildings(m, 0), buildings(m, 1) - 45)
            bColor(m) = color
        Next
        ReleaseCapture 
    	
        // 按下货物
        TouchDown pos(0), pos(1), 1
        Delay 200
        
        Dim found = -1
        
        KeepCapture 
        // 查找区域
        For n = 0 To 8
            Dim x = buildings(n, 0), y = buildings(n, 1) - 45
            Dim fx, fy
            
            Dim afterColor = GetPixelColor(x, y)
            // 比较颜色差值
            Dim diff = ColorDiff(bColor(n), afterColor)
            
            If diff > 60 Then 
                If buildings(n, 2) Then 
                    found = n
                    Goto MOVEGOODS
                Else 
                    TracePrint "货物跳过"
                End If
            	
                Exit For
            End If
        Next 
        
        Rem MOVEGOODS
        ReleaseCapture
        TouchUp 1
        Delay 200
        
        // 拖拽货物
        If found > -1 Then 
            Dim zb = goodsPoints[i]
            For t = 1 To num
                TracePrint "货物:" & i & " -> " & (found+1)
                TouchDown pos(0) + 20, pos(1), 1
                Delay 200
                TouchMove buildings(found, 0), buildings(found, 1), 1
                Delay 100
                TouchUp 1
                Delay 700
            Next
            Delay 1000
        End If
    Else 
        TracePrint i & "号位置货物数量: 0"
    End If
End Function

// 自动升级
Sub HandleAutoLevelUp
    Dim t = TickCount(), needLevelUp = False, edit = buttons["edit"], upgrade = buttons["et_upgrade"]
    If autoUpdateInterval > 0 And t \ ( autoUpdateInterval * 1000 ) - autoLevelUpTimes > 0 Then 
        Dim editClicked = False
        For i = 0 To Ubound(buildings)
            If buildings(i, 3) Then 
                If editClicked = False Then 
                    Tap edit(0), edit(1)
                    editClicked = True
                End If
                needLevelUp = True
                Delay 100
                Tap buildings(i, 0), buildings(i, 1)
                Delay 300
                Tap upgrade(0), upgrade(1)
                Delay 100
            End If
        Next
        If needLevelUp Then 
            autoLevelUpTimes = autoLevelUpTimes + 1
            Tap edit(0), edit(1)
            Delay 200
        End If
    End If
End Sub


// 重启游戏
Function RestartGame
    TracePrint "重启游戏"
    KillApp package
    goodsTryTimes = 0
    stuckTimes = 0
    Delay 200
    RunApp package
    Delay 3000
End Function

// 将游戏转入后台并开启飞行模式
Function BackgroundGame
    TracePrint "进入飞行模式"
    KeyPress "Home"
    ShanHai.OpenAirplane
    ShanHai.CloseAirplane 
    RunApp package
    Delay 3000
End Function

// 判断假死并重启游戏
Sub HandleStuck
    If stuckTimes > 60 Then 
        TracePrint "检测到游戏卡死, 重启游戏"
        RestartGame
    End If
End Sub

