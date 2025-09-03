# obsGRID同化
obsgrid同化过程主要包括：观测数据下载，数据预处理，安装与运行obsgrid三个过程。更多过程参考 [UCAR_WRF指南第七章](https://www2.mmm.ucar.edu/wrf/users/docs/user_guide_v4/v4.4/users_guide_chap7.html)
<a id=Return_to_Top></a>

## 观测数据下载
[Return to Top](#Return_to_Top)  
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
[Return to Top](#Return_to_Top)  
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

#### metoa_em*文件解释
生成的`metoa_em*`文件可以通过以下两个方法运行real.exe  
1. 重命名或链接`metoa_em*`文件为`met_em*`，之后按照默认方法运行real.exe
2. 修改WRF的namelist.input文件中 *\&time_control* 模块下的 *auxinput1_inname* 
   ```
   auxinput1_inname = "metoa_em.d<domain>.<date>"
   ```

### 修改namelist.input
[Return to Top](#Return_to_Top)  
前面处理了OBS的地面以及高空数据，所以此处默认将fsfdda_d01 ， metoa_em*和 OBS_DOMAINdxxx均使用上，即使用grid analysis nudging、surface grid nudging和observational nudging
以下是示例namelist参数以及其意义 ，修改&ffda部分

Tabel 1. grid analysis nuging与surface grid nudging 参数

|       **变量名**        |      **推荐值**       |                                                                             **描述**                                                                             |
|:--------------------:|:------------------:|:--------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|      grid_fdda       |         1          |                       option to turn on grid nudging;<br>=0 : off<br>=1 : grid analysis nudging on<br>=2 : spectral analysis nudging on                        |
|     gfdda_inname     | wrffdda_d<domain>  |                                         defined name of grid nudging input file that is produced when running real.exe                                         |
|   gfdda_interval_m   |        360         |                                                         time interval (in mins) between analysis times                                                         |
|     gfdda_end_h      |         6          |                                                time (in hours) from the initial forecast time, to stop nudging                                                 |
|    io_form_gfdda     |         2          |                        output format for grid analysis data;<br>=2 : NetCDF<br>=4 : PHD5<br>=5 : GRIB1<br>=10 : GRIB2<br>=11 : pNetCDF                         |
|         fgdt         |         0          |                                 calculation frequency (in mins) for analysis nudging; 0=every time step, which is recommended                                  |
| if_no_pbl_nudging_uv |         0          |                                                      set to =1 to turn off nudging of u and v in the PBL                                                       |
| if_no_pbl_nudging_t  |         0          |                                                    set to =1 to turn off nudging of temperature in the PBL                                                     |
| if_no_pbl_nudging_q  |         0          |                                                       set to =1 to turn off nudging of qvapor in the PBL                                                       |
|         guv          |       0.0003       |                                              nudging coefficient for u and v (s-1); a reasonable value is 0.0003                                               |
|          gt          |       0.0003       |                                            nudging coefficient for temperature (s-1); a reasonable value is 0.0003                                             |
|          gq          |       0.0003       |                                               nudging coefficient for qvapor (s-1); a reasonable value is 0.0003                                               |
|      if_ramping      |         0          |                   the method for ending nudging;<br>=0 : nudging ends as a step function<br>=1 : nudging ramps down at the end of the period                   |
|      dtramp_min      |         60         |                                                            timestep (in mins) for ramping function                                                             |
|      grid_sfdda      |         1          | type of surface grid nudging;<br>=0 : none<br>=1 : nudging for selected surface fields<br>=2 : FASDAS (Flux-Adjusted Surface Data Assimilation System) nudging |
|    sgfdda_inname     | wrfsfdda_d<domain> |                                         defined name of surface nudging input file that comes from the OBSGRID program                                         |
|  sgfdda_interval_m   |        180         |                                                     time interval (in mins) between surface analysis times                                                     |
|     sgfdda_end_h     |         6          |                                            time (in hours) from the initial forecast time, to stop surface nudging                                             |
|    io_form_sgfdda    |         2          |                                                         surface analysis output format;<br>=2 : NetCDF                                                         |
|       guv_sfc        |       0.0003       |                                          surface nudging coefficient for u and v (s-1); a reasonable value is 0.0003                                           |
|        gt_sfc        |       0.0003       |                                        surface nudging coefficient for temperature (s-1); a reasonable value is 0.0003                                         |
|        gq_sfc        |       0.0003       |                                          surface nudging coefficient for qvapor (s-1); a reasonable value is 0.00001                                           |


Table 2. observational nudging 参数

|       **变量名**       | **推荐值** |                                                                  **描述**                                                                   |
|:-------------------:|:-------:|:-----------------------------------------------------------------------------------------------------------------------------------------:|
|    obs_nudge_opt    |    1    | set to =1 to turn on observational nudging; must also set auxinput11_invterval and auxinput11_end_h under &time_control in namelist.input |
|       max_obs       | 150000  |                               maximum number of observations used for a domain during any given time window                               |
|     fdda_start      |    0    |                                                observational nudging start time (in mins)                                                 |
|      fdda_end       |  99999  |                                                 observational nudging end time (in mins)                                                  |
|   obs_nudge_wind    |    1    |                                                     set to =1 to turn on wind nudging                                                     |
|    obs_coef_wind    |  6.E-4  |                                                    nudging coefficient for wind (s-1)                                                     |
|   obs_nudge_temp    |    1    |                                                 set to =1 to turn on temperature nudging                                                  |
|    obs_coef_temp    |  6.E-4  |                                                 nudging coefficient for temperature (s-1)                                                 |
|   obs_nudge_mois    |    1    |                                              set to =1 to turn on vapor mixing ratio nudging                                              |
|    obs_coef_mois    |  6.E-4  |                                             nudging coefficient for vapor mixing ratio (s-1)                                              |
|      obs_rinxy      |   240   |                                                  horizontal radius of influence (in km)                                                   |
|     obs_rinsig      |   0.1   |                                                   vertical radius of influence (in eta)                                                   |
|     obs_twindo      | 0.6667  |                             half-period time window over which an observation is used for nudging (in hours)                              |
|      obs_npfi       |   10    |                                         frequency in coarse grid timesteps for diagnostic prints                                          |
|      obs_ionf       |    2    |                             frequency in coarse grid timesteps for observational input and error calculation                              |
|     obs_idynin      |    0    |              for dynamic initialization, turns on ramping-down function to gradually turn off FDDA before the pure forecast               |
|     obs_dtramp      |   40    |                               time period (in mins) over which the nudging is ramped down from one to zero                                |
|     obs_prt_max     |   100   |                                            maximum allowed obs entries in diagnostic printout                                             |
|    obs_prt_freq     |   100   |                                          frequency in observation index for diagnostic printout                                           |
|   obs_ipf_in4dob    | .true.  |                                          set to =.true. to print observational input diagnostics                                          |
|    obs_ipf_errob    | .true.  |                                          set to =.true. to print observational error diagnostics                                          |
|    obs_ipf_nudob    | .true.  |                                         set to =.true. to print observational nudging diagnostics                                         |
|    obs_ipf_init     | .true.  |                                              enables observational printed warning messages                                               |
| obs_no_pbl_nudge_uv |    0    |                                             set to =1 to turn off wind nudging within the PBL                                             |
| obs_no_pbl_nudge_t  |    0    |                                         set to =1 to turn off temperature nudging within the PBL                                          |
| obs_no_pbl_nudge_q  |    0    |                                           set to =1 to turn off moisture nudging within the PBL                                           |

<font color=#f9906F size =4>特别强调</font>，开启observational nudging后需要在&time_control 增加以下变量  
```
auxinput11_invterval  = 180
auxinput11_end_h      = 6
```

以下变量在 grid_fdda=2时有用，给出建议取值如下
Table 3 spectral analysis nudging参数

|       **变量名**        | **推荐值** |                                                                                   **描述**                                                                                   |
|:--------------------:|:-------:|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|      grid_fdda       |    2    |                             option to turn on grid nudging;<br>=0 : off<br>=1 : grid analysis nudging on<br>=2 : spectral analysis nudging on                              |
|       fgdtzero       |    0    |                                                        set to =1 to nudge tendencies to zero in between fdda calls                                                         |
| if_no_pbl_nudging_ph |    0    |                                                 set to =1 to turn off nudging of perturbation geopotential (ph) in the PBL                                                 |
|      if_zfac_uv      |    0    |                    determines which layers nudging will occur for u and v;<br>=0 : nudge in all layers<br>=1 : limit nudging to levels above k_zfac_uv                     |
|      k_zfac_uv       |   10    |                                                         below this model level, nudging is turned off for u and v                                                          |
|      dk_zfac_uv      |    1    |                                  depth (in k dimension) between k_zfac_uv to dk_zfac_uv where nudging increases linearly to full strength                                  |
|      if_zfac_t       |    0    |             determines which layers nudging will occur for temperature;<br>=0 : nudge temperature in all layers<br>=1 : limit nudging to levels above k_zfac_t             |
|       k_zfac_t       |   10    |                                                       below this model level, nudging is turned off for temperature                                                        |
|      dk_zfac_t       |    1    |                                   depth (in k dimension) between k_zfac_t to dk_zfac_t where nudging increases linearly to full strength                                   |
|      if_zfac_ph      |    0    |       determines which layers nudging will occur for perturbation geopotential (ph);<br>=0 : nudge ph in all layers<br>=1 : limit nudging to levels above k_zfac_tph       |
|      k_zfac_ph       |   10    |                                              below this model level, nudging is turned off for perturbation geopotential (ph)                                              |
|      dk_zfac_ph      |    1    |                                  depth (in k dimension) between k_zfac_ph to dk_zfac_ph where nudging increases linearly to full strength                                  |
|      if_zfac_q       |    0    |                 determines which layers nudging will occur for qvapor;<br>=0 : nudge qvapor in all layers<br>=1 : limit nudging to levels above k_zfac_tq                  |
|       k_zfac_q       |   10    |                                                          below this model level, nudging is turned off for qvapor                                                          |
|      dk_zfac_q       |    1    |                                   depth (in k dimension) between k_zfac_q to dk_zfac_q where nudging increases linearly to full strength                                   |
|         gph          | 0.0003  |                                            nudging coefficient for perturbation geopotential (ph); a reasonable value is 0.0003                                            |
|        ktrop         |    0    | option to cap spectral nudging of potential temperature and water vapor mixing ratio at a user-defined layer above the PBL; nominally selected to represent the tropopause |
|       xwavenum       |    3    |                                                    top wave number to nudge in the x-direction; a reasonable value is 3                                                    |
|       ywavenum       |    3    |                                                    top wave number to nudge in the y-direction; a reasonable value is 3                                                    |

更多namelist相关设置可以参考[WRF用户指南文档](https://www2.mmm.ucar.edu/wrf/users/wrf_users_guide/build/html/overview.html)  
附上包含OBSGRID的WRF运行流程图  
![图1](https://github.com/Xueyexueyuexue/WRF_Nudging/blob/main/WRF%20flow%20chart.png)
