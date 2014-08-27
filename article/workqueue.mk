那个jni往JAVA的异步通知想找一个异步运行的机制，自己懒得写了。在native发现了一个叫looper的东西，但是，这玩意与java中的不太一样。然后无意在frameworks/native/libs/utils中发现有一个workqueue。呵呵，能满足需求。


<utils/WorkQueue.h>

构造函数
WorkQueue(size_t maxThreads, bool canCallJava = true)

往队列中加入WorkUnit
status_t schedule(WorkUnit* workUnit, size_t backlog = 2);

WorkUnit就是需要运行单元：

    class WorkUnit {
    public:
        WorkUnit() { } 
        virtual ~WorkUnit() { } 

        /*  
         * Runs the work unit.
         * If the result is 'true' then the work queue continues scheduling work as usual.
         * If the result is 'false' then the work queue is canceled.
         */
        virtual bool run() = 0;
    };

run要返回true，要不然，这个workqueue就停止了。

哈哈，有video和audio两种事件，可以继承不同的WorkUnit，当然，还可以添加数据成员，在run就可以进行处理。

用起来简单但灵活的机制。


