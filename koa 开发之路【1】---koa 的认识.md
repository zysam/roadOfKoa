## koa 的认识
---
用 koa 框架创建 http 服务只要三步：

1. 创建 app 实例 ： `app = koa()`
2. 添加中间件 : `app.use(middelware)`
3. 创建 http 服务 ： `app.listen(port)`

OK，就是这么简单。
那么，下面就来看看它为什么这样简单。

**客户端发起请求到服务器后，场景假想如下 : 小冰带上 【通行证】，提着 【需求】，要到你的 【图书馆】 里查找 【资料】，并取回 【结果】。**
### koa 的初始化
`app.use()`是什么东东？


1. *[通行证] ： 假设这张 [通行证] 有很多 {条例}，对于不同的 {条例}，[图书馆] 设计者安排不同的人来核查，我们称这些人为 '中间人'' .*`app.use()`的作用就是把中间人排列组合起来 , 采用数组方式 , `app.use(mw1);app.use(mw2);app.use(mw3);...;app.use(mwn)`就是 `middleware[mw1],...,middleware[mw1,mw2,...,mwn]`, 嗯 ! `app.use(mw)` 就是 `middleware.push(mw)` , 就这样 , 没有了 .

2. `app.listen(port)` , 这个方法只有两步:

- 1) 创建 http 服务 `server = http.createServer(callback)`, 2) 监听 port ; 

**callback 就是服务内容 . 这时 callback 是这么做的 : **

1.  加入一个中间件 : 将 `*respond` 函数 ( 封装了 http 的最后 respond ) 加入中间件数组 , 顺序是这样子的 middleware ['respond',mw1,...,mwn];

2. 解开中间件数组 : `compose`出场 , 几行代码就发布一个 package , 牛呀 ! 取出最后一个中间件 mwn , 传入一个参数 next (这时 next 是一个空函数或者是你的业务函数) , `mwn(next)` , 并绑定 ctx (封装 http 的 req 和 res) 到 mwn 的上下文`this` , 最终是 `mwn.call(this,next)` ; mwn-1 , 传入一个参数 next (这时 next 是 mwn ) , `mwn-1.call(this,mwn)` ; 返回第一个中间件 `gen = respond.call(this,mw1)`

3. 用 co 包装 gen , co 是个异步流组织 , 运行 generator 函数 , `yield *` 一个 gen/promise/thunk , 都是无阻单步直入 ; 如果 `yield` , 等待 `gen.next()` 再继续 ; 直到没有 `yield` , 就原路折回 . co 代码不多无依赖 , 却是个 gen++ , 超级 gen , koa 的核心工厂流水线 .

4.  返回一个正常的函数 , 最终是这样的` htp.creatServer(fn(req,res){//do sth}) `.

### koa 的运行过程

** 当 client 发起请求时 ** http 服务做三件事 , 1) 事件处理 ;2) 等待事件处理结束返回结果 res ;3) 连接错误 ;**

- 监听是否结束及错误 , 交给 `onFinish(res,ctx.onerror)`.

- 事件处理过程 : 初始化时 , co(gen) 返回的是一个函数 fn(done) , done 函数就是统一处理错误 . 传入`ctx.onerror`参数, 绑定 ctx 到各个中间件的上下文 `this` , 运行 `fn.call(ctx,ctx.onError)` .

**`ctx` 封装了全局 `req ,res`的内容以及错误处理 , 全局 `ctx` 通过 `yield` 一个中间件里的上下文 `this` 来传址 **

1. 经过 `respond` , 很明显 `respond` 的作用是返回 [结果] 的 , 所以一开始设置 `res.headers` 默认为 `i am koa` 之类豪言就 `yield *next()`了 .( next 就是初始化时 mw1 )

2. 回到假想 , mw1 这个中间人作点记录或者核对工作 , 交给下一步 . 小冰在 [通行证] 最后一条 核对的中间人指导下 , [图书馆] 满足小冰 [需求] , 取出 [结果] , 小冰原路返回 , 这些中间人再根据 [结果] , 多些一事情 . 在这些过程中 , 发生些错误就交给全局错误处理 , 另外有些中间人发现 [通行证] 不符合 [图书馆] 规章 , 会作出标记和遣回的处理 , 视中间人职责而定 .

### koa 总结
整个过程如图 ：

认识 koa 

1. ES6 的 generator 函数 ; compose + co , 前者控制顺序 , 后者流水运行;

2. ES6 的 promise 运用 (不然你怎么优雅地用 `yield` 来异步) ;

3. `this`这个传址关键词 (js 的基础 , 出场最多 , 最难搞就是它 , 常常弄不清上下文的痛苦) , `call/apply/bing` 等方法对 `this` 的绑定处理 .

下篇介绍 koa 的那些中间件 , 先睡了 , 都写了一夜 .



