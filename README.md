WaveTrans

===========================================================================
Let's teach the machines to sing

Try 声波传输!  --- 用声音传输数据

    采用仿生学技术，利用声音实现文件的快速传输。采用跨平台的技术，实现手机与PC之间，或者手机之间的图片、文字、链接的传输, 以及设备间配对等。一键操作，2秒钟搞定。

    同时社交功能实现了微博互粉、近距离广播、电子名片交换等功能, 将来可以实现开放协议的便捷电子支付功能。

===========================================================================

声波传输如何工作？

    声波传输技术由两部分组成：音频协议与网络协议。音频协议将待传数据编码为一系列选定频率的音调；网络协议则将数据以键值形式存入服务器，其中键为与数据唯一对应的10个字符。

音频协议

    音频协议的原理很简单，易于实现。建立一个含有32个字符（[0-9，a-v]）的表，并将每个字符映射到频率表。频率表是根据乐理，通过伴音的计算生成。

0 = 1760hz

1 = 1864hz

......

v = 10.5khz

    一个完整的声波包包含20个音（即20个字符），每87.2毫秒发一个音 。前两位为信息头，采用“hj”，用以通知接收端开始接收。中间10位为有效的信息位，是有效的传输信息，即Key值经过映射后的频率信息。最后8位为RS（Reed-Solomon）校验位，通过RS校验算法，对中间10位进行计算，生成8位的校验信息

[头][有效数据][校验位]

校验主要用来处理由于噪声干扰造成的信息接收错误。通过RS校验，可以纠正25%的错误信息。


发送端（编码器）

    发送端设备只需能够发送1.7khz到10.5khz的正弦声波即可。为了将发送出的声波变得更好听，可以对声音进行一些美化处理，比如在我们的例子中，采用了椭圆形窗对声波进行了音量上的优化。


接收端（解码器）

    接收端需要记录声音，并将其进行解码以及容错处理。其对算法的要求相对较高，降噪及容错处理对能否得到正确的解码信息是至关重要的。所以接收端需要一定的数字运算能力，对设备的硬件配置有一定的要求。对于算法的细节，我们会逐步的公开并开源。


网络协议

    音频协议的最大局限性，在于其较低的传输效率。

    为了解决大量数据的传输问题，我们提供RESTful Api，这样发送设备可以将照片上传到云端，并获取云端返回的Key，将Key通过声波发送出去。接收端通过收到的Key从云端获取数据。

http://rest.sinaapp.com/?a=api

===========================================================================
PACKAGING LIST:

EAGLView.h
EAGLView.m

This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.

aurio_helper.cpp
aurio_helper.h

Helper functions for manipulating the remote i/o audio unit, responsible for setting up the remote i/o.

AppDelegate.h
AppDelegate.mm


The application delegate for the aurioTouch2 app, responsible for handling touch events and drawing.

FFTBufferManager.cpp
FFTBufferManager.h

This class manages buffering and computation for FFT analysis on input audio data. The methods provided are used to grab the audio, buffer it, and perform the FFT when sufficient data is available.

CAMath.h

CAMath is a helper class for various math functions.

CADebugMacros.h
CADebugMacros.cpp

A helper class for printing debug messages.

CAXException.h
CAXException.cpp

A helper class for exception handling.

CAStreamBasicDescription.cpp
CAStreamBasicDescription.h

A helper class for AudioStreamBasicDescription handling and manipulation.


