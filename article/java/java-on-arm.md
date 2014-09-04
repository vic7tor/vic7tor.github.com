#1.java版本选择

关于编译内核时使用的浮点，导致java版本需要选择对。EABI问题。

一共有三种：

gcc编译使用时的选择：

-mfloat-abi=hard -mfpu=vfp
-mfloat-abi=softfp -mfpu=vfp
-msoft-float

这个三个选项在java embedded的下载页面有描述。

这个要根c库的实现走。

#java 8
解开ejdk后，在bin下有个./jrecreate.sh，看了下内容要在bin目录下运行这个文件才行。

还有，host的jdk要jdk8才行，为jdk6会报错。报找不到类。

运行./jrecreate.sh，后有一个--vm的选项。

最终的命令：
./jrecreate.sh --dest ../jre-arm-all --vm all -g -k

关于vm:server client的差异，见The Java HotSpot Performance Engine Architecture的Java HotSpot Client Compiler、Java HotSpot Server Compiler

Java HotSpot Client Compiler
The Java HotSpot Client Compiler is a simple, fast three-phase compiler. In the first phase, a platform-independent front end constructs a high-level intermediate representation (HIR) from the bytecodes. The HIR uses static single assignment (SSA) form to represent values in order to more easily enable certain optimizations, which are performed during and after IR construction. In the second phase, the platform-specific back end generates a low-level intermediate representation (LIR) from the HIR. The final phase performs register allocation on the LIR using a customized version of the linear scan algorithm, does peephole optimization on the LIR and generates machine code from it.

Emphasis is placed on extracting and preserving as much information as possible from the bytecodes. The client compiler focuses on local code quality and does very few global optimizations, since those are often the most expensive in terms of compile time.

Java HotSpot Server Compiler
The server compiler is tuned for the performance profile of typical server applications. The Java HotSpot Server Compiler is a high-end fully optimizing compiler. It uses an advanced static single assignment (SSA)-based IR for optimizations. The optimizer performs all the classic optimizations, including dead code elimination, loop invariant hoisting, common subexpression elimination, constant propagation, global value numbering, and global code motion. It also features optimizations more specific to Java technology, such as null-check and range-check elimination and optimization of exception throwing paths. The register allocator is a global graph coloring allocator and makes full use of large register sets that are commonly found in RISC microprocessors. The compiler is highly portable, relying on a machine description file to describe all aspects of the target hardware. While the compiler is slow by JIT standards, it is still much faster than conventional optimizing compilers, and the improved code quality pays back the compile time by reducing execution times for compiled code.

