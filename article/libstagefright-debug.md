#1.prepare出错

V/MediaPlayer( 2013): setVideoSurfaceTexture
V/MediaPlayer( 2013): prepareAsync
V/MediaPlayer( 2013): message received msg=100, ext1=1, ext2=-2147483648
E/MediaPlayer( 2013): error (1, -2147483648)
V/MediaPlayer( 2013): callback application
V/MediaPlayer( 2013): back from callback
V/FFmpegExtractor(  210): FFmpegExtractor enter thread(readerEntry)
E/MediaPlayer( 2013): Error (1,-2147483648)

第一个error是c++层，Error是java层的。

2556 void AwesomePlayer::abortPrepare(status_t err) {
2557     CHECK(err != OK);
2558 
2559     if (mIsAsyncPrepare) {
2560         notifyListener_l(MEDIA_ERROR, MEDIA_ERROR_UNKNOWN, err);
2561     }

上层调用的是preapreAsync.

prepare最终走向onPrepareAsyncEvent，里面finishSetDataSource_l、initVideoDecoder、initAudioDecoder。


