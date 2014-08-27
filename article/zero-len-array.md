0长度的数组sizeof时长度为0，但是有指针。

所以在一些数据的头部是有用的。

如：

    struct inotify_event {
        __s32           wd;             /* watch descriptor */
        __u32           mask;           /* watch mask */
        __u32           cookie;         /* cookie to synchronize two events */
        __u32           len;            /* length (including nulls) of name */
        char            name[0];        /* stub for possible name */
    };

C代码：

#include <stdio.h>
#include <stdlib.h>

int main()
{
        char null[0];

        printf("sizeof(null)=%d, ptr=%p\n", sizeof(null), &null);
}

