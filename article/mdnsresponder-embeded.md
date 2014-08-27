#1.dnssd_clientshim.c
这个如何与mDNSCore交互呢？

跟DNSServiceGetAddrInfo吧。

##1.DNSServiceGetAddrInfo

DNSServiceQueryRecord重要的参数mDNS_DirectOP_GetAddrInfo->

DNSServiceQueryRecord->

mDNS_StartQuery->

	q = &m->Questions;
	...
	*q = question;

question的callback调用路径：

	mDNS_Execute() {
		...
		AnswerNewQuestion
		...
		AnswerAllLocalQuestionsWithLocalAuthRecord
		...
		AnswerAllLocalQuestionsWithLocalAuthRecord
	}

mDNSPosixGetFDSet和MainLoop都调用了mDNS_Execute。



#2.mDNSCore/mDNSEmbeddedAPI.h
##1.mDNS_Init

	mDNSPlatformInit

mDNSPlatformInit初始化unicastSocket4

SetupOneInterface初始化multicastSocket4

###1.AdvertiseInterface
SetupOneInterface->mDNS_RegisterInterface->AdvertiseInterface

AdvertiseInterface:
AssignDomainName(&set->RR_A.namestorage, &m->MulticastHostname);

mDNS_Register_internal: Adding to active record list    4 localhost.local. Addr 192.168.137.3

###hostname的确定
上面的AssignDomainName用到的

mDNSPlatformInit：

	GetUserSpecifiedRFC1034ComputerName();
	mDNS_SetFQDN(m);
	...
	SetupInterfaceList(
	...
	WatchForInterfaceChange

###WatchForInterfaceChange
mDNSPosixRunEventLoopOnce来驱动WatchForInterfaceChange中添加的Event。

mDNSPosixRunEventLoopOnce：

    fd_set listenFDs = gEventFDs;
    int fdMax = 0, numReady;
    struct timeval timeout = *pTimeout;

    // Include the sockets that are listening to the wire in our select() set
    mDNSPosixGetFDSet(m, &fdMax, &listenFDs, &timeout); // timeout may get modified

fd_set listenFDs = gEventFDs;

后面的mDNSPosixGetFDSet是把网卡上的那几个fd给弄进来。

##1.mDNS_Close
关闭

##0.ProgramName与mDNSStorage
const char ProgramName[] = "xxx";

mDNS mDNSStorage;

有别的地方extern这两个符号，所以不能是static修饰的。

dnssd_clientshim.c大量引用mDNSStorage

##0.关于Android的logcat
定义在PlatformCommon.c的mDNSPlatformWriteLogMsg

LOG_TAG是bonjour

只被定义在mDNSShared/mDNSDebug.c的LogMsgWithLevelv引用。

LogMsgWithLevelv只被LOG_HELPER_BODY引用。

mDNS_LoggingEnabled:

mDNSCore/mDNSDebug.h:139:extern int mDNS_LoggingEnabled;

把这个赋值为1就能开启LogInfo、LogOperation

##2.mDNSPosixRunEventLoopOnce
这个函数被PosixDaemon.c的MainLoop调用，所以embeded的实现可以参考这个。

	mDNSPosixGetFDSet(m, &fdMax, &listenFDs, &timeout);
	numReady = select(fdMax + 1, &listenFDs, (fd_set*) NULL, (fd_set*) NULL, &timeout);
	mDNSPosixProcessFDSet(m, &listenFDs);

##3.mDNSPosixGetFDSet

这个是获取网卡上收到的mdns包用的socket，见这几个socket的初始化。

可以在这个处理函数加上log看看有没有收到外面来的数据包。

#debug
#1.

D/bonjour (32366): Attempt to register record with invalid rdata:    0 9886b100ac41@Apple\032TV._raop._tcp.local. SRV << ZERO RDATA LENGTH >>
D/bonjour (32366): DNSServiceBrowse("_raop._tcp", "<<NULL>>") failed: mDNS_RegisterService (-65549)

mDNS_RegisterService:

    // Setting AutoTarget tells DNS that the target of this SRV is to be automatically kept in sync with our host name
    if (host && host->c[0]) AssignDomainName(&sr->RR_SRV.resrec.rdata->u.srv.target, host);
    else { sr->RR_SRV.AutoTarget = Target_AutoHost; sr->RR_SRV.resrec.rdata->u.srv.target.c[0] = '\0'; }

internal:

    if (rr->AutoTarget)
    {
        SetTargetToHostName(m, rr);
    }
#2.
把embeded_Mainloop的调用时间从1s调到100ms后，正常工作了。

发现，以embeded方式运行时，会回应QM Question，但是QU不会回。

在mDNS_Init中：

	m->CanReceiveUnicastOn5353       = mDNSfalse;
	m->UnicastPort4                  = zeroIPPort;

这就是没有QU的原因么？

mDNSPlatformInit:中

if (mDNSPlatformInit_CanReceiveUnicast()) m->CanReceiveUnicastOn5353 =      mDNStrue;

#3.
用wireshark抓包发现，只要iphone发出一条广播的,SocketDataReady就会调用一次。

日志：

D/bonjour ( 5947): SocketDataReady got a packet from 192.168.137.30 to 224.0.0.251 on interface 192.168.137.3/wlan0/18/66
D/bonjour ( 5947): Received Query from 192.168.137.30 :5353  to 224.0.0.251    :5353  on 0x51004E38 with  2 Questions,  0 Answers,  0 Authorities,  1 Additional  66 bytes
D/bonjour ( 5947): AddRecordToResponseList: _raop._tcp.local. (PTR) already in list
D/bonjour ( 5947): AddRecordToResponseList: _airplay._tcp.local. (PTR) already in list
D/bonjour ( 5947): AddRecordToResponseList: 9886b100ac41@Apple\032TV._raop._tcp.local. (SRV) already in list
D/bonjour ( 5947): AddRecordToResponseList: 9886b100ac41@Apple\032TV._raop._tcp.local. (TXT) already in list
D/bonjour ( 5947): AddRecordToResponseList: Apple\032TV._airplay._tcp.local. (SRV) already in list
D/bonjour ( 5947): AddRecordToResponseList: Apple\032TV._airplay._tcp.local. (TXT) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): AddRecordToResponseList: 9886b100ac41@Apple\032TV._raop._tcp.local. (SRV) already in list
D/bonjour ( 5947): AddRecordToResponseList: 9886b100ac41@Apple\032TV._raop._tcp.local. (TXT) already in list
D/bonjour ( 5947): AddRecordToResponseList: Apple\032TV._airplay._tcp.local. (SRV) already in list
D/bonjour ( 5947): AddRecordToResponseList: Apple\032TV._airplay._tcp.local. (TXT) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): SendResponses: Next in 2013265920 ticks

