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

### example vAccel Firecracker VM execution

VM boot:
```
# VACCEL_BACKENDS=/store/ananos-develop/vaccelrt/build/plugins/exec/libvaccel-exec.so LD_LIBRARY_PATH=. VACCEL_DEBUG_LEVEL=4 /opt/vaccel-v0.4.0/bin/firecracker --api-sock /tmp/fc.sock --config-file /opt/vaccel-v0.4.0/share/config_virtio_accel.json --seccomp-level 0
2022.08.06-13:59:40.01 - <debug> Initializing vAccel
2022.08.06-13:59:40.01 - <debug> Registered plugin exec
2022.08.06-13:59:40.01 - <debug> Registered function noop from plugin exec
2022.08.06-13:59:40.01 - <debug> Registered function exec from plugin exec
2022.08.06-13:59:40.01 - <debug> Loaded plugin exec from /store/ananos-develop/vaccelrt/build/plugins/exec/libvaccel-exec.so
[    0.000000] Linux version 5.10.0 (runner@gh-cloud-pod-t4rjg) (gcc (Ubuntu 8.4.0-3ubuntu2) 8.4.0, GNU ld (GNU Binutils for Ubuntu) 2.34) #1 SMP Tue Mar 22 20:07:37 UTC 2022
[    0.000000] Command line: console=ttyS0 reboot=k panic=1 pci=off loglevel=8 root=/dev/vda ip=172.42.0.2::172.42.0.1:255.255.255.0::eth0:off random.trust_cpu=on root=/dev/vda rw virtio_mmio.device=4K@0xd0000000:5 virtio_mmio.device=4K@0xd0001000:6 virtio_mmio.device=4K@0xd0002000:7
[snipped]
```

```
# LD_LIBRARY_PATH=. ./wrapper_vaccel data/dataset.txt  | tee log.txt
[Host logs:]

2022.08.06-14:02:54.12 - <debug> session:1 New session
2022.08.06-14:02:54.12 - <debug> session:1 Looking for plugin implementing exec
2022.08.06-14:02:54.12 - <debug> Found implementation in exec plugin
2022.08.06-14:02:54.12 - <debug> Calling exec for session 1
2022.08.06-14:02:54.12 - <debug> [exec] library: libsavgol_cuda_prometheus.so
2022.08.06-14:02:54.12 - <debug> [exec] symbol: savgol_GPU_unpack
* Savgol Filter *
Parameters=11 3

total GPU process time: 1.464000 msecs
only savgol GPU kernel time: 0.047000 msecs
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
2022.08.06-14:02:54.33 - <debug> session:1 Free session
[Guest logs:]
2022.08.06-14:02:54.03 - <debug> Initializing vAccel
2022.08.06-14:02:54.03 - <debug> Registered plugin virtio
2022.08.06-14:02:54.03 - <debug> virtio is a VirtIO module
2022.08.06-14:02:54.03 - <debug> Registered function noop from plugin virtio
2022.08.06-14:02:54.03 - <debug> Registered function sgemm from plugin virtio
2022.08.06-14:02:54.03 - <debug> Registered function image classification from plugin virtio
2022.08.06-14:02:54.03 - <debug> Registered function image detection from plugin virtio
2022.08.06-14:02:54.03 - <debug> Registered function image segmentation from plugin virtio
2022.08.06-14:02:54.03 - <debug> Registered function image depth estimation from plugin virtio
2022.08.06-14:02:54.03 - <debug> Registered function image pose estimation from plugin virtio
2022.08.06-14:02:54.03 - <debug> Registered function exec from plugin virtio
2022.08.06-14:02:54.03 - <debug> Loaded plugin virtio from /opt/vaccel/lib/libvaccel-virtio.so
filename: data/dataset.txt
File size: 2288439B
2022.08.06-14:02:54.04 - <debug> session:1 New session
2022.08.06-14:02:54.04 - <debug> session:1 New session
Initialized session with id: 1
librar:libsavgol_cuda_prometheus.so
2022.08.06-14:02:54.04 - <debug> session:1 Looking for plugin implementing exec
2022.08.06-14:02:54.04 - <debug> Found implementation in virtio plugin
2022.08.06-14:02:54.04 - <debug> [virtio] session:1 Executing exec
output:0
2022.08.06-14:02:54.25 - <debug> session:1 Free session
2022.08.06-14:02:54.25 - <debug> session:1 Free session
2022.08.06-14:02:54.25 - <debug> Shutting down vAccel
2022.08.06-14:02:54.25 - <debug> Cleaning up plugins
2022.08.06-14:02:54.25 - <debug> Unregistered plugin virtio
```

