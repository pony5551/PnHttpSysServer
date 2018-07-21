# PnHttpSysServer
ms httpapi server with iocp
微软 httpapi 异步封装


为兼容之前的项目代码中参考并复制了大量mORMot的代码，只有核心部份重写了使用基于iocp的模型
另外感谢diocp群友菜根对本人基础知识的解惑

为什么重新封装？
使用中发现mORMot的httpapiserver存在线程阻塞的方法，如果超过服务器线程数的慢网速客户端不停地post数据到服务器端，或者不停下载服务器上的大一点的文件，就会严重拖慢服务器，甚至卡死服务器线程，
这个问题我向mORMot作者提出过，前且我修改过一个SynCrtSock.pas为THttpApiServer.Execute增加了一个系统的线程池(Winapi.Windows.QueueUserWorkItem)来作为工作线程，结果是THttpApiServer.Execute的线程不再会被阻塞并且整体性能提升1.5到2倍

后来发现系统管理的线程池中有很多不可控因素，比如线程的运行前与运行后的事件，绑定在QueueUserWorkItem时会不停地调用，但绑定在THttpApiServer时又与工作线程存在同步问题

之上列出的问题个人部结了一下，就有个现在的封装，基于iocp异步模式的http服务器

其性能较mORMot提升3-4倍


0.8a 第一版，代码较乱，比较粗糙

0.9a 整理了部份代码，并修正了一个request body接收完成时的bug

0.9.1a 把mormot的几个设置都移过来了，目前还有日志没有完善，还有线程事件没有增加

0.9.2a 增加w3c日志,增加异步的文件发送(基于mORMot的方法修改)

0.9.3a 修正文件缓存与大文件下载

0.9.4b 测试版，调整了启动日志的参数,整理了部分代码与注释微调响应静态文件

0.9.5b 增加OnCallWorkItemEvent事件,可以另开工作线程处理任务,另修正DoAfterResponse的出发位置，增加上传文件demo代码(文件块处理代码未完成)

0.9.6b 调整Start与Stop的代码，修正SendErr不存日志的问题

0.9.7b 优化日志写入，调整几出代码位置

0.9.8r 增加请求统计，优化应答数据处理，上线测试5天300万次用户请求无异常。