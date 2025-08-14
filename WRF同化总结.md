> 正在施工

# obsGRID同化
obsgrid同化过程主要包括：观测数据下载，数据预处理，安装与运行obsgrid三个过程。更多过程参考 [UCAR_WRF指南第七章](https://www2.mmm.ucar.edu/wrf/users/docs/user_guide_v4/v4.4/users_guide_chap7.html)
## 观测数据下载
观测数据需要下载，分别下载高空和地表数据，需求格式为little_r格式。  
高空数据 NCEP BUFR 格式 [ds351.0](http://rda.ucar.edu/datasets/ds351.0/)  
表面数据 NCEP BUFR 格式 [ds461.0](http://rda.ucar.edu/datasets/ds461.0/)  
打开链接后选择DATA ACCESS -> 选择little_r format 的File Listing -> complete file list  
之后选择合适年份，筛选文件选择csh下载脚本，进入服务器./运行

## 数据预处理
将下载好的高空与地面数据一同放入WRF_Nudging-main文件夹下  
依次运行两个combine文件  
```
./combineSurfaceToObs.sh
./combineCobsToRdaobs.sh
```
依次将 `SURFACE_OBS:YYYYMMDD` 和 `OBS:YYYYMMDD` 整和成 `C_OBS:YYYYMMDD`  
并所有的探测数据写入`rda_obs`  

## 安装与运行obsgrid
### 安装obsgrid
脚本源代码可以从以下路径获取 https://github.com/wrf-model/OBSGRID 或 https://www2.mmm.ucar.edu/wrf/users/download/get_sources_pproc_util.html  
解压文件`tar -xzvf OBSGRID.tar.gz`生成目录OBSGRID
```
cd OBSGRID
```  
接下来修改配置文件
```
vim /src/drive.F90
```
编辑drive.F90文件中，修改785，797和809行，将OBS_DOMAIN保存上限由99改为999
```
WRITE (obs_nudge_file,'("OBS_DOMAIN",i1,i3.3)') nml%record_2%grid_id, obs_file_count
```  
之后修改configure默认配置  
```
cd arch
vim vim configure.defaults
```
更改第78行，intel 编译下的CPPFLAGS 为
```
CPPFLAGS        =       -I. -P -DDEC -traditional
```
到此配置完成，`./configure` 选项选择3 ，`./complie` 完成编译，出现obsgrid.exe  
进入util目录下，生成get_rda_data.exe
```
cd util
ifort -FR get_rda_data.f -o get_rda_data.exe
```

编译不成功也可以复制/r008/xdxie/models/obsgrid/OBSGRID
### 运行obsgrid
将预处理后的`rda_obs`以及`namelist.oa`复制到OBSGRID以及OBSGRID/util目录下
设置`namelist.oa`中Record1的时间信息`./get_rda_data.exe`得到`OBS:YYYY-MM-DD`文件  
将`met_em.d01*`文件移动到`obsgride.exe`的目录下，修改`namelist.oa`，设置obsfilename路径
```
obs_filename                = './util/OBS'
```
`./obsgrid.exe` 生成 wrfsfdda_d01 ， metoa_em*和 OBS_DOMAINdxxx  
运行run_cat_obs_files.csh，将所有OBS_DOMAINdxxx整合成OBS_DOMAINd01方便WRF读取`./run_cat_obs_files.csh`

#### metoa_em*
生成的`metoa_em*`文件可以通过以下两个方法运行real.exe  
1. 重命名或链接`metoa_em*`文件为`met_em*`，之后按照默认方法运行real.exe
2. 修改WRF的namelist.input文件中 *\&time_control* 模块下的 *auxinput1_inname* 
   ```
   auxinput1_inname = "metoa_em.d<domain>.<date>"
   ```
