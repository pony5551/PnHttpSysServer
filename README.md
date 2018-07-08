# PnHttpSysServer
ms httpapi server with iocp
微软 httpapi 异步封装


为兼容之前的项目代码中参考并复制了大量mORMot的代码，只有核心部份重写了使用基于iocp的模型
另外感谢diocp群友菜根对本人基础知识的解惑

0.8a 第一版，代码较乱，比较粗糙

0.9a 整理了部份代码，并修正了一个request body接收完成时的bug