最后一个SendResponses: Next in 2013265920 ticks是不是有点那什么？是因为缓存的原因么？

一次完整的query respone:

D/bonjour ( 5947): SocketDataReady got a packet from 192.168.137.30 to 224.0.0.251 on interface 192.168.137.3/wlan0/18/66
D/bonjour ( 5947): Received Query from 192.168.137.30 :5353  to 224.0.0.251    :5353  on 0x51004E38 with  2 Questions,  0 Answers,  0 Authorities,  0 Additionals 37 bytes
D/bonjour ( 5947): AddRecordToResponseList: _raop._tcp.local. (PTR) already in list
D/bonjour ( 5947): AddRecordToResponseList: _airplay._tcp.local. (PTR) already in list
D/bonjour ( 5947): AddRecordToResponseList: 9886b100ac41@Apple\032TV._raop._tcp.local. (SRV) already in list
D/bonjour ( 5947): AddRecordToResponseList: 9886b100ac41@Apple\032TV._raop._tcp.local. (TXT) already in list
D/bonjour ( 5947): AddRecordToResponseList: Apple\032TV._airplay._tcp.local. (SRV) already in list
D/bonjour ( 5947): AddRecordToResponseList: Apple\032TV._airplay._tcp.local. (TXT) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): AddRecordToResponseList: localhost.local. (Addr) already in list
D/bonjour ( 5947): SendResponses: Sending 0 Deregistrations, 0 Announcements, 2 Answers, 8 Additionals on 51004E38
D/bonjour ( 5947): SendResponses: Next in 2013265920 ticks
D/bonjour ( 5947): SocketDataReady got a packet from 192.168.137.3 to 224.0.0.251 on interface 192.168.137.3/wlan0/18/66
D/bonjour ( 5947): Received Response from 192.168.137.3   addressed to 224.0.0.251     on 51004E38 with  0 Questions,  2 Answers,  0 Authorities,  8 Additionals 435 bytes LLQType 0

这次与上次不同的是多了一句：

D/bonjour ( 5947): SendResponses: Sending 0 Deregistrations, 0 Announcements, 2 Answers, 8 Additionals on 51004E38

为什么发向224.0.0.251的原因：

SendResponses：

if (intf->IPv4Available) mDNSSendDNSMessage(m, &m->omsg, responseptr
, intf->InterfaceID, mDNSNULL, &AllDNSLinkGroup_v4, MulticastDNSPort, mDNSNULL, mDNSNULL, mDNSfalse);

AllDNSLinkGroup_v4这个参数决定的。

###mDNSCoreReceiveQuery
mDNSCoreReceive调用这个函数。

打印

Received Query from 192.168.137.30 :5353  to 224.0.0.251    :5353  on 0x510E4618 with  2 Questions,  2 Answers,  0 Authorities,  0 Additionals 96 bytes

ProcessQuery中：

 6473             for (rr=ResponseRecords; rr; rr=rr->NextResponse)
 6474                 if (MustSendRecord(rr) && ShouldSuppressKnownAnswer(&m->re      c.r, rr))


