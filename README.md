# vaccelrt-savgol

Build using the makefile provided:

```
make
```
### example stock execution

```
# ./savgol_cuda_prometheus
* Savgol Filter *
 # input file:               dataset.txt
Parameters=11 3

total GPU process time: 1.718000 msecs
only savgol GPU kernel time: 0.059000 msecs
1591.453003 976.202711
 1619.575806 1290.201435
 1622.184814 1539.333213
 1609.237549 1692.502404
 1570.958008 1714.224479
 1549.126343 1557.865562
 1519.252441 1535.564624
 1535.055908 1516.743359
 1519.155518 1509.109087
 1479.832520 1513.473090
```


### example wrapper execution

```
# LD_LIBRARY_PATH=. ./wrapper_host ./data/dataset.txt
* Savgol Filter *
 # input file:               ./data/dataset.txt
Parameters=11 3

total GPU process time: 1.648000 msecs
only savgol GPU kernel time: 0.048000 msecs
1591.453003 976.202711
 1619.575806 1290.201435
 1622.184814 1539.333213
 1609.237549 1692.502404
 1570.958008 1714.224479
 1549.126343 1557.865562
 1519.252441 1535.564624
 1535.055908 1516.743359
 1519.155518 1509.109087
 1479.832520 1513.473090
```

### example vAccel execution

```
# VACCEL_BACKENDS=/opt/vaccel/lib/libvaccel-exec.so LD_LIBRARY_PATH=. VACCEL_DEBUG_LEVEL=4  ./wrapper_vaccel data/dataset.txt
2022.08.06-13:51:13.84 - <debug> Initializing vAccel
2022.08.06-13:51:13.84 - <debug> Registered plugin exec
2022.08.06-13:51:13.84 - <debug> Registered function noop from plugin exec
2022.08.06-13:51:13.84 - <debug> Registered function exec from plugin exec
2022.08.06-13:51:13.84 - <debug> Loaded plugin exec from /store/ananos-develop/vaccelrt/build/plugins/exec/libvaccel-exec.so
filename: data/dataset.txt
File size: 2288439B
2022.08.06-13:51:13.84 - <debug> session:1 New session
Initialized session with id: 1
librar:libsavgol_cuda_prometheus.so
2022.08.06-13:51:13.84 - <debug> session:1 Looking for plugin implementing exec
2022.08.06-13:51:13.84 - <debug> Found implementation in exec plugin
2022.08.06-13:51:13.84 - <debug> Calling exec for session 1
2022.08.06-13:51:13.84 - <debug> [exec] library: libsavgol_cuda_prometheus.so
2022.08.06-13:51:13.85 - <debug> [exec] symbol: savgol_GPU_unpack
* Savgol Filter *
Parameters=11 3

total GPU process time: 1.388000 msecs
only savgol GPU kernel time: 0.049000 msecs
1591.453003 976.202711
 1619.575806 1290.201435
 1622.184814 1539.333213
 1609.237549 1692.502404
 1570.958008 1714.224479
 1549.126343 1557.865562
 1519.252441 1535.564624
 1535.055908 1516.743359
 1519.155518 1509.109087
 1479.832520 1513.473090
 ret=0
output:0
2022.08.06-13:51:14.05 - <debug> session:1 Free session
2022.08.06-13:51:14.05 - <debug> Shutting down vAccel
2022.08.06-13:51:14.05 - <debug> Cleaning up plugins
2022.08.06-13:51:14.05 - <debug> Unregistered plugin exec
```
